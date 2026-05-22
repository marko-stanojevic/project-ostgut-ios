import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            StationListView()
                .tabItem { Label("Browse", systemImage: "radio") }
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            AccountView()
                .tabItem { Label("Account", systemImage: "person") }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MiniPlayerView()
        }
    }
}
