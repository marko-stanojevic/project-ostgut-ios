import Foundation
import SinkAPI

public actor AnonymousSessionStore {
    private let apiClient: APIClient
    private var cached: AnonymousSessionToken?

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func sessionToken() async throws -> String {
        let now = Date()
        if let cached, cached.expiresAt > now.addingTimeInterval(60) {
            return cached.token
        }
        let fresh = try await apiClient.createAnonymousSession(existingToken: cached?.token)
        cached = fresh
        return fresh.token
    }
}
