import Foundation
import SwiftData

/// Attribution cohérente des facteurs aux nuits (journal + avant-sommeil + moteurs).
enum SleepFactorAttribution {
    /// Heures avant le coucher pour une prise.
    static func hoursBeforeSleep(consumedAt: Date, bedtime: Date) -> Double {
        max(0, bedtime.timeIntervalSince(consumedAt) / 3600)
    }

    /// Fenêtre d’attribution : de la veille (réveil) jusqu’à peu après le coucher.
    static func window(for session: SleepSession, previousSessionEnd: Date?) -> (start: Date, end: Date) {
        let bedtime = session.startTime
        let defaultStart = bedtime.addingTimeInterval(-18 * 3600)
        let start: Date
        if let prevEnd = previousSessionEnd {
            start = max(defaultStart, prevEnd)
        } else {
            start = defaultStart
        }
        let end = (session.endTime ?? bedtime).addingTimeInterval(2 * 3600)
        return (start, end)
    }

    /// Tous les facteurs qui influencent cette nuit (liés + orphelins dans la fenêtre).
    static func factors(for session: SleepSession, allFactors: [SleepFactor], previousSessionEnd: Date? = nil) -> [SleepFactor] {
        let (start, end) = window(for: session, previousSessionEnd: previousSessionEnd)
        let bedtime = session.startTime

        var byId: [UUID: SleepFactor] = [:]
        for f in session.factors {
            byId[f.id] = f
        }
        for f in allFactors where f.session?.id == session.id {
            byId[f.id] = f
        }
        for f in allFactors where f.session == nil && f.consumedAt >= start && f.consumedAt <= end {
            if !DailyRoutineMarkers.isSkipped(f) {
                byId[f.id] = f
            }
        }

        let merged = Array(byId.values).sorted { $0.consumedAt < $1.consumedAt }
        for f in merged where f.session?.id == session.id || f.session == nil {
            let h = hoursBeforeSleep(consumedAt: f.consumedAt, bedtime: bedtime)
            if abs(f.hoursBeforeSleep - h) > 0.05 {
                f.hoursBeforeSleep = h
            }
        }
        return merged
    }

    /// Facteurs depuis le dernier réveil (énergie, caféine du jour, interactions).
    static func factorsSinceWake(
        wake: Date,
        now: Date = Date(),
        allFactors: [SleepFactor]
    ) -> [SleepFactor] {
        allFactors.filter { factor in
            !DailyRoutineMarkers.isSkipped(factor)
                && factor.consumedAt >= wake.addingTimeInterval(-30 * 60)
                && factor.consumedAt <= now
        }
    }

    /// Contexte « aujourd’hui » pour l’accueil : depuis le réveil de la dernière nuit.
    static func factorsForCurrentContext(
        sessions: [SleepSession],
        allFactors: [SleepFactor],
        now: Date = Date()
    ) -> [SleepFactor] {
        guard let wake = latestWakeTime(sessions: sessions, now: now) else {
            let start = Calendar.current.startOfDay(for: now)
            return allFactors.filter { $0.consumedAt >= start && $0.consumedAt <= now }
        }
        return factorsSinceWake(wake: wake, now: now, allFactors: allFactors)
    }

    /// Rattache les orphelins pertinents au démarrage d’une nuit (fenêtre 18 h, pas 48 h).
    static func attachOrphans(
        to session: SleepSession,
        allSessions: [SleepSession],
        allFactors: [SleepFactor],
        in context: ModelContext
    ) {
        let prevEnd = allSessions
            .filter { $0.kind == .night && ($0.endTime ?? .distantPast) < session.startTime }
            .compactMap(\.endTime)
            .max()

        let (start, end) = window(for: session, previousSessionEnd: prevEnd)
        let bedtime = session.startTime

        for factor in allFactors where factor.session == nil {
            guard factor.consumedAt >= start, factor.consumedAt <= end else { continue }
            guard !DailyRoutineMarkers.isSkipped(factor) else { continue }
            link(factor, to: session, bedtime: bedtime)
        }
        try? context.save()
    }

    /// Recalcule les liens pour toutes les nuits terminées (maintenance).
    static func relinkAll(sessions: [SleepSession], allFactors: [SleepFactor], in context: ModelContext) {
        let nights = sessions
            .filter { $0.kind == .night && $0.endTime != nil }
            .sorted { $0.startTime < $1.startTime }

        for (index, session) in nights.enumerated() {
            let prevEnd = index > 0 ? nights[index - 1].endTime : nil
            let (start, end) = window(for: session, previousSessionEnd: prevEnd)
            let bedtime = session.startTime

            for factor in allFactors {
                guard factor.consumedAt >= start, factor.consumedAt <= end else { continue }
                guard !DailyRoutineMarkers.isSkipped(factor) else { continue }
                if factor.session == nil || factor.session?.id == session.id {
                    link(factor, to: session, bedtime: bedtime)
                }
            }
        }
        try? context.save()
    }

    static func link(_ factor: SleepFactor, to session: SleepSession, bedtime: Date) {
        factor.session = session
        factor.hoursBeforeSleep = hoursBeforeSleep(consumedAt: factor.consumedAt, bedtime: bedtime)
        if !session.factors.contains(where: { $0.id == factor.id }) {
            session.factors.append(factor)
        }
    }

    private static func latestWakeTime(sessions: [SleepSession], now: Date) -> Date? {
        let cal = Calendar.current
        let recent = sessions
            .filter { $0.kind == .night && $0.endTime != nil }
            .sorted { ($0.endTime ?? $0.startTime) > ($1.endTime ?? $1.startTime) }
        guard let session = recent.first else { return nil }
        let wake = session.actualWakeTime ?? session.endTime ?? session.startTime
        if cal.isDate(wake, inSameDayAs: now) || wake > cal.startOfDay(for: now).addingTimeInterval(-36 * 3600) {
            return wake
        }
        return nil
    }
}
