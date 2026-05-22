import Foundation
import SinkAPI

@Observable
@MainActor
final class SearchViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    var query: String = ""
    private(set) var results: [CatalogCard] = []
    private(set) var loadState: LoadState = .idle

    private let apiClient: APIClient
    private let anonymousSessionStore: AnonymousSessionStore
    private var searchTask: Task<Void, Never>?

    init(apiClient: APIClient, anonymousSessionStore: AnonymousSessionStore) {
        self.apiClient = apiClient
        self.anonymousSessionStore = anonymousSessionStore
    }

    func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(300))
            } catch {
                return
            }
            await self?.search()
        }
    }

    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            loadState = .idle
            return
        }
        loadState = .loading
        do {
            let anonToken = try? await anonymousSessionStore.sessionToken()
            let page = try await apiClient.search(
                query: trimmed,
                anonymousSessionToken: anonToken
            )
            results = page.entries
            loadState = .loaded
        } catch {
            loadState = .error(error.localizedDescription)
        }
    }
}
