import AVFoundation
import Combine
import Foundation

@MainActor
final class HandpanAudioEngine: ObservableObject {
    static let shared = HandpanAudioEngine()

    static let soundNames: [String] = [
        "pos1_C_v0", "pos1_C_v1", "pos1_C_v2",
        "pos2_F_v0", "pos2_F_v1", "pos2_F_v2",
        "pos3_G_v0", "pos3_G_v1", "pos3_G_v2",
        "pos4_sG_v0", "pos4_sG_v1", "pos4_sG_v2",
        "pos4_A_v0", "pos4_A_v1", "pos4_A_v2",
        "pos5_sA_v0", "pos5_sA_v1", "pos5_sA_v2",
        "pos5_B_v0", "pos5_B_v1", "pos5_B_v2",
        "pos6_C2_v0", "pos6_C2_v1", "pos6_C2_v2",
        "pos7_D2_v0", "pos7_D2_v1", "pos7_D2_v2",
        "pos8_sD2_v0", "pos8_sD2_v1", "pos8_sD2_v2",
        "pos8_E2_v0", "pos8_E2_v1", "pos8_E2_v2",
        "pos9_F2_v0", "pos9_F2_v1", "pos9_F2_v2",
    ]

    static let fallbackDurationMs = 3800

    @Published private(set) var status: AudioStatus = .loading

    private var soundURLs: [String: URL] = [:]
    private var durationsMs: [String: Int] = [:]
    private var activePlayers: [AVAudioPlayer] = []
    private let maxPolyphony = 32

    private init() {
        Task { await bootstrap() }
    }

    func waitUntilReady() async -> AudioStatus {
        for _ in 0..<80 {
            if status == .ready || status == .unavailable {
                return status
            }
            try? await Task.sleep(for: .milliseconds(150))
        }
        return status
    }

    func estimatedDurationMs(for sound: String, rate: Double) -> Int {
        let base = durationsMs[sound] ?? Self.fallbackDurationMs
        let adjusted = Int((Double(base) / rate).rounded())
        return min(max(adjusted, 80), 20_000)
    }

    func play(sound: String, volume: Double, rate: Double) {
        guard status == .ready, let url = soundURLs[sound] else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = Float(volume.clamped(to: 0.05...1.0))
            player.enableRate = true
            player.rate = Float(rate.clamped(to: 0.5...2.0))
            player.prepareToPlay()
            player.play()
            activePlayers.append(player)
            trimFinishedPlayers()
        } catch {
            // Fichier manquant ou corrompu — ignorer silencieusement
        }
    }

    private func bootstrap() async {
        configureAudioSession()

        var loaded = 0
        for name in Self.soundNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Sounds")
                ?? Bundle.main.url(forResource: name, withExtension: "wav") {
                soundURLs[name] = url
                durationsMs[name] = Self.readWavDurationMs(at: url)
                loaded += 1
            }
        }

        status = loaded > 0 ? .ready : .unavailable
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func trimFinishedPlayers() {
        activePlayers.removeAll { !$0.isPlaying }
        if activePlayers.count > maxPolyphony {
            activePlayers.removeFirst(activePlayers.count - maxPolyphony)
        }
    }

    private static func readWavDurationMs(at url: URL) -> Int {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return fallbackDurationMs
        }
        defer { try? handle.close() }

        guard let header = try? handle.read(upToCount: 44), header.count == 44 else {
            return fallbackDurationMs
        }

        let channels = Int(readLe16(header, offset: 22))
        let sampleRate = Int(readLe32(header, offset: 24))
        let bitsPerSample = Int(readLe16(header, offset: 34))

        guard channels > 0, sampleRate > 0, bitsPerSample > 0 else {
            return fallbackDurationMs
        }

        let bytesPerSecond = sampleRate * channels * (bitsPerSample / 8)
        guard bytesPerSecond > 0 else { return fallbackDurationMs }

        let dataSize = Int(readLe32(header, offset: 40))
        let ms = Int((Double(dataSize) / Double(bytesPerSecond)) * 1000.0)
        return max(ms, 80)
    }

    private static func readLe16(_ bytes: Data, offset: Int) -> UInt16 {
        UInt16(bytes[offset]) | (UInt16(bytes[offset + 1]) << 8)
    }

    private static func readLe32(_ bytes: Data, offset: Int) -> UInt32 {
        UInt32(bytes[offset])
            | (UInt32(bytes[offset + 1]) << 8)
            | (UInt32(bytes[offset + 2]) << 16)
            | (UInt32(bytes[offset + 3]) << 24)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
