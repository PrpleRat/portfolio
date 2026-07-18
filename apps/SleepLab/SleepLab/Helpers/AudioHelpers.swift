import AVFoundation
import Accelerate
import Foundation

enum AudioHelpers {

    /// Convertit l'amplitude RMS en dB approximatif
    static func rmsToDecibels(_ rms: Float) -> Double {
        guard rms > 0 else { return 0 }
        return Double(20 * log10(rms))
    }

    /// RMS d'un buffer mono
    static func rmsLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData?[0] else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }
        var rms: Float = 0
        vDSP_rmsqv(data, 1, &rms, vDSP_Length(count))
        return rms
    }

    /// Score ronflement (délègue à l’analyse spectrale partagée).
    static func snoringScore(from buffer: AVAudioPCMBuffer, sampleRate: Double) -> Double {
        AudioSpectralFeatures.analyze(buffer: buffer, sampleRate: sampleRate)?.snoreScore ?? 0
    }

    static var clipsDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SleepClips", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func clipURL(fileName: String) -> URL {
        clipsDirectory.appendingPathComponent(fileName)
    }
}
