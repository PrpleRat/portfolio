import Foundation
import SwiftData

/// Finalise les sessions laissées ouvertes après kill iOS / crash (invisibles dans l’historique).
enum InterruptedSleepRecovery {
    struct Result: Identifiable {
        let id: UUID
        let session: SleepSession
        let estimatedEnd: Date
    }

    /// Sessions sans `endTime`, assez anciennes pour ne pas être un démarrage en cours.
    @MainActor
    static func recoverSessions(
        in context: ModelContext,
        profile: UserProfile?,
        skipIfTracking: Bool
    ) throws -> [Result] {
        guard !skipIfTracking else { return [] }

        let now = Date()
        let minAge: TimeInterval = 3 * 60
        let maxAge: TimeInterval = 8 * 24 * 3600

        let descriptor = FetchDescriptor<SleepSession>(
            predicate: #Predicate { $0.endTime == nil },
            sortBy: [SortDescriptor(\SleepSession.startTime, order: .reverse)]
        )
        let open = try context.fetch(descriptor)
        var recovered: [Result] = []

        for session in open {
            let age = now.timeIntervalSince(session.startTime)
            guard age >= minAge, age <= maxAge else { continue }

            if !hasRecoverableData(session) {
                if age > 30 * 60 {
                    context.delete(session)
                }
                continue
            }

            let end = estimatedEndTime(for: session, now: now)
            closeOpenPhases(session: session, end: end)
            session.finalize(at: end)
            session.actualWakeTime = end
            SleepPhaseRebalancer.rebalance(session: session)
            SleepPhaseBackfill.backfillIfNeeded(session: session, modelContext: context)
            session.recalculatePhaseMinutes()
            session.recalculateSnoreMinutes()
            SleepScoreCalculator.apply(to: session, profile: profile)

            recovered.append(Result(id: session.id, session: session, estimatedEnd: end))
        }

        if !recovered.isEmpty {
            try context.save()
            for item in recovered {
                WidgetBridge.syncSession(item.session, latestDream: nil)
            }
        }

        return recovered
    }

    private static func hasRecoverableData(_ session: SleepSession) -> Bool {
        !session.phases.isEmpty
            || !session.soundEvents.isEmpty
            || !session.snoreEvents.isEmpty
    }

    /// Dernière activité enregistrée + marge, bornée à maintenant.
    static func estimatedEndTime(for session: SleepSession, now: Date) -> Date {
        var markers: [Date] = [session.startTime.addingTimeInterval(60)]

        if let lastPhase = session.phases.max(by: { $0.endTime < $1.endTime }) {
            markers.append(lastPhase.endTime)
        }
        if let lastSound = session.soundEvents.max(by: { $0.timestamp < $1.timestamp }) {
            markers.append(lastSound.timestamp.addingTimeInterval(max(1, lastSound.duration)))
        }
        if let lastSnore = session.snoreEvents.max(by: { $0.timestamp < $1.timestamp }) {
            markers.append(lastSnore.timestamp.addingTimeInterval(max(1, lastSnore.duration)))
        }

        let lastActivity = markers.max() ?? session.startTime
        let end = min(now, lastActivity.addingTimeInterval(5 * 60))
        return max(end, session.startTime.addingTimeInterval(60))
    }

    private static func closeOpenPhases(session: SleepSession, end: Date) {
        if let last = session.phases.max(by: { $0.endTime < $1.endTime }) {
            if last.endTime < end {
                last.endTime = end
            }
            return
        }

        let phase = SleepPhase(
            startTime: session.startTime,
            endTime: end,
            phaseType: .light,
            movementScore: 0
        )
        phase.session = session
        session.phases.append(phase)
    }
}
