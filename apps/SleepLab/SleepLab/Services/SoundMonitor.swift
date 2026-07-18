import AVFoundation
import Foundation
import UIKit

/// Surveillance audio nocturne — détection heuristique améliorée + clips optionnels.
final class SoundMonitor: NSObject, ObservableObject {
    private let audioEngine = AVAudioEngine()
    private var clipRecorder: AVAudioRecorder?

    @Published var currentDBLevel: Double = 0
    @Published var isMonitoring = false
    @Published var lastDetectedType: SoundType?
    @Published var microphoneDenied = false
    @Published var lastStartError: String?

    private var threshold: Double = 52
    private var tapSampleRate: Double = 48_000
    private var lastClipStartedAt: Date?
    private var lastEventAtByType: [String: Date] = [:]
    private var recordClipsEnabled = false

    private var noiseCalibrationDB: [Double] = []
    private var adaptiveNoiseFloor: Double = 36
    private var isNoiseCalibrated = false

    var onSoundEvent: ((SoundType, Double, String?, TimeInterval, Date) -> Void)?
    /// Échantillons mono extraits sur le thread audio (Sendable).
    var onPCMSamples: (@Sendable ([Float], Double) -> Void)?

    func startMonitoring(threshold: Double = 52.0, recordClips: Bool = false) async -> Bool {
        self.threshold = threshold
        recordClipsEnabled = recordClips
        lastStartError = nil
        microphoneDenied = false
        lastClipStartedAt = nil
        lastEventAtByType = [:]
        noiseCalibrationDB = []
        isNoiseCalibrated = false
        adaptiveNoiseFloor = 36

        guard !isMonitoring else { return true }

        let granted = await requestMicrophoneAccess()
        guard granted else {
            microphoneDenied = true
            lastStartError = "Autorise le micro dans Réglages → \(AppBrand.displayName) pour le suivi audio."
            return false
        }

        configureAudioSession()

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            lastStartError = "Format audio micro indisponible sur cet appareil."
            return false
        }
        tapSampleRate = format.sampleRate
        input.removeTap(onBus: 0)

        let thresholdBase = threshold
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let rms = AudioHelpers.rmsLevel(buffer: buffer)
            let db = AudioHelpers.rmsToDecibels(rms) + 90
            let rate = self.tapSampleRate

            let mono = SnoreAudioPipeline.monoFloatSamples(from: buffer)
            if let mono, !mono.isEmpty {
                self.onPCMSamples?(mono, rate)
            }

            let effectiveThreshold = max(thresholdBase, self.adaptiveNoiseFloor + 8)

            DispatchQueue.main.async {
                self.calibrateNoiseFloor(db: db)
                self.applyAudioSample(db: db, effectiveThreshold: effectiveThreshold)
            }
        }

        do {
            try audioEngine.start()
            isMonitoring = true
            return true
        } catch {
            input.removeTap(onBus: 0)
            lastStartError = "Micro : \(error.localizedDescription)"
            return false
        }
    }

    func stopMonitoring() {
        guard isMonitoring || audioEngine.isRunning else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        if let rec = clipRecorder, rec.isRecording {
            rec.stop()
        }
        clipRecorder = nil
        isMonitoring = false
    }

    func checkBatteryAndWarn() -> Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        if level >= 0 && level < 0.2 { return false }
        return true
    }

    private func calibrateNoiseFloor(db: Double) {
        guard !isNoiseCalibrated else { return }
        noiseCalibrationDB.append(db)
        guard noiseCalibrationDB.count >= 80 else { return }
        let sorted = noiseCalibrationDB.sorted()
        let median = sorted[sorted.count / 2]
        adaptiveNoiseFloor = median
        isNoiseCalibrated = true
    }

    private func requestMicrophoneAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func applyAudioSample(db: Double, effectiveThreshold: Double) {
        currentDBLevel = db
        guard db >= effectiveThreshold + 2 else { return }

        let type = SoundType.unknown
        let now = Date()
        let minInterval: TimeInterval = 25

        if let last = lastEventAtByType[type.rawValue],
           now.timeIntervalSince(last) < minInterval {
            return
        }
        lastEventAtByType[type.rawValue] = now
        lastDetectedType = type

        var clipName: String?
        var clipDuration: TimeInterval = 0
        let canRecord = recordClipsEnabled
            && (lastClipStartedAt == nil || now.timeIntervalSince(lastClipStartedAt!) >= minClipInterval)
        if canRecord, db >= effectiveThreshold + 6 {
            let duration: TimeInterval = db >= effectiveThreshold + 12 ? 12 : 8
            if let name = recordClip(duration: duration) {
                clipName = name
                clipDuration = duration
                lastClipStartedAt = now
            }
        }

        onSoundEvent?(type, db, clipName, clipDuration, now)
    }

    func injectTestEvent(type: SoundType = .unknown, decibels: Double = 55, at detectedAt: Date = Date()) {
        onSoundEvent?(type, decibels, nil, 0, detectedAt)
    }

    private let minClipInterval: TimeInterval = 22

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.mixWithOthers, .allowBluetoothHFP, .defaultToSpeaker]
        )
        try? session.setActive(true)
    }

    func classifySound(buffer: AVAudioPCMBuffer, sampleRate: Double = 48_000) -> SoundType? {
        NightAudioClassifier.classify(buffer: buffer, sampleRate: sampleRate)?.type
    }

    @discardableResult
    func recordClip(duration: TimeInterval = 12.0) -> String? {
        if let existing = clipRecorder, existing.isRecording {
            existing.stop()
        }
        clipRecorder = nil

        let ts = Int(Date().timeIntervalSince1970)
        let name = "clip_\(ts)_\(UUID().uuidString.prefix(8)).m4a"
        let url = AudioHelpers.clipURL(fileName: name)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 96_000,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            guard recorder.prepareToRecord() else { return nil }
            recorder.record(forDuration: duration)
            clipRecorder = recorder
            return name
        } catch {
            return nil
        }
    }
}
