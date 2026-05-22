import SinkCore
import SwiftUI

@main
struct SinkMacApp: App {
    private let navigation: AppNavigation
    private let authViewModel: AuthViewModel
    private let apiClient: APIClient
    private let userAccessStore: UserAccessStore
    private let playerPreferencesStore: PlayerPreferencesStore
    private let catalogViewModel: CatalogViewModel
    private let searchViewModel: SearchViewModel
    private let playbackService: AVPlayerPlaybackService

    init() {
        let serverURL = Self.resolveServerURL()
        let navigation = AppNavigation()

        let tokenStore = TokenStore { refreshToken in
            let bare = APIClient(serverURL: serverURL, tokenProvider: { "" })
            return try await bare.refresh(refreshToken: refreshToken)
        }

        let apiClient = APIClient(serverURL: serverURL) {
            try await tokenStore.accessToken()
        }

        let anonymousSessionStore = AnonymousSessionStore(apiClient: apiClient)
        let userAccessStore = UserAccessStore { try await apiClient.fetchUserAccess() }
        let playbackService = Self.makePlaybackService(apiClient: apiClient)
        let playerPreferencesStore = Self.makePlayerPreferencesStore(
            apiClient: apiClient,
            playbackService: playbackService
        )

        self.navigation = navigation
        self.apiClient = apiClient
        self.userAccessStore = userAccessStore
        self.playerPreferencesStore = playerPreferencesStore
        self.playbackService = playbackService
        self.authViewModel = AuthViewModel(
            apiClient: apiClient,
            tokenStore: tokenStore,
            navigation: navigation,
            userAccessStore: userAccessStore,
            playerPreferencesStore: playerPreferencesStore
        )
        self.catalogViewModel = CatalogViewModel(
            apiClient: apiClient,
            anonymousSessionStore: anonymousSessionStore
        )
        self.searchViewModel = SearchViewModel(
            apiClient: apiClient,
            anonymousSessionStore: anonymousSessionStore
        )

        Task {
            await Self.restoreAuthState(
                tokenStore: tokenStore,
                navigation: navigation,
                userAccessStore: userAccessStore,
                playerPreferencesStore: playerPreferencesStore
            )
        }
    }

    var body: some Scene {
        Window("SINK", id: "main") {
            injectSharedEnvironment(into: MacRootView())
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)

        MenuBarExtra {
            injectSharedEnvironment(into: MenuBarPlayerView())
        } label: {
            injectSharedEnvironment(into: MenuBarIconView())
        }
        .menuBarExtraStyle(.window)
    }

    private static func makePlaybackService(apiClient: APIClient) -> AVPlayerPlaybackService {
        AVPlayerPlaybackService(
            playbackURLResolver: { id in
                let result = try await apiClient.fetchPlayback(id: id)
                return PlaybackToken(url: result.url, expiresAt: result.expiresAt)
            },
            nowPlayingResolver: { id in
                guard let result = try await apiClient.fetchNowPlaying(id: id) else { return nil }
                return NowPlayingMetadata(title: result.title, artist: result.artist)
            }
        )
    }

    private static func makePlayerPreferencesStore(
        apiClient: APIClient,
        playbackService: AVPlayerPlaybackService
    ) -> PlayerPreferencesStore {
        PlayerPreferencesStore(
            fetcher: { try await apiClient.fetchPlayerPreferences() },
            saver: { try await apiClient.updatePlayerPreferences($0) },
            volumeApplicator: { volume in
                Task { @MainActor in
                    playbackService.setVolume(Float(volume))
                }
            }
        )
    }

    private static func resolveServerURL() -> URL {
        #if DEBUG
        // swiftlint:disable:next force_unwrapping
        return URL(string: "http://localhost:8080")!
        #else
        // swiftlint:disable:next force_unwrapping
        return URL(string: "https://api.sink.fm")!
        #endif
    }

    private static func restoreAuthState(
        tokenStore: TokenStore,
        navigation: AppNavigation,
        userAccessStore: UserAccessStore,
        playerPreferencesStore: PlayerPreferencesStore
    ) async {
        let authenticated = await tokenStore.isAuthenticated
        if authenticated {
            navigation.signedIn()
            await userAccessStore.refresh()
            await playerPreferencesStore.sync()
        }
    }

    private func injectSharedEnvironment<Content: View>(into view: Content) -> some View {
        view
            .environment(navigation)
            .environment(authViewModel)
            .environment(catalogViewModel)
            .environment(searchViewModel)
            .environment(userAccessStore)
            .environment(playerPreferencesStore)
            .environment(\.apiClient, apiClient)
            .environment(\.playbackService, playbackService)
    }
}
