import Accelerate
import AVFoundation
import CoreMedia
import MediaToolbox

// MARK: - Tap context

// Heap-allocated state shared between the main actor and the audio tap thread.
// Float fields are nonisolated(unsafe) — approximate values make explicit
// synchronization unnecessary; a torn float read produces a slightly wrong
// gain rather than a crash.
private final class TapContext {
    let stationID: String
    let cache: GainCache
    nonisolated(unsafe) var smoothedRMS: Float = 0
    nonisolated(unsafe) var currentGain: Float
    nonisolated(unsafe) var gainCached: Bool = false
    nonisolated(unsafe) var formatIsFloat: Bool = false
    // CFAbsoluteTime is a Double; written once on init, read from tap thread.
    nonisolated(unsafe) var playStarted: CFAbsoluteTime

    init(stationID: String, initialGain: Float, cache: GainCache) {
        self.stationID = stationID
        self.currentGain = initialGain
        self.cache = cache
        self.playStarted = CFAbsoluteTimeGetCurrent()
    }
}

// MARK: - C-compatible tap callbacks (global functions, no captured state)

private func agcTapInit(
    _ tap: MTAudioProcessingTap,
    _ clientInfo: UnsafeMutableRawPointer?,
    _ tapStorageOut: UnsafeMutablePointer<UnsafeMutableRawPointer?>
) {
    tapStorageOut.pointee = clientInfo
}

private func agcTapFinalize(_ tap: MTAudioProcessingTap) {
    let ptr = MTAudioProcessingTapGetStorage(tap)
    Unmanaged<TapContext>.fromOpaque(ptr).release()
}

private func agcTapPrepare(
    _ tap: MTAudioProcessingTap,
    _ maxFrames: CMItemCount,
    _ format: UnsafePointer<AudioStreamBasicDescription>
) {
    let ptr = MTAudioProcessingTapGetStorage(tap)
    let ctx = Unmanaged<TapContext>.fromOpaque(ptr).takeUnretainedValue()
    let flags = format.pointee.mFormatFlags
    ctx.formatIsFloat = format.pointee.mFormatID == kAudioFormatLinearPCM
        && flags & kAudioFormatFlagIsFloat != 0
        && format.pointee.mBitsPerChannel == 32
}

private func agcTapUnprepare(_ tap: MTAudioProcessingTap) {}

// swiftlint:disable:next function_parameter_count
private func agcTapProcess(
    _ tap: MTAudioProcessingTap,
    _ numberFrames: CMItemCount,
    _ flags: MTAudioProcessingTapFlags,
    _ bufferListInOut: UnsafeMutablePointer<AudioBufferList>,
    _ numberFramesOut: UnsafeMutablePointer<CMItemCount>,
    _ flagsOut: UnsafeMutablePointer<MTAudioProcessingTapFlags>
) {
    MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)

    let ptr = MTAudioProcessingTapGetStorage(tap)
    let ctx = Unmanaged<TapContext>.fromOpaque(ptr).takeUnretainedValue()

    guard ctx.formatIsFloat, numberFramesOut.pointee > 0 else { return }

    let abl = UnsafeMutableAudioBufferListPointer(bufferListInOut)
    var sumSquares: Float = 0
    var totalSamples = 0

    for buffer in abl {
        guard let data = buffer.mData, buffer.mDataByteSize > 0 else { continue }
        let count = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
        var bufSumSq: Float = 0
        vDSP_svesq(data.assumingMemoryBound(to: Float.self), 1, &bufSumSq, vDSP_Length(count))
        sumSquares += bufSumSq
        totalSamples += count
    }

    if totalSamples > 0 {
        let rms = sqrt(sumSquares / Float(totalSamples))
        // Per-buffer exponential moving average for smoothing
        ctx.smoothedRMS = ctx.smoothedRMS * 0.95 + rms * 0.05

        if ctx.smoothedRMS > 0.001 {
            let target: Float = 0.07
            let desired = max(0.1, min(2.0, target / ctx.smoothedRMS))
            // Slow gain ramp to prevent audible pumping
            ctx.currentGain = ctx.currentGain * 0.98 + desired * 0.02
        }

        if !ctx.gainCached && CFAbsoluteTimeGetCurrent() - ctx.playStarted >= 10.0 {
            ctx.cache.write(stationID: ctx.stationID, gain: ctx.currentGain)
            ctx.gainCached = true
        }
    }

    var gain = ctx.currentGain
    for buffer in abl {
        guard let data = buffer.mData, buffer.mDataByteSize > 0 else { continue }
        let count = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
        let samples = data.assumingMemoryBound(to: Float.self)
        vDSP_vsmul(samples, 1, &gain, samples, 1, vDSP_Length(count))
    }
}

// MARK: - AGCEngine

@MainActor
final class AGCEngine {
    private let gainCache = GainCache()
    private var context: TapContext?
    private var installTask: Task<Void, Never>?

    // Starts AGC for the given player item. Returns immediately; the tap is
    // installed asynchronously once the item's audio tracks are available.
    // The cached gain (if any) is pre-loaded into the context so it applies
    // from the first processed buffer.
    func start(playerItem: AVPlayerItem, stationID: String) {
        installTask?.cancel()
        persistContextIfReady()
        context = nil

        let initialGain = gainCache.read(stationID: stationID) ?? 1.0
        let ctx = TapContext(stationID: stationID, initialGain: initialGain, cache: gainCache)
        context = ctx

        installTask = Task { @MainActor [weak self, weak playerItem] in
            guard let self, let playerItem, !Task.isCancelled else { return }
            self.installTap(on: playerItem, context: ctx)
        }
    }

    // Stops AGC and persists the current gain to the cache.
    func stop() {
        installTask?.cancel()
        installTask = nil
        persistContextIfReady()
        context = nil
    }

    // MARK: - Private

    private func persistContextIfReady() {
        guard let ctx = context, !ctx.gainCached,
              CFAbsoluteTimeGetCurrent() - ctx.playStarted >= 5.0 else { return }
        gainCache.write(stationID: ctx.stationID, gain: ctx.currentGain)
        ctx.gainCached = true
    }

    private func installTap(on playerItem: AVPlayerItem, context ctx: TapContext) {
        let clientInfo = Unmanaged.passRetained(ctx).toOpaque()
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: clientInfo,
            `init`: agcTapInit,
            finalize: agcTapFinalize,
            prepare: agcTapPrepare,
            unprepare: agcTapUnprepare,
            process: agcTapProcess
        )

        var tap: MTAudioProcessingTap?
        guard MTAudioProcessingTapCreate(
            kCFAllocatorDefault,
            &callbacks,
            kMTAudioProcessingTapCreationFlag_PostEffects,
            &tap
        ) == noErr, let tap else {
            // Release retained context if tap creation failed
            Unmanaged<TapContext>.fromOpaque(clientInfo).release()
            return
        }

        let params = AVMutableAudioMixInputParameters()
        params.audioTapProcessor = tap

        let mix = AVMutableAudioMix()
        mix.inputParameters = [params]
        playerItem.audioMix = mix
    }
}
