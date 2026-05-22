import Foundation

// Auth API methods use URLSession directly because the backend's login endpoint returns
// two different JSON shapes (Auth or MFALoginChallenge) under the same 200 status code,
// which the generated client cannot represent as a single typed response.

// MARK: - Private request body types

private struct LoginBody: Encodable {
    let email: String
    let password: String
}

private struct RegisterBody: Encodable {
    let email: String
    let password: String
    let anonymousSessionToken: String?
    enum CodingKeys: String, CodingKey {
        case email, password
        case anonymousSessionToken = "anonymous_session_token"
    }
}

private struct NativeAppleBody: Encodable {
    let identityToken: String
    let anonymousSessionToken: String?
    enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
        case anonymousSessionToken = "anonymous_session_token"
    }
}

private struct RefreshBody: Encodable {
    let refreshToken: String
    enum CodingKeys: String, CodingKey { case refreshToken = "refresh_token" }
}

private struct ErrorBody: Decodable {
    let code: String?
    let message: String?
}

// MARK: - Auth extension

extension APIClient {
    // MARK: - Login

    public func login(email: String, password: String) async throws -> LoginResult {
        let data = try await post(path: "/v1/auth/login", body: LoginBody(email: email, password: password))

        // Backend returns Auth when MFA is not enrolled, MFALoginChallenge when it is.
        if let challenge = try? JSONDecoder().decode(MFAChallengeResponse.self, from: data),
           challenge.mfaRequired {
            return .mfaRequired(challengeToken: challenge.mfaChallengeToken)
        }
        let auth = try JSONDecoder().decode(AuthResponse.self, from: data)
        return .success(try auth.toTokens())
    }

    // MARK: - Registration

    public func register(
        email: String,
        password: String,
        anonymousSessionToken: String? = nil
    ) async throws -> AuthTokens {
        let body = RegisterBody(email: email, password: password, anonymousSessionToken: anonymousSessionToken)
        let data = try await post(path: "/v1/auth/register", body: body, expectedStatus: 201)
        return try JSONDecoder().decode(AuthResponse.self, from: data).toTokens()
    }

    // MARK: - Sign in with Apple (native)

    public func signInWithApple(
        identityToken: String,
        anonymousSessionToken: String? = nil
    ) async throws -> AuthTokens {
        let body = NativeAppleBody(identityToken: identityToken, anonymousSessionToken: anonymousSessionToken)
        let data = try await post(path: "/v1/auth/native/apple", body: body)
        return try JSONDecoder().decode(AuthResponse.self, from: data).toTokens()
    }

    // MARK: - Refresh

    public func refresh(refreshToken: String) async throws -> AuthTokens {
        let data = try await post(path: "/v1/auth/refresh", body: RefreshBody(refreshToken: refreshToken))
        return try JSONDecoder().decode(AuthResponse.self, from: data).toTokens()
    }

    // MARK: - Logout

    public func logout(refreshToken: String) async throws {
        _ = try await post(
            path: "/v1/auth/logout",
            body: RefreshBody(refreshToken: refreshToken),
            expectedStatus: 204
        )
    }

    // MARK: - Private request helper

    private func post<B: Encodable>(path: String, body: B, expectedStatus: Int = 200) async throws -> Data {
        guard let url = URL(string: path, relativeTo: serverURL) else {
            throw AuthAPIError.invalidResponse("invalid path: \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthAPIError.invalidResponse("non-HTTP response")
        }
        if http.statusCode == expectedStatus {
            return data
        }
        let err = try? JSONDecoder().decode(ErrorBody.self, from: data)
        if http.statusCode == 401 {
            throw AuthAPIError.unauthorized
        }
        throw AuthAPIError.httpError(statusCode: http.statusCode, code: err?.code, message: err?.message)
    }
}
