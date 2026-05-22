import Foundation

// MARK: - Public models

public struct PlaybackItem: Sendable, Equatable {
    public let id: String
    public let name: String
    public let slug: String
    public let kind: String

    public init(id: String, name: String, slug: String, kind: String) {
        self.id = id
        self.name = name
        self.slug = slug
        self.kind = kind
    }
}

public struct PlayerPreferences: Sendable {
    public let volume: Double
    public let lastItem: PlaybackItem?
    public let normalizationEnabled: Bool
    public let updatedAt: Date

    public init(volume: Double, lastItem: PlaybackItem?, normalizationEnabled: Bool, updatedAt: Date) {
        self.volume = volume
        self.lastItem = lastItem
        self.normalizationEnabled = normalizationEnabled
        self.updatedAt = updatedAt
    }
}

public struct PlayerPreferencesWriteResult: Sendable {
    public let stale: Bool
    public let preferences: PlayerPreferences

    public init(stale: Bool, preferences: PlayerPreferences) {
        self.stale = stale
        self.preferences = preferences
    }
}

// MARK: - Internal decoders

struct PlaybackItemJSON: Codable {
    let id: String
    let name: String
    let slug: String
    let kind: String

    func toModel() -> PlaybackItem {
        PlaybackItem(id: id, name: name, slug: slug, kind: kind)
    }
}

struct PlayerPreferencesJSON: Decodable {
    let volume: Double
    let lastItem: PlaybackItemJSON?
    let normalizationEnabled: Bool
    let updatedAt: String

    func toModel() throws -> PlayerPreferences {
        guard let date = iso8601d.date(from: updatedAt) else {
            throw CatalogAPIError.invalidResponse("unparseable updated_at")
        }
        return PlayerPreferences(
            volume: volume,
            lastItem: lastItem?.toModel(),
            normalizationEnabled: normalizationEnabled,
            updatedAt: date
        )
    }
}

struct PlayerPreferencesWriteResultJSON: Decodable {
    let stale: Bool
    let volume: Double
    let lastItem: PlaybackItemJSON?
    let normalizationEnabled: Bool
    let updatedAt: String

    func toModel() throws -> PlayerPreferencesWriteResult {
        guard let date = iso8601d.date(from: updatedAt) else {
            throw CatalogAPIError.invalidResponse("unparseable updated_at")
        }
        let prefs = PlayerPreferences(
            volume: volume,
            lastItem: lastItem?.toModel(),
            normalizationEnabled: normalizationEnabled,
            updatedAt: date
        )
        return PlayerPreferencesWriteResult(stale: stale, preferences: prefs)
    }
}

// MARK: - Internal encoder

struct PlayerPreferencesUpdateBody: Encodable {
    let volume: Double
    let lastItem: PlaybackItemJSON?
    let normalizationEnabled: Bool
    let queue: [PlaybackItemJSON]
    let queueIndex: Int
    let updatedAt: String

    init(from prefs: PlayerPreferences) {
        volume = prefs.volume
        lastItem = prefs.lastItem.map { PlaybackItemJSON(id: $0.id, name: $0.name, slug: $0.slug, kind: $0.kind) }
        normalizationEnabled = prefs.normalizationEnabled
        queue = []
        queueIndex = 0
        updatedAt = iso8601d.string(from: prefs.updatedAt)
    }
}
