import SinkAPI
import SinkPlayback
import SwiftUI

@main
struct SinkApp: App {
    private let navigation: AppNavigation
    private let authViewModel: AuthViewModel
    private let apiClient: APIClient
    private let catalogViewModel: CatalogViewModel
    private let searchViewModel: SearchViewModel
    private let playbackService: AVPlayerPlaybackService

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

        let anonymousSessionStore = AnonymousSessionStore(apiClient: apiClient)

        self.navigation = navigation
        self.apiClient = apiClient
        self.authViewModel = AuthViewModel(
            apiClient: apiClient,
            tokenStore: tokenStore,
            navigation: navigation
        )
        self.catalogViewModel = CatalogViewModel(
            apiClient: apiClient,
            anonymousSessionStore: anonymousSessionStore
        )
        self.searchViewModel = SearchViewModel(
            apiClient: apiClient,
            anonymousSessionStore: anonymousSessionStore
        )
        self.playbackService = AVPlayerPlaybackService(
            playbackURLResolver: { id in
                let result = try await apiClient.fetchPlayback(id: id)
                return PlaybackToken(url: result.url, expiresAt: result.expiresAt)
            },
            nowPlayingResolver: { id in
                guard let result = try await apiClient.fetchNowPlaying(id: id) else { return nil }
                return NowPlayingMetadata(title: result.title, artist: result.artist)
            }
        )

        Task { await Self.restoreAuthState(tokenStore: tokenStore, navigation: navigation) }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(navigation)
                .environment(authViewModel)
                .environment(catalogViewModel)
                .environment(searchViewModel)
                .environment(\.apiClient, apiClient)
                .environment(\.playbackService, playbackService)
        }
    }

    // MARK: - Setup helpers

    private static func resolveServerURL() -> URL {
        #if DEBUG
        // swiftlint:disable:next force_unwrapping
        return URL(string: "http://localhost:8080")!
        #else
        // swiftlint:disable:next force_unwrapping
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
