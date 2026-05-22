import SinkAPI
import SinkPlayback
import SwiftUI

private struct APIClientKey: EnvironmentKey {
    static let defaultValue: APIClient? = nil
}

private struct PlaybackServiceKey: EnvironmentKey {
    static let defaultValue: AVPlayerPlaybackService? = nil
}

extension EnvironmentValues {
    var apiClient: APIClient? {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }

    var playbackService: AVPlayerPlaybackService? {
        get { self[PlaybackServiceKey.self] }
        set { self[PlaybackServiceKey.self] = newValue }
    }
}
