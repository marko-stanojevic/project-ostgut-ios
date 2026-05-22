import Foundation

/// Current track metadata for a live stream.
public struct NowPlayingMetadata: Sendable {
    public let title: String
    public let artist: String

    public init(title: String, artist: String) {
        self.title = title
        self.artist = artist
    }
}
