import Foundation
import HTTPTypes
import OpenAPIRuntime
import OpenAPIURLSession

/// Entry point for all backend API calls.
///
/// Wraps the generated `Client` with Bearer token injection. Pass a
/// `tokenProvider` closure that returns the current access token; for
/// unauthenticated contexts pass `{ "" }` and no Authorization header
/// is sent.
public final class APIClient: Sendable {
    // The generated Client is internal to SinkAPI; app code uses APIClient methods instead.
    let client: Client
    public let serverURL: URL
    let tokenProvider: @Sendable () async throws -> String

    public init(
        serverURL: URL,
        tokenProvider: @escaping @Sendable () async throws -> String
    ) {
        self.serverURL = serverURL
        self.tokenProvider = tokenProvider
        client = Client(
            serverURL: serverURL,
            transport: URLSessionTransport(),
            middlewares: [BearerAuthMiddleware(tokenProvider: tokenProvider)]
        )
    }

    /// Applies auth headers to a mutable URLRequest.
    /// Injects Bearer token when one is available; falls back to anonymous session token.
    func authorizeRequest(_ request: inout URLRequest, anonymousSessionToken: String?) async {
        let token = (try? await tokenProvider()) ?? ""
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if let anonToken = anonymousSessionToken {
            request.setValue(anonToken, forHTTPHeaderField: "X-Anonymous-Session")
        }
    }
}

// MARK: - Middleware

struct BearerAuthMiddleware: ClientMiddleware {
    let tokenProvider: @Sendable () async throws -> String

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let token = try await tokenProvider()
        var request = request
        if !token.isEmpty {
            request.headerFields[.authorization] = "Bearer \(token)"
        }
        return try await next(request, body, baseURL)
    }
}
