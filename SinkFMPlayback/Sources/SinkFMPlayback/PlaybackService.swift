import Foundation

/// A station the player can be asked to play.
public struct Station: Sendable {
    public let id: String
    public let name: String
    public let slug: String

    public init(id: String, name: String, slug: String) {
        self.id = id
        self.name = name
        self.slug = slug
    }
}

/// Playback state observed by the UI.
public enum PlaybackState: Sendable {
    case idle
    case loading
    case playing(station: Station)
    case paused(station: Station)
    case error(station: Station, underlyingError: Error)
}

/// The single contract for all playback operations.
///
/// `AVPlayerPlaybackService` is the concrete implementation used in the app target
/// and future CarPlay extension. Tests use a mock that conforms to this protocol.
@MainActor
public protocol PlaybackService: AnyObject {
    var state: PlaybackState { get }

    /// Resolve a signed playback URL and start streaming the station.
    func play(station: Station) async throws

    /// Pause the current stream.
    func pause()

    /// Resume a paused stream.
    func resume()

    /// Stop playback and release audio focus.
    func stop()
}
