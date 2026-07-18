import Foundation

enum SnoreIngestRouter {
    nonisolated(unsafe) static weak var active: SnoreDetectionService?

    nonisolated static func ingest(samples: [Float], sourceSampleRate: Double) {
        active?.ingest(samples: samples, sourceSampleRate: sourceSampleRate)
    }
}

/// Pipeline ronflement : chunks 1 s @ 22 050 Hz → Core ML / heuristique → événements.
@MainActor
final class SnoreDetectionService: ObservableObject {
    nonisolated private let worker = SnoreInferenceWorker()

    @Published private(set) var isRunning = false
    @Published private(set) var lastConfidence: Double = 0
    @Published private(set) var detectionsThisSession = 0
    @Published private(set) var usesCoreMLModel = false

    var onSnoreDetected: ((Date, TimeInterval, Double) -> Void)?

    private var lastSnoreCallbackAt: Date?
    /// Limite les allers-retours MainActor pendant une série de ronflements (chunks 1 s).
    private let minCallbackInterval: TimeInterval = 22

    func start() {
        SnoreIngestRouter.active = self
        worker.reset()
        detectionsThisSession = 0
        lastSnoreCallbackAt = nil
        usesCoreMLModel = worker.isModelLoaded
        isRunning = true
    }

    func stop() {
        isRunning = false
        if SnoreIngestRouter.active === self {
            SnoreIngestRouter.active = nil
        }
        worker.reset()
    }

    /// Appelé depuis le tap audio (hors MainActor) — échantillons mono déjà extraits.
    nonisolated func ingest(samples: [Float], sourceSampleRate: Double) {
        worker.ingest(samples: samples, sourceSampleRate: sourceSampleRate) { result, detectedAt in
            Task { @MainActor in
                SnoreIngestRouter.active?.applyIngest(result: result, detectedAt: detectedAt)
            }
        }
    }

    private func applyIngest(result: SnoreClassificationResult, detectedAt: Date) {
        lastConfidence = result.confidence
        guard result.isSnore, result.confidence >= SnoreClassifierEngine.confidenceThreshold else { return }
        if let last = lastSnoreCallbackAt,
           detectedAt.timeIntervalSince(last) < minCallbackInterval {
            return
        }
        lastSnoreCallbackAt = detectedAt
        detectionsThisSession += 1
        onSnoreDetected?(detectedAt, 1.0, result.confidence)
    }
}
