import CoreMotion
import Foundation

/// Mesure éveillé 2 min à 10 Hz — CMMotionManager dédié, arrêté à la fin (pas de fuite).
@MainActor
@Observable
final class AwakeMotionSampler {
    private let motionManager = CMMotionManager()
    private var samples: [CMAcceleration] = []
    private var measureTask: Task<Void, Never>?
    private let sampleInterval = 0.1
    let duration: TimeInterval = 120

    private(set) var isRunning = false
    private(set) var sampleCount = 0

    var isAccelerometerAvailable: Bool {
        motionManager.isAccelerometerAvailable
    }

    func start(
        onProgress: @escaping @MainActor (_ remaining: TimeInterval) -> Void,
        onComplete: @escaping @MainActor (_ baseline: Double?) -> Void
    ) {
        stop()
        guard motionManager.isAccelerometerAvailable else {
            onComplete(nil)
            return
        }

        samples.removeAll()
        sampleCount = 0
        isRunning = true
        onProgress(duration)

        motionManager.accelerometerUpdateInterval = sampleInterval
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            Task { @MainActor in
                self.samples.append(data.acceleration)
                self.sampleCount = self.samples.count
            }
        }

        measureTask = Task { @MainActor in
            let start = Date()
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(start)
                let remaining = max(0, duration - elapsed)
                onProgress(remaining)
                if elapsed >= duration { break }
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            guard !Task.isCancelled else { return }
            let captured = samples
            let baseline = Self.baselineVariance(from: captured)
            stop()
            onComplete(baseline)
        }
    }

    func stop() {
        measureTask?.cancel()
        measureTask = nil
        motionManager.stopAccelerometerUpdates()
        isRunning = false
    }

    /// Fenêtres de 30 s (300 échantillons @ 10 Hz), variance moyenne.
    static func baselineVariance(from accelerations: [CMAcceleration]) -> Double? {
        let windowSize = 300
        guard accelerations.count >= 30 else { return nil }

        if accelerations.count < windowSize {
            return MotionAnalyzer.movementScore(from: accelerations)
        }

        var windowScores: [Double] = []
        var index = 0
        while index + windowSize <= accelerations.count {
            let slice = Array(accelerations[index..<(index + windowSize)])
            windowScores.append(MotionAnalyzer.movementScore(from: slice))
            index += windowSize
        }
        guard !windowScores.isEmpty else { return nil }
        return windowScores.reduce(0, +) / Double(windowScores.count)
    }
}
