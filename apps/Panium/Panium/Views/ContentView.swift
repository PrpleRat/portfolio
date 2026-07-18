import SwiftUI

struct ContentView: View {
    var body: some View {
        HandpanScreen()
            .background(HandpanColors.background.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
        .environmentObject(HandpanAudioEngine.shared)
        .environmentObject(NotePlaybackTracker())
}
