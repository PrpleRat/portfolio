import CoreMotion
import Foundation

/// Analyse l'accéléromètre (10 Hz) + cycles physiologiques pour estimer les phases.
@MainActor
final class MotionAnalyzer: ObservableObject {
    private let motionManager = CMMotionManager()
    private var accelerationBuffer: [CMAcceleration] = []
    private let bufferMaxSamples = 300
    private let sampleInterval = 0.1

    private var calibrationScores: [Double] = []
    private var baselineMovement: Double = 0.06
    private var isCalibrated = false
    private var sessionStart: Date?
    private let phaseSmoother = PhaseSmoother()

    @Published var currentPhase: SleepPhaseType = .light
    @Published var isRunning = false
    @Published private(set) var lastMovementScore: Double = 0
    @Published private(set) var isCalibratedForDisplay = false

    func beginSession(at start: Date) {
        sessionStart = start
        phaseSmoother.reset()
    }

    func startTracking() {
        guard motionManager.isAccelerometerAvailable else { return }
        accelerationBuffer.removeAll()
        calibrationScores.removeAll()
        let manager = SleepCalibrationManager.shared
        if manager.isCalibrated {
            baselineMovement = manager.effectiveMovementThreshold
            isCalibrated = true
            isCalibratedForDisplay = true
        } else {
            baselineMovement = 0.06
            isCalibrated = false
            isCalibratedForDisplay = false
        }
        phaseSmoother.reset()
        currentPhase = .light

        motionManager.accelerometerUpdateInterval = sampleInterval
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.appendSample(data.acceleration)
        }
        isRunning = true
    }

    func stopTracking() {
        motionManager.stopAccelerometerUpdates()
        isRunning = false
        sessionStart = nil
    }

    private func appendSample(_ acc: CMAcceleration) {
        accelerationBuffer.append(acc)
        if accelerationBuffer.count > bufferMaxSamples {
            accelerationBuffer.removeFirst(accelerationBuffer.count - bufferMaxSamples)
        }
        lastMovementScore = movementScore(from: accelerationBuffer)
        updateCalibration(with: lastMovementScore)
        currentPhase = analyzeCurrentPhase()
    }

    private func updateCalibration(with score: Double) {
        guard !isCalibrated else { return }
        calibrationScores.append(score)
        guard calibrationScores.count >= 90 else { return }
        let sorted = calibrationScores.sorted()
        let median = sorted[sorted.count / 2]
        baselineMovement = max(0.02, median * 1.15)
        isCalibrated = true
        isCalibratedForDisplay = true
    }

    func analyzeCurrentPhase() -> SleepPhaseType {
        guard accelerationBuffer.count >= 30 else { return .light }

        let score = movementScore(from: accelerationBuffer)
        let irregularity = irregularityScore(from: accelerationBuffer)
        let motion = phaseFromMovementScore(score, irregularity: irregularity)

        let elapsedMin: Double
        if let start = sessionStart {
            elapsedMin = Date().timeIntervalSince(start) / 60
        } else {
            elapsedMin = 0
        }

        let architectural = SleepArchitectureEstimator.typicalPhase(elapsedMinutes: elapsedMin)
        let blended = SleepArchitectureEstimator.blend(
            motion: motion,
            architectural: architectural,
            elapsedMinutes: elapsedMin,
            movementScore: score,
            baseline: baselineMovement
        )

        return phaseSmoother.smooth(blended)
    }

    func movementScore(from buffer: [CMAcceleration]) -> Double {
        Self.movementScore(from: buffer)
    }

    static func movementScore(from buffer: [CMAcceleration]) -> Double {
        guard !buffer.isEmpty else { return 0 }
        let magnitudes = buffer.map { acc in
            sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)
        }
        let mean = magnitudes.reduce(0, +) / Double(magnitudes.count)
        let variance = magnitudes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(magnitudes.count)
        return sqrt(variance)
    }

    private func effectiveBaseline() -> Double {
        let manager = SleepCalibrationManager.shared
        if manager.isCalibrated {
            return max(0.02, manager.effectiveMovementThreshold)
        }
        return max(baselineMovement, 0.02)
    }

    private func phaseFromMovementScore(_ score: Double, irregularity: Double) -> SleepPhaseType {
        let baseline = effectiveBaseline()
        let ratio = score / baseline

        if ratio > 2.5 || score > baseline * 3.3 { return .awake }
        if ratio > 1.45 || score > baseline * 2.0 { return .light }

        if irregularity > 0.012, ratio > 0.5, ratio < 1.45 { return .rem }

        if ratio < 0.5, score < baseline * 0.37, irregularity < 0.008 { return .deep }

        return .light
    }

    private func irregularityScore(from buffer: [CMAcceleration]) -> Double {
        guard buffer.count > 10 else { return 0 }
        let deltas = zip(buffer.dropFirst(), buffer).map { a, b in
            abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)
        }
        return deltas.reduce(0, +) / Double(deltas.count)
    }

    func enrichedPhase(
        motionPhase: SleepPhaseType,
        heartRate: Double?,
        hrv: Double?
    ) -> SleepPhaseType {
        if motionPhase == .awake { return .awake }
        if let heartRate, heartRate > 85, motionPhase == .deep { return .light }
        if let heartRate, heartRate > 72, motionPhase == .deep { return .rem }
        return motionPhase
    }

    static func isLikelyOverestimatedDeep(session: SleepSession) -> Bool {
        let total = session.deepSleepMinutes + session.lightSleepMinutes + session.remSleepMinutes
        guard total > 30 else { return false }
        let deepRatio = Double(session.deepSleepMinutes) / Double(total)
        return deepRatio > 0.55
    }
}
