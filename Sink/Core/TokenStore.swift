import Foundation
import SinkAPI

// MARK: - Errors

public enum TokenError: Error, Sendable {
    case notAuthenticated
    case refreshFailed(Error)
}

// MARK: - TokenStore

/// Manages access and refresh tokens in the Keychain.
///
/// `accessToken()` returns a valid token, silently refreshing when the token
/// is within 60 seconds of expiry. Concurrent calls coalesce onto a single
/// in-flight refresh task.
public actor TokenStore {
    private let refresher: @Sendable (_ refreshToken: String) async throws -> AuthTokens

    private var storedAccessToken: String?
    private(set) var storedRefreshToken: String?
    private var expiresAt: Date?
    private var inflightRefresh: Task<String, Error>?

    private static let accessTokenKey = "fm.sink.app.accessToken"
    private static let refreshTokenKey = "fm.sink.app.refreshToken"
    private static let expiryKey = "fm.sink.app.tokenExpiry"

    public init(refresher: @escaping @Sendable (_ refreshToken: String) async throws -> AuthTokens) {
        self.refresher = refresher
        loadFromKeychain()
    }

    // MARK: - Public API

    public var isAuthenticated: Bool {
        storedRefreshToken != nil
    }

    /// Returns a valid access token, refreshing silently when within 60 seconds of expiry.
    public func accessToken() async throws -> String {
        if let token = storedAccessToken, let exp = expiresAt, exp > Date().addingTimeInterval(60) {
            return token
        }
        if let task = inflightRefresh {
            return try await task.value
        }
        let task = Task { try await self.performRefresh() }
        inflightRefresh = task
        do {
            let token = try await task.value
            inflightRefresh = nil
            return token
        } catch {
            inflightRefresh = nil
            throw error
        }
    }

    /// Stores new tokens (called after successful login, register, or OAuth sign-in).
    public func store(_ tokens: AuthTokens) {
        storedAccessToken = tokens.accessToken
        storedRefreshToken = tokens.refreshToken
        expiresAt = tokens.accessTokenExpiresAt
        saveToKeychain(tokens)
    }

    /// Clears all tokens from memory and Keychain (logout).
    public func clear() {
        storedAccessToken = nil
        storedRefreshToken = nil
        expiresAt = nil
        deleteFromKeychain()
    }

    // MARK: - Refresh

    private func performRefresh() async throws -> String {
        guard let refreshToken = storedRefreshToken else {
            throw TokenError.notAuthenticated
        }
        do {
            let tokens = try await refresher(refreshToken)
            store(tokens)
            return tokens.accessToken
        } catch {
            throw TokenError.refreshFailed(error)
        }
    }

    // MARK: - Keychain

    private func loadFromKeychain() {
        storedAccessToken = keychainRead(key: TokenStore.accessTokenKey)
        storedRefreshToken = keychainRead(key: TokenStore.refreshTokenKey)
        if let raw = keychainRead(key: TokenStore.expiryKey),
           let ts = Double(raw) {
            expiresAt = Date(timeIntervalSince1970: ts)
        }
    }

    private func saveToKeychain(_ tokens: AuthTokens) {
        keychainWrite(key: TokenStore.accessTokenKey, value: tokens.accessToken)
        keychainWrite(key: TokenStore.refreshTokenKey, value: tokens.refreshToken)
        keychainWrite(key: TokenStore.expiryKey, value: String(tokens.accessTokenExpiresAt.timeIntervalSince1970))
    }

    private func deleteFromKeychain() {
        keychainDelete(key: TokenStore.accessTokenKey)
        keychainDelete(key: TokenStore.refreshTokenKey)
        keychainDelete(key: TokenStore.expiryKey)
    }
}

// MARK: - Keychain helpers

private func keychainRead(key: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess,
          let data = result as? Data,
          let string = String(data: data, encoding: .utf8)
    else { return nil }
    return string
}

private func keychainWrite(key: String, value: String) {
    guard let data = value.data(using: .utf8) else { return }
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
    ]
    let attrs: [String: Any] = [kSecValueData as String: data]
    let status = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
    if status == errSecItemNotFound {
        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}

private func keychainDelete(key: String) {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
    ]
    SecItemDelete(query as CFDictionary)
}
