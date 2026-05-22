import Foundation
import SinkAPI

@Observable
@MainActor
final class CatalogViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    private(set) var entries: [CatalogCard] = []
    private(set) var loadState: LoadState = .idle
    private(set) var hasMore = false

    private let apiClient: APIClient
    private let anonymousSessionStore: AnonymousSessionStore
    private var currentOffset = 0
    private let pageSize = 50

    init(apiClient: APIClient, anonymousSessionStore: AnonymousSessionStore) {
        self.apiClient = apiClient
        self.anonymousSessionStore = anonymousSessionStore
    }

    func loadInitial() async {
        guard loadState != .loading else { return }
        loadState = .loading
        entries = []
        currentOffset = 0
        await fetch(offset: 0, appending: false)
    }

    func loadMore() async {
        guard loadState == .loaded, hasMore else { return }
        await fetch(offset: currentOffset, appending: true)
    }

    private func fetch(offset: Int, appending: Bool) async {
        do {
            let anonToken = try? await anonymousSessionStore.sessionToken()
            let page = try await apiClient.fetchCatalog(
                limit: pageSize,
                offset: offset,
                anonymousSessionToken: anonToken
            )
            if appending {
                entries.append(contentsOf: page.entries)
            } else {
                entries = page.entries
            }
            currentOffset = offset + page.entries.count
            hasMore = page.hasMore
            loadState = .loaded
        } catch {
            loadState = .error(error.localizedDescription)
        }
    }
}
