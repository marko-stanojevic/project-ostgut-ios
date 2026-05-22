import AVFoundation
import Testing
@testable import SinkPlayback

@Suite("AVPlayerPlaybackService")
@MainActor
struct AVPlayerPlaybackServiceTests {
    private let station = Station(id: "s1", name: "Test FM", slug: "test-fm")
    private let streamURL = URL(string: "https://stream.example.com/live.mp3")! // swiftlint:disable:this force_unwrapping

    // MARK: - play()

    @Test("play calls resolver with the station ID")
    func playCallsResolverWithStationID() async throws {
        var resolvedID: String?
        let service = AVPlayerPlaybackService { id in
            resolvedID = id
            return PlaybackToken(url: self.streamURL, expiresAt: Date().addingTimeInterval(3600))
        }

        try await service.play(station: station)

        #expect(resolvedID == "s1")
    }

    @Test("play transitions state to playing")
    func playTransitionsToPlaying() async throws {
        let service = AVPlayerPlaybackService { _ in
            PlaybackToken(url: self.streamURL, expiresAt: Date().addingTimeInterval(3600))
        }

        try await service.play(station: station)

        guard case .playing(let playing) = service.state else {
            Issue.record("Expected .playing, got \(service.state)")
            return
        }
        #expect(playing.id == station.id)
    }

    @Test("play replaces the AVPlayer current item")
    func playReplacesAVPlayerItem() async throws {
        let player = AVPlayer()
        let service = AVPlayerPlaybackService(
            playbackURLResolver: { _ in
                PlaybackToken(url: self.streamURL, expiresAt: Date().addingTimeInterval(3600))
            },
            player: player
        )

        try await service.play(station: station)

        #expect(player.currentItem != nil)
    }

    @Test("play transitions to error when resolver throws")
    func playTransitionsToErrorOnResolverFailure() async throws {
        struct ResolverError: Error, Equatable {}
        let service = AVPlayerPlaybackService { _ in throw ResolverError() }

        await #expect(throws: ResolverError.self) {
            try await service.play(station: self.station)
        }
        guard case .error(let errStation, _) = service.state else {
            Issue.record("Expected .error state")
            return
        }
        #expect(errStation.id == station.id)
    }

    // MARK: - pause() / resume()

    @Test("pause transitions playing to paused")
    func pauseTransitionsToPaused() async throws {
        let service = AVPlayerPlaybackService { _ in
            PlaybackToken(url: self.streamURL, expiresAt: Date().addingTimeInterval(3600))
        }
        try await service.play(station: station)

        service.pause()

        guard case .paused(let paused) = service.state else {
            Issue.record("Expected .paused")
            return
        }
        #expect(paused.id == station.id)
    }

    @Test("resume transitions paused to playing")
    func resumeTransitionsToPlaying() async throws {
        let service = AVPlayerPlaybackService { _ in
            PlaybackToken(url: self.streamURL, expiresAt: Date().addingTimeInterval(3600))
        }
        try await service.play(station: station)
        service.pause()

        service.resume()

        guard case .playing = service.state else {
            Issue.record("Expected .playing after resume")
            return
        }
    }

    // MARK: - stop()

    @Test("stop resets state to idle and clears player item")
    func stopResetsToIdle() async throws {
        let player = AVPlayer()
        let service = AVPlayerPlaybackService(
            playbackURLResolver: { _ in
                PlaybackToken(url: self.streamURL, expiresAt: Date().addingTimeInterval(3600))
            },
            player: player
        )
        try await service.play(station: station)

        service.stop()

        #expect(service.state == .idle)
        #expect(player.currentItem == nil)
    }

    // MARK: - Interruption handling

    @Test("interruption ended with shouldResume resumes playback")
    func interruptionShouldResumeRestoresPlayingState() async throws {
        let service = AVPlayerPlaybackService { _ in
            PlaybackToken(url: self.streamURL, expiresAt: Date().addingTimeInterval(3600))
        }
        try await service.play(station: station)
        service.pause()

        let notification = Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue
            ]
        )
        NotificationCenter.default.post(notification)

        // Allow the Task spawned by the notification handler to execute.
        try await Task.sleep(for: .milliseconds(200))

        guard case .playing = service.state else {
            Issue.record("Expected .playing after interruption-ended-shouldResume")
            return
        }
    }

    @Test("interruption began pauses playback")
    func interruptionBeganPausesPlayback() async throws {
        let service = AVPlayerPlaybackService { _ in
            PlaybackToken(url: self.streamURL, expiresAt: Date().addingTimeInterval(3600))
        }
        try await service.play(station: station)

        let notification = Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
        )
        NotificationCenter.default.post(notification)

        try await Task.sleep(for: .milliseconds(100))

        guard case .paused = service.state else {
            Issue.record("Expected .paused after interruption began")
            return
        }
    }
}

// PlaybackState needs Equatable for #expect comparison in stop test.
extension PlaybackState: Equatable {
    public static func == (lhs: PlaybackState, rhs: PlaybackState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): true
        case (.loading, .loading): true
        case (.playing(let l), .playing(let r)): l.id == r.id
        case (.paused(let l), .paused(let r)): l.id == r.id
        case (.error(let ls, _), .error(let rs, _)): ls.id == rs.id
        default: false
        }
    }
}
