import SwiftUI

/// App-level navigation state.
///
/// Determines which root screen is visible: auth flow or the main app.
@Observable
final class AppNavigation {
    var isAuthenticated: Bool = false

    func signedIn() {
        isAuthenticated = true
    }

    func signedOut() {
        isAuthenticated = false
    }
}
