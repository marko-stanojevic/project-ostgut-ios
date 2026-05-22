import SwiftUI

public struct UpgradeView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(UserAccessStore.self) private var userAccessStore

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "lock.circle")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    Text("Upgrade Required")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Your current plan doesn't include native app access. Upgrade at sink.fm to continue listening.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button {
                    Task {
                        await userAccessStore.refresh()
                    }
                } label: {
                    Label("Refresh Access", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 32)

                Button("Sign Out", role: .destructive) {
                    Task { await authViewModel.logout() }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
