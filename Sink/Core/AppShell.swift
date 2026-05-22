import SinkCore
import SwiftUI

struct AppShell: View {
    @State private var selectedSection: AppSection? = .catalog

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, id: \.self, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("SINK")
        } detail: {
            detailContent
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    MiniPlayerView()
                }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selectedSection ?? .catalog {
        case .catalog:
            StationListView()
        case .search:
            SearchView()
        case .account:
            AccountView()
        }
    }
}

private enum AppSection: String, CaseIterable, Hashable {
    case catalog
    case search
    case account

    var title: String {
        switch self {
        case .catalog:
            "Browse"
        case .search:
            "Search"
        case .account:
            "Account"
        }
    }

    var icon: String {
        switch self {
        case .catalog:
            "radio"
        case .search:
            "magnifyingglass"
        case .account:
            "person"
        }
    }
}
