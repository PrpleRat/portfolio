import Foundation

/// Inférence ronflement hors MainActor (tap audio + queue dédiée).
final class SnoreInferenceWorker: @unchecked Sendable {
    private let classifier = SnoreClassifierEngine()
    private let pipeline = SnoreAudioPipeline()
    private let inferenceQueue = DispatchQueue(label: "com.prple.sleeplab.snore.inference", qos: .userInitiated)

    var isModelLoaded: Bool { classifier.isModelLoaded }

    func reset() {
        pipeline.reset()
    }

    func ingest(
        samples: [Float],
        sourceSampleRate: Double,
        onResult: @escaping @Sendable (SnoreClassificationResult, Date) -> Void
    ) {
        guard sourceSampleRate > 0, !samples.isEmpty else { return }
        pipeline.ingest(samples: samples, sourceSampleRate: sourceSampleRate) { chunk, detectedAt in
            self.inferenceQueue.async {
                guard let result = self.classifier.classify(waveform: chunk) else { return }
                onResult(result, detectedAt)
            }
        }
    }
}
