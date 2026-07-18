import Foundation

/// Score de récupération réelle du matin (inertie, dette, caféine tardive, fragmentation).
enum MorningRecoveryEngine {
    struct MorningRecoveryScore {
        let score: Int
        let label: String
        let detail: String
        let inertiaPenalty: Int
        let debtPenalty: Int
        let caffeinePenalty: Int
        let fragmentationPenalty: Int
    }

    static func score(
        sessions: [SleepSession],
        profile: UserProfile?,
        factors: [SleepFactor],
        now: Date = Date()
    ) -> MorningRecoveryScore? {
        let nights = SleepNightGrouper.logicalNights(
            from: sessions.filter { $0.kind == .night },
            days: 14,
            now: now
        )
        guard let last = nights.last else { return nil }

        let debtReport = SleepDebtEngine.report(sessions: sessions, profile: profile, now: now)
        let debtPenalty = min(35, Int(debtReport.netDebtHours * 8))

        let inertiaPenaltyHours = last.inertiaPenaltyHours + min(1.0, debtReport.netDebtHours * 0.15)
        let inertiaMinutes = inertiaMinutes(fragmentCount: last.fragmentCount, penaltyHours: inertiaPenaltyHours)
        let inertiaPenalty = min(25, inertiaMinutes / 2)

        let wake = last.primarySession.actualWakeTime ?? last.primarySession.endTime ?? now
        let dayFactors = SleepFactorAttribution.factorsSinceWake(wake: wake, now: now, allFactors: factors)
        let caffeinePenalty = lateCaffeinePenalty(
            factors: dayFactors,
            wakeTime: wake,
            now: now,
            sessions: sessions
        )

        let fragmentationPenalty = fragmentationPenalty(for: last)

        let raw = 100 - debtPenalty - inertiaPenalty - caffeinePenalty - fragmentationPenalty
        let score = min(100, max(0, raw))

        let label: String
        switch score {
        case 80...: label = "Bonne récupération"
        case 60..<80: label = "Récupération correcte"
        case 40..<60: label = "Récupération fragile"
        default: label = "Récupération difficile"
        }

        var parts: [String] = []
        if debtPenalty > 5 { parts.append("dette \(SleepDebtEngine.formatHours(debtReport.netDebtHours))") }
        if inertiaPenalty > 0 { parts.append("inertie ~\(inertiaMinutes) min") }
        if caffeinePenalty > 0 { parts.append("caféine tardive") }
        if fragmentationPenalty > 0 { parts.append("nuit fragmentée") }

        let detail = parts.isEmpty ? "Facteurs favorables ce matin." : parts.joined(separator: " · ")

        return MorningRecoveryScore(
            score: score,
            label: label,
            detail: detail,
            inertiaPenalty: inertiaPenalty,
            debtPenalty: debtPenalty,
            caffeinePenalty: caffeinePenalty,
            fragmentationPenalty: fragmentationPenalty
        )
    }

    private static func inertiaMinutes(fragmentCount: Int, penaltyHours: Double) -> Int {
        var minutes = 50
        if fragmentCount > 1 { minutes += 20 }
        minutes += Int(penaltyHours * 25)
        return min(120, max(35, minutes))
    }

    private static func lateCaffeinePenalty(
        factors: [SleepFactor],
        wakeTime: Date,
        now: Date,
        sessions: [SleepSession]
    ) -> Int {
        let cal = Calendar.current
        guard cal.isDate(wakeTime, inSameDayAs: now) || wakeTime < now else { return 0 }

        let threshold = CaffeinePersonalizationEngine.suggestedCutoffHour(
            factors: factors,
            sessions: sessions
        )

        let late = factors.filter { factor in
            guard factor.type == .caffeine else { return false }
            let h = cal.component(.hour, from: factor.consumedAt)
            return h >= threshold && factor.consumedAt >= cal.startOfDay(for: now)
        }

        return min(20, late.count * 8)
    }

    private static func fragmentationPenalty(for night: SleepNightGrouper.LogicalNight) -> Int {
        if night.fragmentCount > 1 {
            return min(20, (night.fragmentCount - 1) * 10)
        }
        if night.primarySession.pauseCount > 0 { return 12 }
        return 0
    }
}
