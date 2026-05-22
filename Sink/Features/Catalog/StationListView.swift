import SinkAPI
import SwiftUI

struct StationListView: View {
    @Environment(CatalogViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Browse")
        }
        .task { await viewModel.loadInitial() }
    }

    @ViewBuilder
    private var content: some View {
        if case .error(let message) = viewModel.loadState {
            ContentUnavailableView {
                Label("Unable to Load", systemImage: "wifi.slash")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") {
                    Task { await viewModel.loadInitial() }
                }
            }
        } else if viewModel.entries.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            stationList
        }
    }

    private var stationList: some View {
        List {
            ForEach(viewModel.entries) { station in
                NavigationLink(value: station.id) {
                    StationRowView(station: station)
                }
                .onAppear {
                    if station.id == viewModel.entries.last?.id {
                        Task { await viewModel.loadMore() }
                    }
                }
            }
            if viewModel.loadState == .loading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: String.self) { stationId in
            StationDetailView(
                stationId: stationId,
                station: viewModel.entries.first { $0.id == stationId }
            )
        }
    }
}
