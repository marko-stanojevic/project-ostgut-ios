import SinkAPI
import SwiftUI

struct StationDetailView: View {
    let stationId: String
    let station: CatalogCard?

    @Environment(\.apiClient) private var apiClient
    @State private var detail: CatalogDetail?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                detailBody
            }
            .padding()
        }
        .navigationTitle(detail?.name ?? station?.name ?? "")
        .navigationBarTitleDisplayMode(.large)
        .task { await loadDetail() }
    }

    @ViewBuilder
    private var detailBody: some View {
        if let detail {
            stationHeader(name: detail.name, icon: detail.icon)
            if !detail.city.isEmpty || !detail.country.isEmpty {
                metadataRow(country: detail.country, city: detail.city, language: detail.language)
            }
            if !detail.overview.isEmpty {
                Text(detail.overview)
                    .font(.body)
            }
            if let review = detail.editorialReview {
                Text(review)
                    .font(.body)
                    .italic()
                    .foregroundStyle(.secondary)
            }
            tagScrollRow(tags: detail.genreTags + detail.formatTags)
            playButton
        } else if let station {
            stationHeader(name: station.name, icon: station.icon)
            tagScrollRow(tags: station.genreTags)
            if let message = errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        } else if let message = errorMessage {
            ContentUnavailableView {
                Label("Station Unavailable", systemImage: "exclamationmark.circle")
            } description: {
                Text(message)
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 200)
        }
    }

    private func stationHeader(name: String, icon: CatalogIcon?) -> some View {
        HStack(spacing: 16) {
            Group {
                if let iconURL = icon.flatMap({ URL(string: $0.url) }) {
                    AsyncImage(url: iconURL) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Color(.systemGray5)
                        }
                    }
                } else {
                    Color(.systemGray5)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(name)
                .font(.title2)
                .fontWeight(.bold)
        }
    }

    private func metadataRow(country: String, city: String, language: String) -> some View {
        let parts = [city, country, language].filter { !$0.isEmpty }
        return Text(parts.joined(separator: " · "))
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private func tagScrollRow(tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var playButton: some View {
        Button {
            // Playback wired in ios-10
        } label: {
            Label("Play", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    private func loadDetail() async {
        guard let client = apiClient else {
            errorMessage = "API client unavailable"
            return
        }
        do {
            detail = try await client.fetchCatalogDetail(id: stationId)
        } catch CatalogAPIError.notFound {
            errorMessage = "Station not found"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
