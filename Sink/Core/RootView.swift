import SwiftUI

/// Top-level view that gates on authentication state.
struct RootView: View {
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        if navigation.isAuthenticated {
            ContentView()
        } else {
            LoginView()
        }
    }
}
