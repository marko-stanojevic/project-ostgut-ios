import SwiftUI

public struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @Environment(AuthViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()

            header

            Spacer().frame(height: 48)

            formSection

            Spacer().frame(height: 16)

            signInLink

            Spacer()
        }
        .padding(.horizontal, 32)
        .navigationTitle("")
        .alert("Sign Up Failed", isPresented: errorBinding) {
            Button("OK") { viewModel.clearError() }
        } message: {
            if case .error(let msg) = viewModel.state {
                Text(msg)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Create Account")
                .font(.title.bold())
            Text("Start listening to curated radio.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .padding()
                .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            SecureField("Password", text: $password)
                .textContentType(.newPassword)
                .padding()
                .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            SecureField("Confirm Password", text: $confirmPassword)
                .textContentType(.newPassword)
                .padding()
                .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            Button {
                guard password == confirmPassword else {
                    return
                }
                Task { await viewModel.register(email: email, password: password) }
            } label: {
                Group {
                    if case .loading = viewModel.state {
                        ProgressView()
                    } else {
                        Text("Create Account")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.state == .loading || password != confirmPassword)

            if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                Text("Passwords don't match.")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    private var signInLink: some View {
        Button {
            dismiss()
        } label: {
            Text("Already have an account? ")
                .foregroundStyle(.secondary)
            + Text("Sign In")
                .foregroundStyle(.primary)
        }
        .font(.footnote)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { if case .error = viewModel.state { return true }; return false },
            set: { if !$0 { viewModel.clearError() } }
        )
    }
}
