import Testing
import Foundation
@testable import SinkAPI

@Suite("AnonymousSessionToken")
struct AnonymousSessionTokenTests {
    @Test("token is not expired when expiry is far future")
    func notExpired() {
        let token = AnonymousSessionToken(
            token: "abc",
            expiresAt: Date().addingTimeInterval(3600)
        )
        #expect(token.expiresAt > Date())
    }

    @Test("token string is preserved")
    func tokenStringPreserved() {
        let token = AnonymousSessionToken(token: "test-token-123", expiresAt: Date())
        #expect(token.token == "test-token-123")
    }
}
