import Foundation
import SinkAPI

actor AnonymousSessionStore {
    private let apiClient: APIClient
    private var cached: AnonymousSessionToken?

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // Returns a valid anonymous session token, refreshing when within 60 s of expiry.
    func sessionToken() async throws -> String {
        let now = Date()
        if let cached, cached.expiresAt > now.addingTimeInterval(60) {
            return cached.token
        }
        let fresh = try await apiClient.createAnonymousSession(existingToken: cached?.token)
        cached = fresh
        return fresh.token
    }
}
