import SinkCore
import SinkPlayback
import SwiftUI

struct MenuBarPlayerView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.playbackService) private var playbackService
    @Environment(PlayerPreferencesStore.self) private var playerPreferencesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            stationInfo
            controls
        }
        .padding(16)
        .frame(width: 280)
    }

    @ViewBuilder
    private var stationInfo: some View {
        if let station = displayStation {
            Button {
                openWindow(id: "main")
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(station.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let metadata = playbackService?.nowPlayingMetadata, !isRestoredStation {
                        Text(nowPlayingLine(from: metadata))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text(isRestoredStation ? "Ready to resume" : playbackStatusLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("Nothing playing")
                    .font(.headline)
                Text("Start a station in SINK to control playback here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                handlePrimaryAction()
            } label: {
                Label(primaryButtonTitle, systemImage: primaryButtonIcon)
                    .frame(maxWidth: .infinity)
            }
            .disabled(displayStation == nil || playbackService == nil)

            Button("Open SINK") {
                openWindow(id: "main")
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var displayStation: Station? {
        playbackService?.state.currentStation ?? playerPreferencesStore.restoredStation
    }

    private var isRestoredStation: Bool {
        playbackService?.state.currentStation == nil && displayStation != nil
    }

    private var primaryButtonTitle: String {
        guard displayStation != nil else { return "Play" }
        return playbackService?.state.isPlaying == true ? "Pause" : "Play"
    }

    private var primaryButtonIcon: String {
        playbackService?.state.isPlaying == true ? "pause.fill" : "play.fill"
    }

    private var playbackStatusLabel: String {
        guard let service = playbackService else { return "Unavailable" }
        switch service.state {
        case .idle:
            return "Idle"
        case .loading:
            return "Loading…"
        case .playing:
            return "Live now"
        case .paused:
            return "Paused"
        case .error:
            return "Playback unavailable"
        }
    }

    private func handlePrimaryAction() {
        guard let station = displayStation, let service = playbackService else { return }

        if isRestoredStation {
            playerPreferencesStore.trackPlayback(station: station)
            Task { try? await service.play(station: station) }
            return
        }

        if service.state.isPlaying {
            service.pause()
        } else {
            service.resume()
        }
    }

    private func nowPlayingLine(from metadata: NowPlayingMetadata) -> String {
        if metadata.artist.isEmpty {
            return metadata.title
        }
        return "\(metadata.title) • \(metadata.artist)"
    }
}
