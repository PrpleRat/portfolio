import AVFoundation
import AudioToolbox
import Foundation
/// Sons de réveil bundlés (rain, bowl, birds) + preview AVAudioPlayer.
@MainActor
final class AlarmSoundLibrary: ObservableObject {
    static let shared = AlarmSoundLibrary()
    static let userDefaultsKey = "alarmSoundFilename"

    @Published private(set) var isPreviewPlaying = false

    private var previewPlayer: AVAudioPlayer?

    private init() {}

    var selectedFilename: String {
        get {
            UserDefaults.standard.string(forKey: Self.userDefaultsKey)
                ?? AlarmSound.rain.fileName
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.userDefaultsKey)
        }
    }

    var selectedSound: AlarmSound {
        AlarmSound(filename: selectedFilename) ?? .rain
    }

    func select(_ sound: AlarmSound) {
        selectedFilename = sound.fileName
    }

    func preview(_ sound: AlarmSound) {
        stopPreview()
        guard let url = sound.bundleURL else {
            AudioServicesPlaySystemSound(1005)
            return
        }
        configureAudioSession()
        previewPlayer = try? AVAudioPlayer(contentsOf: url)
        previewPlayer?.volume = 0.85
        previewPlayer?.numberOfLoops = 0
        previewPlayer?.play()
        isPreviewPlaying = true
    }

    func stopPreview() {
        previewPlayer?.stop()
        previewPlayer = nil
        isPreviewPlaying = false
    }

    func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
    }

}
