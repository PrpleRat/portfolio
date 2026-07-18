import Foundation
import SwiftData

/// Reconstruit l’architecture du sommeil quand les phases enregistrées sont absentes ou incohérentes.
enum SleepPhaseBackfill {
  private static let chunkSeconds: TimeInterval = 5 * 60

  static func backfillIfNeeded(session: SleepSession, modelContext: ModelContext? = nil) {
    guard !session.isManuallyEntered else { return }
    guard session.endTime != nil, session.totalDuration >= 30 * 60 else { return }

    session.recalculatePhaseMinutes()
    let phaseMinutes = session.deepSleepMinutes + session.lightSleepMinutes + session.remSleepMinutes
    let expectedMinutes = Int(session.totalDuration / 60)
    guard phaseMinutes < max(15, expectedMinutes / 4) else { return }

    for phase in session.phases {
      modelContext?.delete(phase)
    }
    session.phases.removeAll()

    var elapsed: TimeInterval = 0
    var segmentStart = session.startTime
    while elapsed < session.totalDuration {
      let remaining = session.totalDuration - elapsed
      let duration = min(chunkSeconds, remaining)
      let elapsedMinutes = elapsed / 60
      let phaseType = SleepArchitectureEstimator.typicalPhase(elapsedMinutes: elapsedMinutes)
      let segmentEnd = segmentStart.addingTimeInterval(duration)
      let segment = SleepPhase(
        startTime: segmentStart,
        endTime: segmentEnd,
        phaseType: phaseType,
        movementScore: 0.08
      )
      if let modelContext {
        modelContext.insert(segment)
      }
      session.phases.append(segment)
      segmentStart = segmentEnd
      elapsed += duration
    }

    SleepPhaseRebalancer.rebalance(session: session)
    session.recalculatePhaseMinutes()
  }

  /// Corrige les nuits déjà en base (ex. phases vides malgré une durée > 6 h).
  @MainActor
  static func repairStoredSessions(
    sessions: [SleepSession],
    profile: UserProfile?,
    in context: ModelContext
  ) {
    var changed = false
    for session in sessions where session.endTime != nil && !session.isManuallyEntered {
      let before = session.deepSleepMinutes + session.lightSleepMinutes + session.remSleepMinutes
      backfillIfNeeded(session: session, modelContext: context)
      let after = session.deepSleepMinutes + session.lightSleepMinutes + session.remSleepMinutes
      guard after != before else { continue }
      SleepScoreCalculator.apply(to: session, profile: profile)
      changed = true
    }
    if changed {
      try? context.save()
    }
  }
}
