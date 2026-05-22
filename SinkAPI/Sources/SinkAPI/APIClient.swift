import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

/// Entry point for all backend API calls.
///
/// Wraps the generated `Client` with Bearer token injection. Pass a
/// `tokenProvider` closure that returns the current access token; for
/// unauthenticated contexts pass `{ "" }` and no Authorization header
/// is sent.
///
/// Usage (authenticated):
/// ```swift
/// let api = APIClient(serverURL: serverURL) {
///     try await tokenStore.accessToken()
/// }
/// let response = try await api.client.getV1Catalog(.init())
/// ```
public final class APIClient: Sendable {
    public let client: Client
    public let serverURL: URL

    public init(
        serverURL: URL,
        tokenProvider: @escaping @Sendable () async throws -> String
    ) {
        self.serverURL = serverURL
        client = Client(
            serverURL: serverURL,
            transport: URLSessionTransport(),
            middlewares: [BearerAuthMiddleware(tokenProvider: tokenProvider)]
        )
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
