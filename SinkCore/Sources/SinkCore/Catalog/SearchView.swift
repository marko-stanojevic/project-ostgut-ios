import SinkAPI
import SinkPlayback
import SwiftUI

public struct SearchView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @Environment(\.playbackService) private var playbackService

    public init() {}

    public var body: some View {
        NavigationStack {
            searchContent
                .navigationTitle("Search")
                .searchable(
                    text: Bindable(viewModel).query,
                    prompt: "Station, genre, city…"
                )
                .onChange(of: viewModel.query) { _, _ in
                    viewModel.scheduleSearch()
                }
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        if viewModel.query.isEmpty {
            ContentUnavailableView(
                "Search Stations",
                systemImage: "magnifyingglass",
                description: Text("Search by station name, genre, or city.")
            )
        } else if case .error(let message) = viewModel.loadState {
            ContentUnavailableView {
                Label("Search Failed", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            }
        } else if viewModel.loadState == .loading {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 200)
        } else if viewModel.results.isEmpty {
            ContentUnavailableView.search(text: viewModel.query)
        } else {
            resultList
        }
    }

    private var resultList: some View {
        List {
            ForEach(viewModel.results) { station in
                NavigationLink(value: station.id) {
                    StationRowView(
                        station: station,
                        isPlaying: playbackService?.state.currentStation?.id == station.id
                    )
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: String.self) { stationId in
            StationDetailView(
                stationId: stationId,
                station: viewModel.results.first { $0.id == stationId }
            )
        }
    }
}
