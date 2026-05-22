import SinkPlayback
import SwiftUI

struct NowPlayingView: View {
    @Environment(\.playbackService) private var playbackService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let service = playbackService {
            content(service: service)
                .onChange(of: service.state.currentStation == nil) { _, isNil in
                    if isNil { dismiss() }
                }
        }
    }

    @ViewBuilder
    private func content(service: AVPlayerPlaybackService) -> some View {
        VStack(spacing: 0) {
            dragHandle
                .padding(.top, 12)
            Spacer()
            artworkView(service.state.currentStation?.iconURL)
                .padding(.bottom, 32)
            stationInfo(service)
                .padding(.bottom, 48)
            controls(service)
            Spacer()
        }
        .padding(.horizontal, 32)
        .presentationDragIndicator(.hidden)
    }

    private var dragHandle: some View {
        Capsule()
            .fill(Color(.systemGray4))
            .frame(width: 36, height: 5)
    }

    private func artworkView(_ iconURL: URL?) -> some View {
        Group {
            if let url = iconURL {
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
        .frame(width: 280, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 16, y: 8)
    }

    @ViewBuilder
    private func stationInfo(_ service: AVPlayerPlaybackService) -> some View {
        VStack(spacing: 6) {
            if let station = service.state.currentStation {
                Text(station.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            // Track and artist metadata — wired in ios-11
            Text("Live")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func controls(_ service: AVPlayerPlaybackService) -> some View {
        HStack(spacing: 56) {
            Button {
                service.stop()
                dismiss()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Button {
                if service.state.isPlaying {
                    service.pause()
                } else {
                    service.resume()
                }
            } label: {
                Image(systemName: service.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 72))
            }
            .buttonStyle(.plain)
        }
    }
}
