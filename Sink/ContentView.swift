import SwiftUI

/// Placeholder root content — replaced by the catalog and player in ios-8/ios-9.
struct ContentView: View {
    @Environment(AuthViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("SINK")
                .font(.system(size: 40, weight: .black))
                .tracking(8)
            Text("You're signed in.")
                .foregroundStyle(.secondary)
            Button("Sign Out", role: .destructive) {
                Task { await viewModel.logout() }
            }
        }
    }
}
