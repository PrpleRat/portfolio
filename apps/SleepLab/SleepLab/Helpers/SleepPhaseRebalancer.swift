import Foundation

/// Corrige les hypnogrammes aberrants (ex. > 40 % profond avec iPhone immobile).
enum SleepPhaseRebalancer {
    private static let maxDeepFraction = 0.30
    private static let minRemFraction = 0.12

    static func rebalance(session: SleepSession) {
        guard session.totalDuration > 600, !session.phases.isEmpty else { return }

        var deepSec = 0.0
        var remSec = 0.0
        recalc(phases: session.phases, deepSec: &deepSec, remSec: &remSec)
        let asleep = asleepDuration(phases: session.phases)
        guard asleep > 0 else { return }

        if deepSec / asleep > maxDeepFraction {
            convertExcessDeepToLight(phases: session.phases, targetDeepSeconds: asleep * maxDeepFraction)
        }

        recalc(phases: session.phases, deepSec: &deepSec, remSec: &remSec)
        let asleepAfter = asleepDuration(phases: session.phases)
        guard asleepAfter > 0 else { return }

        if remSec / asleepAfter < minRemFraction {
            promoteSomeLightToRem(
                phases: session.phases,
                targetRemSeconds: asleepAfter * minRemFraction,
                currentRem: remSec
            )
        }
    }

    private static func asleepDuration(phases: [SleepPhase]) -> Double {
        phases.filter { $0.phaseType != .awake }.reduce(0) { $0 + $1.duration }
    }

    private static func convertExcessDeepToLight(phases: [SleepPhase], targetDeepSeconds: Double) {
        let deepPhases = phases.filter { $0.phaseType == .deep }.sorted { $0.duration > $1.duration }
        var deepTotal = deepPhases.reduce(0.0) { $0 + $1.duration }
        for phase in deepPhases.reversed() where deepTotal > targetDeepSeconds {
            deepTotal -= phase.duration
            phase.phaseType = .light
        }
    }

    private static func promoteSomeLightToRem(
        phases: [SleepPhase],
        targetRemSeconds: Double,
        currentRem: Double
    ) {
        var need = targetRemSeconds - currentRem
        let candidates = phases.filter { $0.phaseType == .light && $0.duration >= 300 }
        for phase in candidates where need > 0 {
            phase.phaseType = .rem
            need -= phase.duration
        }
    }

    private static func recalc(
        phases: [SleepPhase],
        deepSec: inout Double,
        remSec: inout Double
    ) {
        deepSec = 0
        remSec = 0
        for phase in phases where phase.phaseType != .awake {
            switch phase.phaseType {
            case .deep: deepSec += phase.duration
            case .rem: remSec += phase.duration
            case .light, .awake: break
            }
        }
    }
}
