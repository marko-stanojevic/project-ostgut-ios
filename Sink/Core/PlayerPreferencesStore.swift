import Foundation
import Observation
import SinkAPI
import SinkPlayback
#if os(iOS)
import UIKit
#endif

@Observable
@MainActor
final class PlayerPreferencesStore {
    private(set) var volume: Double = 1.0
    private(set) var restoredStation: Station?

    private var lastItem: PlaybackItem?
    private var updatedAt: Date = .distantPast

    private let fetcher: @Sendable () async throws -> PlayerPreferences
    private let saver: @Sendable (PlayerPreferences) async throws -> PlayerPreferencesWriteResult
    private let volumeApplicator: (@Sendable (Double) -> Void)?

    nonisolated(unsafe) private var saveTask: Task<Void, Never>?
#if os(iOS)
    nonisolated(unsafe) private var foregroundObserver: (any NSObjectProtocol)?
#endif

    private static let defaultsKey = "fm.sink.playerPreferences"

    init(
        fetcher: @escaping @Sendable () async throws -> PlayerPreferences,
        saver: @escaping @Sendable (PlayerPreferences) async throws -> PlayerPreferencesWriteResult,
        volumeApplicator: (@Sendable (Double) -> Void)? = nil
    ) {
        self.fetcher = fetcher
        self.saver = saver
        self.volumeApplicator = volumeApplicator
        loadFromDefaults()
        setupForegroundRefresh()
    }

    deinit {
#if os(iOS)
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
#endif
        saveTask?.cancel()
    }

    // MARK: - Public API

    func sync() async {
        guard let serverPrefs = try? await fetcher() else { return }
        if serverPrefs.updatedAt > updatedAt {
            apply(serverPrefs)
            saveToDefaults()
        }
    }

    func trackPlayback(station: Station) {
        lastItem = PlaybackItem(id: station.id, name: station.name, slug: station.slug, kind: "station")
        restoredStation = nil
        updatedAt = Date()
        scheduleSave()
    }

    func updateVolume(_ newVolume: Double) {
        volume = max(0, min(1, newVolume))
        updatedAt = Date()
        scheduleSave()
    }

    func clearPreferences() {
        volume = 1.0
        lastItem = nil
        restoredStation = nil
        updatedAt = .distantPast
        UserDefaults.standard.removeObject(forKey: Self.defaultsKey)
    }

    // MARK: - Private

    private func apply(_ prefs: PlayerPreferences) {
        volume = prefs.volume
        lastItem = prefs.lastItem
        updatedAt = prefs.updatedAt
        restoredStation = prefs.lastItem.map { Station(id: $0.id, name: $0.name, slug: $0.slug) }
        volumeApplicator?(prefs.volume)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, let self else { return }
            await self.performSave()
        }
    }

    func performSave() async {
        let snapshot = PlayerPreferences(
            volume: volume,
            lastItem: lastItem,
            normalizationEnabled: false,
            updatedAt: updatedAt
        )
        guard let result = try? await saver(snapshot) else { return }
        if result.stale && result.preferences.updatedAt > updatedAt {
            apply(result.preferences)
            saveToDefaults()
        } else {
            saveToDefaults()
        }
    }

    private func setupForegroundRefresh() {
#if os(iOS)
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.sync() }
        }
#endif
    }

    // MARK: - Local persistence

    private func loadFromDefaults() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
              let cached = try? JSONDecoder().decode(CachedPreferences.self, from: data)
        else { return }
        volume = cached.volume
        updatedAt = cached.updatedAt
        if let item = cached.lastItem {
            lastItem = PlaybackItem(id: item.id, name: item.name, slug: item.slug, kind: item.kind)
            restoredStation = Station(id: item.id, name: item.name, slug: item.slug)
        }
    }

    private func saveToDefaults() {
        let cachedItem = lastItem.map {
            CachedPreferences.Item(id: $0.id, name: $0.name, slug: $0.slug, kind: $0.kind)
        }
        let cached = CachedPreferences(volume: volume, lastItem: cachedItem, updatedAt: updatedAt)
        if let data = try? JSONEncoder().encode(cached) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}

// MARK: - Local cache model

private struct CachedPreferences: Codable {
    struct Item: Codable {
        let id: String
        let name: String
        let slug: String
        let kind: String
    }

    let volume: Double
    let lastItem: Item?
    let updatedAt: Date
}
