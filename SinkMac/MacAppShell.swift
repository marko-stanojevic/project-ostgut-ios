import SinkCore
import SwiftUI

struct MacAppShell: View {
    @State private var selectedSection: MacSection? = .catalog

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            VStack(spacing: 0) {
                List(MacSection.allCases, id: \.self, selection: $selectedSection) { section in
                    Label(section.title, systemImage: section.icon)
                        .tag(section)
                }
                .navigationTitle("SINK")

                Divider()

                MiniPlayerView()
                    .padding()
            }
        } detail: {
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
}

private enum MacSection: String, CaseIterable, Hashable {
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
