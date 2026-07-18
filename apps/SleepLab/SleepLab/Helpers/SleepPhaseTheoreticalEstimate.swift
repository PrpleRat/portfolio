import Foundation

/// Architecture de sommeil **indicative** pour les nuits sans capteur (saisie manuelle).
struct TheoreticalSleepArchitecture: Equatable {
    let deepMinutes: Int
    let lightMinutes: Int
    let remMinutes: Int

    var asleepMinutes: Int { deepMinutes + lightMinutes + remMinutes }

    var deepPercent: Double {
        guard asleepMinutes > 0 else { return 0 }
        return Double(deepMinutes) / Double(asleepMinutes) * 100
    }

    var remPercent: Double {
        guard asleepMinutes > 0 else { return 0 }
        return Double(remMinutes) / Double(asleepMinutes) * 100
    }

    var lightPercent: Double {
        guard asleepMinutes > 0 else { return 0 }
        return Double(lightMinutes) / Double(asleepMinutes) * 100
    }
}

struct TheoreticalPhaseSegment: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let type: SleepPhaseType
}

enum SleepPhaseTheoreticalEstimate {
    private static let chunkSeconds: TimeInterval = 5 * 60
    private static let minimumDuration: TimeInterval = 30 * 60

    /// Nuit manuelle sans phases mesurées par le capteur.
    static func shouldShow(for session: SleepSession) -> Bool {
        guard session.isManuallyEntered, session.endTime != nil else { return false }
        return lacksMeasuredPhases(session)
    }

    static func estimate(for session: SleepSession) -> TheoreticalSleepArchitecture? {
        guard shouldShow(for: session) else { return nil }
        return estimate(duration: session.totalDuration)
    }

    static func segments(for session: SleepSession) -> [TheoreticalPhaseSegment]? {
        guard shouldShow(for: session), session.totalDuration >= minimumDuration else { return nil }
        return buildSegments(duration: session.totalDuration, startTime: session.startTime)
    }

    static func estimate(duration: TimeInterval) -> TheoreticalSleepArchitecture? {
        guard duration >= minimumDuration else { return nil }
        var deepSec = 0.0
        var lightSec = 0.0
        var remSec = 0.0
        var elapsed: TimeInterval = 0
        while elapsed < duration {
            let chunk = min(chunkSeconds, duration - elapsed)
            let phase = SleepArchitectureEstimator.typicalPhase(elapsedMinutes: elapsed / 60)
            switch phase {
            case .deep: deepSec += chunk
            case .light: lightSec += chunk
            case .rem: remSec += chunk
            case .awake: lightSec += chunk
            }
            elapsed += chunk
        }
        applyPhysiologicalCaps(
            deepSec: &deepSec,
            lightSec: &lightSec,
            remSec: &remSec,
            asleep: deepSec + lightSec + remSec
        )
        return TheoreticalSleepArchitecture(
            deepMinutes: Int(deepSec / 60),
            lightMinutes: Int(lightSec / 60),
            remMinutes: Int(remSec / 60)
        )
    }

    static func lacksMeasuredPhases(_ session: SleepSession) -> Bool {
        session.recalculatePhaseMinutes()
        let phaseMinutes = session.deepSleepMinutes + session.lightSleepMinutes + session.remSleepMinutes
        let expectedMinutes = Int(session.totalDuration / 60)
        return phaseMinutes < max(15, expectedMinutes / 4)
    }

    private static func buildSegments(duration: TimeInterval, startTime: Date) -> [TheoreticalPhaseSegment] {
        var result: [TheoreticalPhaseSegment] = []
        var elapsed: TimeInterval = 0
        var segmentStart = startTime
        while elapsed < duration {
            let chunk = min(chunkSeconds, duration - elapsed)
            let phase = SleepArchitectureEstimator.typicalPhase(elapsedMinutes: elapsed / 60)
            let end = segmentStart.addingTimeInterval(chunk)
            result.append(TheoreticalPhaseSegment(start: segmentStart, end: end, type: phase))
            segmentStart = end
            elapsed += chunk
        }
        return result
    }

    /// Même logique que `SleepPhaseRebalancer`, appliquée aux totaux indicatifs.
    private static func applyPhysiologicalCaps(
        deepSec: inout Double,
        lightSec: inout Double,
        remSec: inout Double,
        asleep: Double
    ) {
        guard asleep > 0 else { return }
        let maxDeep = asleep * 0.30
        if deepSec > maxDeep {
            let excess = deepSec - maxDeep
            deepSec = maxDeep
            lightSec += excess
        }
        let minRem = asleep * 0.12
        if remSec < minRem {
            let need = minRem - remSec
            let take = min(need, lightSec * 0.4)
            remSec += take
            lightSec -= take
        }
    }
}
