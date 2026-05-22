import Foundation

/// Auth tokens returned by login, register, refresh, and OAuth sign-in endpoints.
public struct AuthTokens: Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let accessTokenExpiresAt: Date

    public init(accessToken: String, refreshToken: String, accessTokenExpiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accessTokenExpiresAt = accessTokenExpiresAt
    }
}

/// Result of a login attempt.
public enum LoginResult: Sendable {
    /// Successfully authenticated; tokens are ready.
    case success(AuthTokens)
    /// MFA is required; pass the challenge token to the MFA verify endpoint.
    case mfaRequired(challengeToken: String)
}

// MARK: - Internal decoding helpers

private let iso8601 = ISO8601DateFormatter()

struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let accessTokenExpiresAt: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case accessTokenExpiresAt = "access_token_expires_at"
    }

    func toTokens() throws -> AuthTokens {
        guard let date = iso8601.date(from: accessTokenExpiresAt) else {
            throw AuthAPIError.invalidResponse("unparseable access_token_expires_at: \(accessTokenExpiresAt)")
        }
        return AuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            accessTokenExpiresAt: date
        )
    }
}

struct MFAChallengeResponse: Decodable {
    let mfaRequired: Bool
    let mfaChallengeToken: String

    enum CodingKeys: String, CodingKey {
        case mfaRequired = "mfa_required"
        case mfaChallengeToken = "mfa_challenge_token"
    }
}

/// Errors from the auth API layer.
public enum AuthAPIError: Error, Sendable {
    case httpError(statusCode: Int, code: String?, message: String?)
    case invalidResponse(String)
    case unauthorized
}
