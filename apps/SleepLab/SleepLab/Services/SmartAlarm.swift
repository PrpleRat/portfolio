import AVFoundation
import Foundation

/// Réveil intelligent — fenêtre + phase légère + son bundlé.
@MainActor
final class SmartAlarm: ObservableObject {
    var targetWakeTime: Date
    var windowMinutes: Int
    var progressiveVolume: Bool

    private var audioPlayer: AVAudioPlayer?
    private var volumeTimer: Timer?
    private var volumeStep = 0
    private var triggered = false
    private var fallbackTimer: Timer?

    @Published var isRinging = false

    init(config: AlarmConfig, sessionStart: Date = Date(), wakeTime: Date? = nil) {
        targetWakeTime = wakeTime ?? config.nextWakeTime(relativeTo: sessionStart)
        windowMinutes = min(30, max(5, config.windowMinutes))
        progressiveVolume = config.progressiveVolume
        AlarmSoundLibrary.shared.select(config.sound)
    }

    var windowStart: Date {
        Calendar.current.date(byAdding: .minute, value: -windowMinutes, to: targetWakeTime) ?? targetWakeTime
    }

    func startMonitoring() {
        triggered = false
        fallbackTimer?.invalidate()
        let sound = AlarmSoundLibrary.shared.selectedSound
        AlarmNotificationScheduler.scheduleFallback(at: targetWakeTime, sound: sound)

        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.checkFallback()
            }
        }
    }

    func stopMonitoring() {
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        AlarmNotificationScheduler.cancelFallback()
        stopAlarm()
    }

    func checkAndTriggerIfNeeded(currentPhase: SleepPhaseType) -> Bool {
        guard !triggered else { return false }
        let now = Date()
        guard now >= windowStart, now <= targetWakeTime else {
            if now > targetWakeTime { return forceTrigger() }
            return false
        }
        if currentPhase == .light || currentPhase == .rem {
            triggerAlarm()
            return true
        }
        return false
    }

    private func checkFallback() {
        guard !triggered else { return }
        if Date() >= targetWakeTime {
            _ = forceTrigger()
        }
    }

    @discardableResult
    func forceTrigger() -> Bool {
        triggerAlarm()
        return true
    }

    func triggerAlarm() {
        guard !triggered else { return }
        triggered = true
        isRinging = true
        playAlarmSound()
    }

    func stopAlarm() {
        volumeTimer?.invalidate()
        audioPlayer?.stop()
        isRinging = false
        triggered = false
        AlarmSoundLibrary.shared.stopPreview()
    }

    private func playAlarmSound() {
        let sound = AlarmSoundLibrary.shared.selectedSound
        AlarmSoundLibrary.shared.configureAudioSession()

        if let url = sound.bundleURL {
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
        } else {
            AudioServicesPlaySystemSound(1005)
            return
        }

        guard let player = audioPlayer else { return }
        player.numberOfLoops = -1
        player.volume = progressiveVolume ? 0.05 : 1
        player.play()

        if progressiveVolume {
            let steps = 60
            volumeStep = 0
            volumeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.volumeStep += 1
                    self.audioPlayer?.volume = min(1, Float(self.volumeStep) / Float(steps))
                    if self.volumeStep >= steps {
                        self.volumeTimer?.invalidate()
                        self.volumeTimer = nil
                    }
                }
            }
        }
    }
}

import AudioToolbox
