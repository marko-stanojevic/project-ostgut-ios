import AuthenticationServices
import Foundation
import SinkAPI

/// View model shared by LoginView and SignUpView.
@Observable
@MainActor
final class AuthViewModel {
    enum State {
        case idle
        case loading
        case error(String)
    }

    var state: State = .idle

    private let apiClient: APIClient
    private let tokenStore: TokenStore
    private let navigation: AppNavigation
    private let userAccessStore: UserAccessStore
    private let playerPreferencesStore: PlayerPreferencesStore

    init(
        apiClient: APIClient,
        tokenStore: TokenStore,
        navigation: AppNavigation,
        userAccessStore: UserAccessStore,
        playerPreferencesStore: PlayerPreferencesStore
    ) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
        self.navigation = navigation
        self.userAccessStore = userAccessStore
        self.playerPreferencesStore = playerPreferencesStore
    }

    // MARK: - Email / Password

    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            state = .error("Email and password are required.")
            return
        }
        state = .loading
        do {
            let result = try await apiClient.login(email: email, password: password)
            switch result {
            case .success(let tokens):
                await tokenStore.store(tokens)
                navigation.signedIn()
                await userAccessStore.refresh()
                await playerPreferencesStore.sync()
            case .mfaRequired:
                state = .error("MFA is required. Please sign in via the web app to complete setup.")
            }
        } catch {
            state = .error(friendlyMessage(for: error))
        }
    }

    func register(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            state = .error("Email and password are required.")
            return
        }
        guard password.count >= 8 else {
            state = .error("Password must be at least 8 characters.")
            return
        }
        state = .loading
        do {
            let tokens = try await apiClient.register(email: email, password: password)
            await tokenStore.store(tokens)
            navigation.signedIn()
            await userAccessStore.refresh()
            await playerPreferencesStore.sync()
        } catch {
            state = .error(friendlyMessage(for: error))
        }
    }

    // MARK: - Sign in with Apple

    func handleAppleAuthorization(_ authorization: ASAuthorization) async {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8)
        else {
            state = .error("Sign in with Apple failed. Please try again.")
            return
        }
        state = .loading
        do {
            let tokens = try await apiClient.signInWithApple(identityToken: identityToken)
            await tokenStore.store(tokens)
            navigation.signedIn()
            await userAccessStore.refresh()
            await playerPreferencesStore.sync()
        } catch {
            state = .error(friendlyMessage(for: error))
        }
    }

    func handleAppleError(_ error: Error) {
        if case ASAuthorizationError.canceled = error { return }
        state = .error("Sign in with Apple failed. Please try again.")
    }

    func clearError() {
        if case .error = state { state = .idle }
    }

    func logout() async {
        let refreshToken = await tokenStore.storedRefreshToken
        await tokenStore.clear()
        userAccessStore.clearAccess()
        playerPreferencesStore.clearPreferences()
        navigation.signedOut()
        if let token = refreshToken {
            try? await apiClient.logout(refreshToken: token)
        }
    }

    // MARK: - Helpers

    private func friendlyMessage(for error: Error) -> String {
        if let authErr = error as? AuthAPIError {
            switch authErr {
            case .unauthorized:
                return "Incorrect email or password."
            case .httpError(let status, _, let message):
                if status == 409 { return "An account with this email already exists." }
                return message ?? "Something went wrong. Please try again."
            case .invalidResponse:
                return "Something went wrong. Please try again."
            }
        }
        return error.localizedDescription
    }
}
