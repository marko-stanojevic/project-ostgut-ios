import AVFoundation
import MediaPlayer

@Observable
@MainActor
public final class AVPlayerPlaybackService: PlaybackService {
    public private(set) var state: PlaybackState = .idle

    public private(set) var nowPlayingMetadata: NowPlayingMetadata?

    // Internal visibility allows the test target to inspect player state.
    let player: AVPlayer
    private let playbackURLResolver: @Sendable (String) async throws -> PlaybackToken
    private let nowPlayingResolver: (@Sendable (String) async throws -> NowPlayingMetadata?)?
    private var reResolveTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?
    // Stored so the observer can be removed in deinit, preventing stale observers in tests.
    nonisolated(unsafe) private var interruptionObserver: (any NSObjectProtocol)?

    public init(
        playbackURLResolver: @escaping @Sendable (String) async throws -> PlaybackToken,
        nowPlayingResolver: (@Sendable (String) async throws -> NowPlayingMetadata?)? = nil,
        player: AVPlayer = AVPlayer()
    ) {
        self.player = player
        self.playbackURLResolver = playbackURLResolver
        self.nowPlayingResolver = nowPlayingResolver
        setupRemoteCommands()
        setupInterruptionHandling()
    }

    // MARK: - PlaybackService

    public func play(station: Station) async throws {
        reResolveTask?.cancel()
        reResolveTask = nil
        state = .loading

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        let token: PlaybackToken
        do {
            token = try await playbackURLResolver(station.id)
        } catch {
            state = .error(station: station, underlyingError: error)
            throw error
        }

        player.replaceCurrentItem(with: AVPlayerItem(url: token.url))
        player.play()
        state = .playing(station: station)
        updateNowPlaying(station: station)
        scheduleReResolve(station: station, expiresAt: token.expiresAt)
        startPolling(station: station)
    }

    public func pause() {
        guard case .playing(let station) = state else { return }
        player.pause()
        state = .paused(station: station)
        stopPolling()
    }

    public func resume() {
        guard case .paused(let station) = state else { return }
        player.play()
        state = .playing(station: station)
        startPolling(station: station)
    }

    public func setVolume(_ volume: Float) {
        player.volume = volume
    }

    public func stop() {
        reResolveTask?.cancel()
        reResolveTask = nil
        stopPolling()
        nowPlayingMetadata = nil
        player.replaceCurrentItem(with: nil)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        state = .idle
    }

    // MARK: - Private

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.resume() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.pause() }
            return .success
        }
        center.stopCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.stop() }
            return .success
        }
    }

    private func setupInterruptionHandling() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                self?.handleInterruption(notification)
            }
        }
    }

    deinit {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func handleInterruption(_ notification: Notification) {
        guard
            let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            if case .playing(let station) = state {
                state = .paused(station: station)
            }
        case .ended:
            let optionsValue = (notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt) ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume), case .paused(let station) = state {
                Task { [weak self] in try? await self?.play(station: station) }
            }
        @unknown default:
            break
        }
    }

    private func startPolling(station: Station) {
        pollTask?.cancel()
        guard let resolver = nowPlayingResolver else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                if let self {
                    let metadata = try? await resolver(station.id)
                    self.nowPlayingMetadata = metadata
                    self.updateNowPlayingLockScreen(station: station, metadata: metadata)
                }
                try? await Task.sleep(for: .seconds(20))
            }
        }
    }

    private func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func updateNowPlaying(station: Station) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: station.name,
            MPNowPlayingInfoPropertyIsLiveStream: true
        ]
    }

    private func updateNowPlayingLockScreen(station: Station, metadata: NowPlayingMetadata?) {
        var info: [String: Any] = [MPNowPlayingInfoPropertyIsLiveStream: true]
        if let metadata, !metadata.title.isEmpty {
            info[MPMediaItemPropertyTitle] = metadata.title
            if !metadata.artist.isEmpty {
                info[MPMediaItemPropertyArtist] = metadata.artist
            }
        } else {
            info[MPMediaItemPropertyTitle] = station.name
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func scheduleReResolve(station: Station, expiresAt: Date) {
        let interval = expiresAt.timeIntervalSinceNow - 30
        guard interval > 0 else { return }

        reResolveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(interval))
            guard !Task.isCancelled, let self else { return }
            guard case .playing(let current) = state, current.id == station.id else { return }
            guard let newToken = try? await playbackURLResolver(station.id) else { return }
            player.replaceCurrentItem(with: AVPlayerItem(url: newToken.url))
            player.play()
            scheduleReResolve(station: station, expiresAt: newToken.expiresAt)
        }
    }
}
