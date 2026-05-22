import SinkAPI
import SwiftUI

@main
struct SinkApp: App {
    private let navigation: AppNavigation
    private let authViewModel: AuthViewModel

    init() {
        let serverURL = Self.resolveServerURL()
        let navigation = AppNavigation()

        // The refresher uses a bare APIClient (no auth header) to call /v1/auth/refresh.
        // This breaks the TokenStore ↔ APIClient circular dependency cleanly.
        let tokenStore = TokenStore { refreshToken in
            let bare = APIClient(serverURL: serverURL, tokenProvider: { "" })
            return try await bare.refresh(refreshToken: refreshToken)
        }

        let apiClient = APIClient(serverURL: serverURL) {
            try await tokenStore.accessToken()
        }

        self.navigation = navigation
        self.authViewModel = AuthViewModel(
            apiClient: apiClient,
            tokenStore: tokenStore,
            navigation: navigation
        )

        Task { await Self.restoreAuthState(tokenStore: tokenStore, navigation: navigation) }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(navigation)
                .environment(authViewModel)
        }
    }

    // MARK: - Setup helpers

    private static func resolveServerURL() -> URL {
        #if DEBUG
        return URL(string: "http://localhost:8080")!
        #else
        return URL(string: "https://api.sink.fm")!
        #endif
    }

    private static func restoreAuthState(tokenStore: TokenStore, navigation: AppNavigation) async {
        let authenticated = await tokenStore.isAuthenticated
        if authenticated {
            navigation.signedIn()
        }
    }
}
