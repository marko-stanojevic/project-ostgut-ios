import SinkAPI
import Testing
@testable import SinkCore

@Suite("UserAccessStore")
@MainActor
struct UserAccessStoreTests {
    private func makeStore(
        isLicensed: Bool = false,
        features: [String] = [],
        capabilities: UserAccessCapabilitiesFixture = .none
    ) -> UserAccessStore {
        UserAccessStore {
            UserAccess(
                isLicensed: isLicensed,
                features: features,
                capabilities: capabilities.value
            )
        }
    }

    // MARK: - ios_app_access

    @Test("hasNativeAppAccess true when canUseIOSApp is true")
    func iosAppAccessGranted() async {
        let store = makeStore(capabilities: .iosAppOnly)
        await store.refresh()
        #expect(store.hasNativeAppAccess == true)
    }

    @Test("hasNativeAppAccess false when canUseIOSApp is false")
    func iosAppAccessDenied() async {
        let store = makeStore(capabilities: .none)
        await store.refresh()
        #expect(store.hasNativeAppAccess == false)
    }

    // MARK: - browser_access / core_access

    @Test("hasBrowserAccess true when canUseBrowser is true")
    func browserAccessGranted() async {
        let store = makeStore(capabilities: .browserOnly)
        await store.refresh()
        #expect(store.hasBrowserAccess == true)
    }

    @Test("hasCoreAccess true when canUseCore is true")
    func coreAccessGranted() async {
        let store = makeStore(capabilities: .coreOnly)
        await store.refresh()
        #expect(store.hasCoreAccess == true)
    }

    @Test("hasBrowserAccess and hasCoreAccess both false when no capabilities")
    func noPlaybackAccess() async {
        let store = makeStore(capabilities: .none)
        await store.refresh()
        #expect(store.hasBrowserAccess == false)
        #expect(store.hasCoreAccess == false)
    }

    // MARK: - isLicensed

    @Test("isLicensed reflects API value when true")
    func isLicensedTrue() async {
        let store = makeStore(isLicensed: true)
        await store.refresh()
        #expect(store.isLicensed == true)
    }

    @Test("isLicensed reflects API value when false")
    func isLicensedFalse() async {
        let store = makeStore(isLicensed: false)
        await store.refresh()
        #expect(store.isLicensed == false)
    }

    // MARK: - features list

    @Test("features list reflects API response")
    func featuresListPopulated() async {
        let store = makeStore(features: ["ios_app_access", "core_access"])
        await store.refresh()
        #expect(store.features.contains("ios_app_access"))
        #expect(store.features.contains("core_access"))
    }

    // MARK: - clearAccess

    @Test("clearAccess resets all gates to false")
    func clearAccessResetsGates() async {
        let store = makeStore(isLicensed: true, capabilities: .full)
        await store.refresh()
        store.clearAccess()
        #expect(store.isLicensed == false)
        #expect(store.hasNativeAppAccess == false)
        #expect(store.hasBrowserAccess == false)
        #expect(store.hasCoreAccess == false)
    }
}

// MARK: - Fixtures

private enum UserAccessCapabilitiesFixture {
    case none
    case iosAppOnly
    case browserOnly
    case coreOnly
    case full

    var value: UserAccessCapabilities {
        switch self {
        case .none:
            UserAccessCapabilities(
                canUseCore: false, canUseBrowser: false, canUseMetadata: false,
                canUseCarPlay: false, canUseIOSApp: false, canUseAlexa: false, canUseKioskMode: false
            )
        case .iosAppOnly:
            UserAccessCapabilities(
                canUseCore: false, canUseBrowser: false, canUseMetadata: false,
                canUseCarPlay: false, canUseIOSApp: true, canUseAlexa: false, canUseKioskMode: false
            )
        case .browserOnly:
            UserAccessCapabilities(
                canUseCore: false, canUseBrowser: true, canUseMetadata: false,
                canUseCarPlay: false, canUseIOSApp: false, canUseAlexa: false, canUseKioskMode: false
            )
        case .coreOnly:
            UserAccessCapabilities(
                canUseCore: true, canUseBrowser: false, canUseMetadata: false,
                canUseCarPlay: false, canUseIOSApp: false, canUseAlexa: false, canUseKioskMode: false
            )
        case .full:
            UserAccessCapabilities(
                canUseCore: true, canUseBrowser: true, canUseMetadata: true,
                canUseCarPlay: false, canUseIOSApp: true, canUseAlexa: false, canUseKioskMode: false
            )
        }
    }
}
