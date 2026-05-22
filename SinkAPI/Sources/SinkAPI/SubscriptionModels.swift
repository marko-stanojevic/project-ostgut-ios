import Foundation

// MARK: - Public models

public struct UserAccess: Sendable {
    public let isLicensed: Bool
    public let features: [String]
    public let capabilities: UserAccessCapabilities

    public init(isLicensed: Bool, features: [String], capabilities: UserAccessCapabilities) {
        self.isLicensed = isLicensed
        self.features = features
        self.capabilities = capabilities
    }

    public func hasFeature(_ key: String) -> Bool {
        features.contains(key)
    }
}

public struct UserAccessCapabilities: Sendable {
    public let canUseCore: Bool
    public let canUseBrowser: Bool
    public let canUseMetadata: Bool
    public let canUseCarPlay: Bool
    public let canUseIOSApp: Bool
    public let canUseAlexa: Bool
    public let canUseKioskMode: Bool

    public init(
        canUseCore: Bool,
        canUseBrowser: Bool,
        canUseMetadata: Bool,
        canUseCarPlay: Bool,
        canUseIOSApp: Bool,
        canUseAlexa: Bool,
        canUseKioskMode: Bool
    ) {
        self.canUseCore = canUseCore
        self.canUseBrowser = canUseBrowser
        self.canUseMetadata = canUseMetadata
        self.canUseCarPlay = canUseCarPlay
        self.canUseIOSApp = canUseIOSApp
        self.canUseAlexa = canUseAlexa
        self.canUseKioskMode = canUseKioskMode
    }
}

// MARK: - Internal decoders

struct UserAccessJSON: Decodable {
    let isLicensed: Bool
    let features: [String]
    let capabilities: UserAccessCapabilitiesJSON

    func toModel() -> UserAccess {
        UserAccess(isLicensed: isLicensed, features: features, capabilities: capabilities.toModel())
    }
}

struct UserAccessCapabilitiesJSON: Decodable {
    let canUseCore: Bool
    let canUseBrowser: Bool
    let canUseMetadata: Bool
    let canUseCarPlay: Bool
    let canUseIosApp: Bool
    let canUseAlexa: Bool
    let canUseKioskMode: Bool

    func toModel() -> UserAccessCapabilities {
        UserAccessCapabilities(
            canUseCore: canUseCore,
            canUseBrowser: canUseBrowser,
            canUseMetadata: canUseMetadata,
            canUseCarPlay: canUseCarPlay,
            canUseIOSApp: canUseIosApp,
            canUseAlexa: canUseAlexa,
            canUseKioskMode: canUseKioskMode
        )
    }
}
