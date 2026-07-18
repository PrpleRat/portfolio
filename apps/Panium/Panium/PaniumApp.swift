import SwiftUI

@main
struct PaniumApp: App {
    @StateObject private var audio = HandpanAudioEngine.shared
    @StateObject private var playback = NotePlaybackTracker()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audio)
                .environmentObject(playback)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}
