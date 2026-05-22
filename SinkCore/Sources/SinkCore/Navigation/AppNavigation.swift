import SwiftUI

/// App-level navigation state.
///
/// Determines which root screen is visible: auth flow or the main app.
@Observable
public final class AppNavigation {
    public var isAuthenticated: Bool = false

    public init() {}

    public func signedIn() {
        isAuthenticated = true
    }

    public func signedOut() {
        isAuthenticated = false
    }
}
