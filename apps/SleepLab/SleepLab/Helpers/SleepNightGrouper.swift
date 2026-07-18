import Foundation
import SwiftData

/// Regroupe les nuits par jour de réveil, fusionne les fragments, permet la reprise.
enum SleepNightGrouper {
    /// Jusqu’à 16 h après la fin : même matinée = une seule nuit.
    static let maxResumeGap: TimeInterval = 16 * 3600
    static let maxMergeGap: TimeInterval = 16 * 3600

    struct LogicalNight: Identifiable {
        let id = UUID()
        let wakeDay: Date
        let sessions: [SleepSession]
        let totalSleptHours: Double
        let fragmentCount: Int
        /// Pénalité inertie du sommeil (heures) si nuit coupée en plusieurs morceaux.
        let inertiaPenaltyHours: Double
        let effectiveSleptHours: Double
        let primarySession: SleepSession
    }

    static func wakeDay(for session: SleepSession) -> Date? {
        guard let end = session.endTime ?? session.actualWakeTime else { return nil }
        return Calendar.current.startOfDay(for: end)
    }

    // MARK: - Reprise tracking

    @MainActor
    static func findResumableNight(in context: ModelContext, now: Date = Date()) throws -> SleepSession? {
        let descriptor = FetchDescriptor<SleepSession>(
            sortBy: [SortDescriptor(\SleepSession.endTime, order: .reverse)]
        )
        let candidates = try context.fetch(descriptor).filter { session in
            guard session.kind == .night,
                  session.endTime != nil,
                  !session.isManuallyEntered else { return false }
            guard let end = session.endTime else { return false }
            let gap = now.timeIntervalSince(end)
            guard gap >= 0, gap <= maxResumeGap else { return false }
            return Calendar.current.isDate(end, inSameDayAs: now)
                || gap <= 6 * 3600
        }
        return candidates.first
    }

    // MARK: - Fusion doublons (même jour de réveil)

    @MainActor
    static func mergeFragmentedWakeDaySessions(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<SleepSession>(
            sortBy: [SortDescriptor(\SleepSession.startTime, order: .forward)]
        )
        let nights = try context.fetch(descriptor).filter {
            $0.kind == .night && $0.endTime != nil && !$0.isManuallyEntered
        }

        let cal = Calendar.current
        let grouped = Dictionary(grouping: nights) { session in
            wakeDay(for: session) ?? cal.startOfDay(for: session.startTime)
        }

        var mergedCount = 0
        for (_, group) in grouped {
            let sorted = group.sorted { $0.startTime < $1.startTime }
            guard sorted.count > 1, shouldMergeFragments(sorted) else { continue }
            merge(group: sorted, in: context)
            mergedCount += sorted.count - 1
        }

        if mergedCount > 0 {
            try context.save()
        }
        return mergedCount
    }

    private static func shouldMergeFragments(_ sessions: [SleepSession]) -> Bool {
        guard sessions.count >= 2 else { return false }
        for index in 0..<(sessions.count - 1) {
            guard let endA = sessions[index].endTime else { return false }
            let startB = sessions[index + 1].startTime
            let gap = startB.timeIntervalSince(endA)
            if gap < 0 || gap > maxMergeGap { return false }
        }
        return true
    }

    private static func merge(group sessions: [SleepSession], in context: ModelContext) {
        guard let primary = sessions.first else { return }
        let others = Array(sessions.dropFirst())
        for other in others {
            if let end = primary.endTime {
                let gap = other.startTime.timeIntervalSince(end)
                if gap > 0 { primary.excludedPauseDuration += gap }
            }
            primary.pauseCount += other.pauseCount + 1
            for phase in other.phases {
                phase.session = primary
                primary.phases.append(phase)
            }
            for event in other.soundEvents {
                event.session = primary
                primary.soundEvents.append(event)
            }
            for snore in other.snoreEvents {
                snore.session = primary
                primary.snoreEvents.append(snore)
            }
            for factor in other.factors where !primary.factors.contains(where: { $0.id == factor.id }) {
                factor.session = primary
                primary.factors.append(factor)
            }
            primary.awakenings += other.awakenings
            if let loud = other.loudestEvent {
                primary.loudestEvent = max(primary.loudestEvent ?? 0, loud)
            }
            context.delete(other)
        }
        if let lastEnd = sessions.compactMap(\.endTime).max() {
            primary.finalize(at: lastEnd)
            primary.actualWakeTime = lastEnd
        }
        primary.recalculateSnoreMinutes()
        SleepPhaseRebalancer.rebalance(session: primary)
    }

    // MARK: - Dette de sommeil (par jour de réveil)

    /// Toutes les nuits logiques récentes (tri par jour de réveil croissant).
    static func logicalNights(
        from sessions: [SleepSession],
        now: Date = Date()
    ) -> [LogicalNight] {
        logicalNights(from: sessions, days: 90, now: now)
    }

    static func logicalNights(
        from sessions: [SleepSession],
        days: Int,
        now: Date = Date()
    ) -> [LogicalNight] {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -days, to: cal.startOfDay(for: now)) ?? now
        let nights = sessions.filter { session in
            guard session.kind == .night, session.endTime != nil else { return false }
            guard let wakeDay = wakeDay(for: session) else { return false }
            return wakeDay >= start
        }

        let grouped = Dictionary(grouping: nights) { session -> Date in
            wakeDay(for: session) ?? cal.startOfDay(for: session.startTime)
        }

        return grouped.map { wakeDay, group in
            let sorted = group.sorted { $0.startTime < $1.startTime }
            let slept = sorted.reduce(0.0) { $0 + $1.totalDuration } / 3600
            let fragments = sorted.count
            let penalty = inertiaPenaltyHours(fragmentCount: fragments, sessions: sorted)
            return LogicalNight(
                wakeDay: wakeDay,
                sessions: sorted,
                totalSleptHours: slept,
                fragmentCount: fragments,
                inertiaPenaltyHours: penalty,
                effectiveSleptHours: max(0, slept - penalty),
                primarySession: sorted.last ?? sorted[0]
            )
        }
        .sorted { $0.wakeDay < $1.wakeDay }
    }

    static func inertiaPenaltyHours(fragmentCount: Int, sessions: [SleepSession]) -> Double {
        guard fragmentCount > 1 else { return 0 }
        var penalty = 0.45
        if fragmentCount >= 3 { penalty += 0.35 }
        if let first = sessions.first?.endTime, let last = sessions.last?.startTime {
            let gap = last.timeIntervalSince(first)
            if gap > 0, gap < 3 * 3600 { penalty += 0.25 }
        }
        return min(1.5, penalty)
    }
}
