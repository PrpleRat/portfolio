import AudioToolbox
import AVFoundation
import Foundation

enum SoundManager {
    private static var player: AVAudioPlayer?

    static func playAlertSound(named name: String = "alert_sound") {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            AudioServicesPlaySystemSound(1005)
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            AudioServicesPlaySystemSound(1005)
        }
    }
}
