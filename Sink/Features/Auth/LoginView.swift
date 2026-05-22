import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false

    @Environment(AuthViewModel.self) private var viewModel
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                logoSection

                Spacer().frame(height: 48)

                formSection

                Spacer().frame(height: 16)

                signUpLink

                Spacer()
            }
            .padding(.horizontal, 32)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .alert(errorTitle, isPresented: errorBinding) {
                Button("OK") { viewModel.clearError() }
            } message: {
                if case .error(let msg) = viewModel.state {
                    Text(msg)
                }
            }
        }
    }

    // MARK: - Sections

    private var logoSection: some View {
        VStack(spacing: 8) {
            Text("SINK")
                .font(.system(size: 40, weight: .black, design: .default))
                .tracking(8)
            Text("Curated Radio")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding()
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))

            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding()
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))

            Button {
                Task { await viewModel.login(email: email, password: password) }
            } label: {
                Group {
                    if case .loading = viewModel.state {
                        ProgressView()
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.state == .loading)

            divider

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task {
                    switch result {
                    case .success(let authorization):
                        await viewModel.handleAppleAuthorization(authorization)
                    case .failure(let error):
                        viewModel.handleAppleError(error)
                    }
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .cornerRadius(12)
        }
    }

    private var divider: some View {
        HStack {
            Rectangle().frame(height: 1).foregroundStyle(.separator)
            Text("or").foregroundStyle(.secondary).font(.caption)
            Rectangle().frame(height: 1).foregroundStyle(.separator)
        }
    }

    private var signUpLink: some View {
        Button {
            showSignUp = true
        } label: {
            Text("Don't have an account? ")
                .foregroundStyle(.secondary)
            + Text("Create one")
                .foregroundStyle(.primary)
        }
        .font(.footnote)
    }

    // MARK: - Alert helpers

    private var errorTitle: String { "Sign In Failed" }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { if case .error = viewModel.state { return true }; return false },
            set: { if !$0 { viewModel.clearError() } }
        )
    }
}

// MARK: - AuthViewModel.State equatable helper

extension AuthViewModel.State: Equatable {
    static func == (lhs: AuthViewModel.State, rhs: AuthViewModel.State) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading): return true
        case (.error(let lhsMessage), .error(let rhsMessage)): return lhsMessage == rhsMessage
        default: return false
        }
    }
}
