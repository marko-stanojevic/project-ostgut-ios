import SinkAPI
import SwiftUI

struct StationRowView: View {
    let station: CatalogCard

    var body: some View {
        HStack(spacing: 16) {
            stationIcon
            VStack(alignment: .leading, spacing: 4) {
                Text(station.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
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
            if station.staffPick {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        Color(.systemGray5)
    }
}
