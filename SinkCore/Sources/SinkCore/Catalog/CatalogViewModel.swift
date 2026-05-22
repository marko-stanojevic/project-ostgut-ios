import Foundation
import Observation
import SinkAPI

@Observable
@MainActor
public final class CatalogViewModel {
    public enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    public private(set) var entries: [CatalogCard] = []
    public private(set) var loadState: LoadState = .idle
    public private(set) var hasMore = false

    private let apiClient: APIClient
    private let anonymousSessionStore: AnonymousSessionStore
    private var currentOffset = 0
    private let pageSize = 50

    public init(apiClient: APIClient, anonymousSessionStore: AnonymousSessionStore) {
        self.apiClient = apiClient
        self.anonymousSessionStore = anonymousSessionStore
    }

    public func loadInitial() async {
        guard loadState != .loading else { return }
        loadState = .loading
        entries = []
        currentOffset = 0
        await fetch(offset: 0, appending: false)
    }

    public func loadMore() async {
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
