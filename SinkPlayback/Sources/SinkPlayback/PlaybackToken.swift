import Foundation

/// A resolved, short-lived playback URL for a catalog entry.
public struct PlaybackToken: Sendable {
    public let url: URL
    public let expiresAt: Date

    public init(url: URL, expiresAt: Date) {
        self.url = url
        self.expiresAt = expiresAt
    }
}
