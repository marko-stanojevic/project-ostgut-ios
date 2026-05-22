import SinkPlayback
import SwiftUI

struct MiniPlayerView: View {
    @Environment(\.playbackService) private var playbackService
    @State private var showNowPlaying = false

    var body: some View {
        if let service = playbackService, let station = service.state.currentStation {
            bar(service: service, station: station)
                .sheet(isPresented: $showNowPlaying) {
                    NowPlayingView()
                }
        }
    }

    private func bar(service: AVPlayerPlaybackService, station: Station) -> some View {
        HStack(spacing: 12) {
            stationIcon(station.iconURL)
            Text(station.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            Spacer()
            Button {
                if service.state.isPlaying {
                    service.pause()
                } else {
                    service.resume()
                }
            } label: {
                Image(systemName: service.state.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .contentShape(Rectangle())
        .onTapGesture { showNowPlaying = true }
    }

    private func stationIcon(_ url: URL?) -> some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
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
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
