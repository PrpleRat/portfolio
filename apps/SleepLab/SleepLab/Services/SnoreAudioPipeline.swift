import AVFoundation
import Foundation

extension SnoreAudioPipeline {
    /// Extrait les échantillons mono sur le thread du tap (avant tout dispatch async).
    static func monoFloatSamples(from buffer: AVAudioPCMBuffer) -> [Float]? {
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return nil }

        if let channel = buffer.floatChannelData?[0] {
            return Array(UnsafeBufferPointer(start: channel, count: frames))
        }

        if let channel = buffer.int16ChannelData?[0] {
            return (0..<frames).map { Float(channel[$0]) / 32_768.0 }
        }

        return nil
    }
}

/// Accumule le micro, resample à 22 050 Hz, émet des chunks d’1 seconde.
final class SnoreAudioPipeline: @unchecked Sendable {
    static let targetSampleRate = 22_050
    static let chunkSampleCount = 22_050

    private var pendingSamples: [Float] = []
    private let lock = NSLock()

    /// Appelé depuis le tap audio (thread temps réel) — échantillons mono déjà extraits.
    func ingest(samples: [Float], sourceSampleRate: Double, onChunk: @escaping @Sendable ([Float], Date) -> Void) {
        let resampled = Self.resample(samples, from: sourceSampleRate, to: Double(Self.targetSampleRate))

        lock.lock()
        pendingSamples.append(contentsOf: resampled)
        while pendingSamples.count >= Self.chunkSampleCount {
            let chunk = Array(pendingSamples.prefix(Self.chunkSampleCount))
            pendingSamples.removeFirst(Self.chunkSampleCount)
            lock.unlock()
            onChunk(chunk, Date())
            lock.lock()
        }
        lock.unlock()
    }

    func reset() {
        lock.lock()
        pendingSamples.removeAll(keepingCapacity: false)
        lock.unlock()
    }

    /// Resampling linéaire (suffisant pour classification 1 s).
    static func resample(_ samples: [Float], from sourceRate: Double, to targetRate: Double) -> [Float] {
        guard sourceRate > 0, targetRate > 0, !samples.isEmpty else { return [] }
        if abs(sourceRate - targetRate) < 1 { return samples }

        let ratio = targetRate / sourceRate
        let outputCount = max(1, Int(Double(samples.count) * ratio))
        var output = [Float]()
        output.reserveCapacity(outputCount)

        for i in 0..<outputCount {
            let srcIndex = Double(i) / ratio
            let lower = Int(srcIndex)
            let upper = min(lower + 1, samples.count - 1)
            let frac = Float(srcIndex - Double(lower))
            let value = samples[lower] * (1 - frac) + samples[upper] * frac
            output.append(value)
        }
        return output
    }
}
