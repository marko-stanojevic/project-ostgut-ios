import SwiftUI

public struct AccountView: View {
    @Environment(AppNavigation.self) private var navigation
    @Environment(AuthViewModel.self) private var authViewModel

    public init() {}

    public var body: some View {
        NavigationStack {
            if navigation.isAuthenticated {
                authenticatedContent
            } else {
                unauthenticatedContent
            }
        }
    }

    private var authenticatedContent: some View {
        List {
            Section {
                Button("Sign Out", role: .destructive) {
                    Task { await authViewModel.logout() }
                }
            }
        }
        .navigationTitle("Account")
    }

    private var unauthenticatedContent: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 12) {
                Text("Sign in to SINK")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Save your favourites and sync preferences across devices.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            NavigationLink("Sign In") {
                LoginView()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .navigationTitle("Account")
    }
}
