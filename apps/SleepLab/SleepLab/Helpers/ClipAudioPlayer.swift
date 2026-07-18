import AVFoundation
import Foundation

/// Lecture des clips nocturnes avec barre de progression et sortie haut-parleur.
@MainActor
final class ClipAudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var loadFailed = false

    private var player: AVAudioPlayer?
    private var progressTimer: Timer?

    func load(fileName: String) {
        stop()
        loadFailed = false
        let url = AudioHelpers.clipURL(fileName: fileName)
        guard FileManager.default.fileExists(atPath: url.path) else {
            loadFailed = true
            return
        }
        configurePlaybackSession()
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            p.volume = 1.0
            p.enableRate = false
            p.prepareToPlay()
            player = p
            duration = p.duration
            currentTime = 0
            progress = 0
        } catch {
            loadFailed = true
        }
    }

    func toggle() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
            stopProgressTimer()
        } else {
            configurePlaybackSession()
            player.play()
            isPlaying = true
            startProgressTimer()
        }
    }

    func seek(fraction: Double) {
        guard let player, duration > 0 else { return }
        let t = max(0, min(duration, duration * fraction))
        player.currentTime = t
        updateProgressFromPlayer()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        progress = 0
        currentTime = 0
        duration = 0
        stopProgressTimer()
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.progress = 1
            self.currentTime = self.duration
            self.stopProgressTimer()
        }
    }

    private func configurePlaybackSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
        try? session.setActive(true)
    }

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateProgressFromPlayer()
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func updateProgressFromPlayer() {
        guard let player else { return }
        currentTime = player.currentTime
        duration = max(duration, player.duration)
        progress = duration > 0 ? player.currentTime / duration : 0
    }
}
