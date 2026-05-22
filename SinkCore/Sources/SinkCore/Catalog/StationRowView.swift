import SinkAPI
import SwiftUI

public struct StationRowView: View {
    public let station: CatalogCard
    public var isPlaying: Bool = false

    public init(station: CatalogCard, isPlaying: Bool = false) {
        self.station = station
        self.isPlaying = isPlaying
    }

    public var body: some View {
        HStack(spacing: 16) {
            stationIcon
            VStack(alignment: .leading, spacing: 4) {
                Text(station.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundStyle(isPlaying ? Color.accentColor : Color.primary)
                HStack(spacing: 6) {
                    Text(station.country)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let genre = station.genreTags.first {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(genre)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            HStack(spacing: 8) {
                if isPlaying {
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundStyle(.tint)
                }
                if station.staffPick {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var stationIcon: some View {
        Group {
            if let iconURL = station.icon.flatMap({ URL(string: $0.url) }) {
                AsyncImage(url: iconURL) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        iconPlaceholder
                    }
                }
            } else {
                iconPlaceholder
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var iconPlaceholder: some View {
        Color.secondary.opacity(0.15)
    }
}
