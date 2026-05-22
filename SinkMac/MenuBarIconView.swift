import SinkCore
import SwiftUI

struct MenuBarIconView: View {
    @Environment(\.playbackService) private var playbackService

    var body: some View {
        Image(systemName: playbackService?.state.isPlaying == true ? "waveform" : "radio")
            .accessibilityLabel("SINK")
    }
}
