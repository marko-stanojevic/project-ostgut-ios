import Foundation
import SinkAPI
import SinkPlayback
import Testing
@testable import SinkCore

@Suite("PlayerPreferencesStore")
@MainActor
struct PlayerPreferencesStoreTests {
    private let testDefaultsSuiteName = "PlayerPreferencesStoreTests"
    private let testDefaults = UserDefaults(suiteName: "PlayerPreferencesStoreTests")!

    private func makePreferences(
        volume: Double = 0.8,
        lastItem: PlaybackItem? = nil,
        updatedAt: Date = Date()
    ) -> PlayerPreferences {
        PlayerPreferences(volume: volume, lastItem: lastItem, normalizationEnabled: false, updatedAt: updatedAt)
    }

    private func makeStore(
        serverPrefs: PlayerPreferences? = nil,
        serverUpdatedAt: Date = Date()
    ) -> PlayerPreferencesStore {
        let prefs = serverPrefs ?? makePreferences(updatedAt: serverUpdatedAt)
        resetDefaults()
        return PlayerPreferencesStore(
            fetcher: { prefs },
            saver: { PlayerPreferencesWriteResult(stale: false, preferences: $0) },
            defaults: testDefaults
        )
    }

    private func resetDefaults() {
        testDefaults.removePersistentDomain(forName: testDefaultsSuiteName)
    }

    // MARK: - Conflict resolution

    @Test("sync applies server preferences when server is newer")
    func syncAppliesServerPrefsWhenNewer() async {
        let future = Date().addingTimeInterval(3600)
        let store = makeStore(serverPrefs: makePreferences(volume: 0.5, updatedAt: future))
        await store.sync()
        #expect(store.volume == 0.5)
    }

    @Test("sync does not apply server preferences when local is newer")
    func syncIgnoresStaleServerPrefs() async {
        let store = makeStore(
            serverPrefs: makePreferences(volume: 0.3, updatedAt: .distantPast)
        )
        store.updateVolume(0.9)
        // local updatedAt is now > server's distantPast
        await store.sync()
        #expect(store.volume == 0.9)
    }

    @Test("stale write response applies server value when server is newer")
    func staleWriteAppliesServerValue() async {
        let serverTime = Date().addingTimeInterval(3600)
        let serverPrefs = makePreferences(volume: 0.2, updatedAt: serverTime)
        let fallback = makePreferences()
        resetDefaults()
        let store = PlayerPreferencesStore(
            fetcher: { fallback },
            saver: { _ in PlayerPreferencesWriteResult(stale: true, preferences: serverPrefs) },
            defaults: testDefaults
        )
        store.updateVolume(0.7)
        // Trigger save immediately (bypass debounce for test)
        await store.performSaveForTest()
        #expect(store.volume == 0.2)
    }

    // MARK: - trackPlayback

    @Test("trackPlayback sets restoredStation to nil")
    func trackPlaybackClearsRestoredStation() async {
        let item = PlaybackItem(id: "s1", name: "Test FM", slug: "test-fm", kind: "station")
        let store = makeStore(serverPrefs: makePreferences(lastItem: item, updatedAt: Date()))
        await store.sync()
        #expect(store.restoredStation != nil)

        let station = Station(id: "s2", name: "New FM", slug: "new-fm")
        store.trackPlayback(station: station)
        #expect(store.restoredStation == nil)
    }

    // MARK: - restoredStation

    @Test("sync sets restoredStation from server last_item")
    func syncSetsRestoredStation() async {
        let item = PlaybackItem(id: "s1", name: "Radio X", slug: "radio-x", kind: "station")
        let store = makeStore(serverPrefs: makePreferences(lastItem: item, updatedAt: Date()))
        await store.sync()
        #expect(store.restoredStation?.id == "s1")
        #expect(store.restoredStation?.name == "Radio X")
    }

    @Test("sync sets restoredStation to nil when server has no last_item")
    func syncClearsRestoredStationWhenNoLastItem() async {
        let store = makeStore(serverPrefs: makePreferences(lastItem: nil, updatedAt: Date()))
        await store.sync()
        #expect(store.restoredStation == nil)
    }

    // MARK: - clearPreferences

    @Test("clearPreferences resets volume and restoredStation")
    func clearPreferencesResetsState() async {
        let item = PlaybackItem(id: "s1", name: "Radio X", slug: "radio-x", kind: "station")
        let store = makeStore(serverPrefs: makePreferences(volume: 0.6, lastItem: item, updatedAt: Date()))
        await store.sync()
        store.clearPreferences()
        #expect(store.volume == 1.0)
        #expect(store.restoredStation == nil)
    }
}
