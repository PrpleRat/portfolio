import Foundation

/// Pics d’énergie / fatigue estimés (sommeil + chronotype + substances).
enum CircadianEnergyEngine {
    struct TimeWindow: Identifiable {
        let id = UUID()
        let kind: Kind
        let start: Date
        let end: Date
        let label: String
        /// Heure de référence (ex. prise de caféine) pour affichage contextuel.
        var referenceTime: Date?

        enum Kind: String {
            case inertia
            case energyPeak
            case fatigueDip
            case fatiguePeak
            case caffeineBoost
            case substanceDip
            case secondWind
        }
    }

    struct Forecast {
        let wakeTime: Date
        let windows: [TimeWindow]
        let headline: String
        let detailLine: String
    }

    static func forecast(
        sessions: [SleepSession],
        profile: UserProfile?,
        factors: [SleepFactor],
        now: Date = Date()
    ) -> Forecast? {
        guard let wake = latestWakeTime(sessions: sessions, now: now) else { return nil }
        let chronotype = profile?.chronotype ?? .neutral
        let metabolism = profile?.caffeineMetabolism ?? 3
        let debt = SleepDebtEngine.report(sessions: sessions, profile: profile, now: now)
        let cyclePhase = currentCyclePhase(profile: profile, wake: wake)

        let logical = SleepNightGrouper.logicalNights(from: sessions, days: 2, now: now).last
        let inertiaMinutes = inertiaDurationMinutes(
            fragmentCount: logical?.fragmentCount ?? 1,
            inertiaPenaltyHours: (logical?.inertiaPenaltyHours ?? 0) + debtInertiaPenalty(debt: debt)
        )

        let peakOffset = chronotypePeakOffsetHours(chronotype) + cycleEnergyOffset(phase: cyclePhase)
        let energyPeakCenter = wake.addingTimeInterval(peakOffset * 3600)
        let fatigueDipCenter = wake.addingTimeInterval((7.5 - min(1.0, debt.netDebtHours * 0.2)) * 3600)
        let fatiguePeakCenter = wake.addingTimeInterval(
            (fatiguePeakOffsetHours(chronotype) - min(2.0, debt.netDebtHours * 0.35)) * 3600
        )
        let secondWindCenter = chronotype == .nightOwl ? wake.addingTimeInterval(10 * 3600) : nil

        var windows: [TimeWindow] = [
            TimeWindow(
                kind: .inertia,
                start: wake,
                end: wake.addingTimeInterval(Double(inertiaMinutes) * 60),
                label: EnergyWindowGlossary.title(for: .inertia)
            ),
            TimeWindow(
                kind: .energyPeak,
                start: energyPeakCenter.addingTimeInterval(-30 * 60),
                end: energyPeakCenter.addingTimeInterval(75 * 60),
                label: EnergyWindowGlossary.title(for: .energyPeak)
            ),
            TimeWindow(
                kind: .fatigueDip,
                start: fatigueDipCenter.addingTimeInterval(-40 * 60),
                end: fatigueDipCenter.addingTimeInterval(60 * 60),
                label: EnergyWindowGlossary.title(for: .fatigueDip)
            ),
            TimeWindow(
                kind: .fatiguePeak,
                start: fatiguePeakCenter.addingTimeInterval(-50 * 60),
                end: fatiguePeakCenter.addingTimeInterval(90 * 60),
                label: EnergyWindowGlossary.title(for: .fatiguePeak)
            )
        ]

        let dayFactors = SleepFactorAttribution.factorsSinceWake(wake: wake, now: now, allFactors: factors)

        if let caffeine = caffeineBoostWindow(factors: dayFactors, wake: wake, metabolism: metabolism, now: now) {
            windows.append(caffeine)
        }
        if let sedation = substanceDipWindow(factors: dayFactors, now: now) {
            windows.append(sedation)
        }

        if let secondWindCenter {
            windows.append(TimeWindow(
                kind: .secondWind,
                start: secondWindCenter,
                end: secondWindCenter.addingTimeInterval(2 * 3600),
                label: EnergyWindowGlossary.title(for: .secondWind)
            ))
        }

        windows = resolveOverlaps(windows)

        let headline = headlineFor(now: now, windows: windows)
        let detail = detailLine(
            wake: wake,
            logical: logical,
            chronotype: chronotype,
            debt: debt,
            cyclePhase: cyclePhase
        )

        return Forecast(wakeTime: wake, windows: windows, headline: headline, detailLine: detail)
    }

    /// Réduit les chevauchements : fenêtres plus courtes, priorité aux repères les plus utiles.
    private static func resolveOverlaps(_ windows: [TimeWindow]) -> [TimeWindow] {
        let priority: [TimeWindow.Kind: Int] = [
            .inertia: 0,
            .energyPeak: 1,
            .caffeineBoost: 2,
            .substanceDip: 3,
            .fatigueDip: 4,
            .fatiguePeak: 5,
            .secondWind: 6
        ]

        var sorted = windows.sorted {
            let p0 = priority[$0.kind] ?? 9
            let p1 = priority[$1.kind] ?? 9
            if p0 != p1 { return p0 < p1 }
            return $0.start < $1.start
        }

        var result: [TimeWindow] = []
        for window in sorted {
            var w = window
            for kept in result {
                guard overlaps(w, kept) else { continue }
                let pW = priority[w.kind] ?? 9
                let pK = priority[kept.kind] ?? 9
                if pW > pK {
                    w = trim(window: w, avoiding: kept)
                }
            }
            if w.end > w.start.addingTimeInterval(12 * 60) {
                result.append(w)
            }
        }
        return result.sorted { $0.start < $1.start }
    }

    private static func overlaps(_ a: TimeWindow, _ b: TimeWindow) -> Bool {
        a.start < b.end && b.start < a.end
    }

    private static func trim(window: TimeWindow, avoiding other: TimeWindow) -> TimeWindow {
        if window.start < other.end && window.end > other.end {
            let newStart = other.end.addingTimeInterval(5 * 60)
            return TimeWindow(
                kind: window.kind,
                start: newStart,
                end: window.end,
                label: window.label,
                referenceTime: window.referenceTime
            )
        }
        if window.end > other.start && window.start < other.start {
            let newEnd = other.start.addingTimeInterval(-5 * 60)
            return TimeWindow(
                kind: window.kind,
                start: window.start,
                end: newEnd,
                label: window.label,
                referenceTime: window.referenceTime
            )
        }
        return window
    }

    private static func latestWakeTime(sessions: [SleepSession], now: Date) -> Date? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let recent = sessions
            .filter { $0.kind == .night && $0.endTime != nil }
            .sorted { ($0.endTime ?? $0.startTime) > ($1.endTime ?? $1.startTime) }
        guard let session = recent.first else { return nil }
        let wake = session.actualWakeTime ?? session.endTime ?? session.startTime
        if cal.isDate(wake, inSameDayAs: now) || wake > today.addingTimeInterval(-36 * 3600) {
            return wake
        }
        return nil
    }

    private static func inertiaDurationMinutes(fragmentCount: Int, inertiaPenaltyHours: Double) -> Int {
        var minutes = 50
        if fragmentCount > 1 { minutes += 20 }
        minutes += Int(inertiaPenaltyHours * 25)
        return min(120, max(35, minutes))
    }

    private static func chronotypePeakOffsetHours(_ chronotype: Chronotype) -> Double {
        switch chronotype {
        case .earlyBird: return 2.5
        case .neutral: return 3.5
        case .nightOwl: return 5.0
        }
    }

    private static func fatiguePeakOffsetHours(_ chronotype: Chronotype) -> Double {
        switch chronotype {
        case .earlyBird: return 13
        case .neutral: return 15
        case .nightOwl: return 17
        }
    }

    private static func currentCyclePhase(profile: UserProfile?, wake: Date) -> UserProfile.MenstrualPhase? {
        guard let profile, profile.tracksMenstrualCycle, let day = profile.currentCycleDay(on: wake) else { return nil }
        return profile.menstrualPhase(for: day)
    }

    private static func cycleEnergyOffset(phase: UserProfile.MenstrualPhase?) -> Double {
        guard let phase else { return 0 }
        switch phase {
        case .follicular, .ovulation: return -0.3
        case .menstrual: return 0.4
        case .luteal: return 0.8
        }
    }

    private static func debtInertiaPenalty(debt: SleepDebtEngine.SleepDebtReport) -> Double {
        min(1.0, debt.netDebtHours * 0.15)
    }

    private static func caffeineBoostWindow(
        factors: [SleepFactor],
        wake: Date,
        metabolism: Int,
        now: Date
    ) -> TimeWindow? {
        let stimulants: Set<FactorType> = [.caffeine, .energyDrink, .theanine]
        let recent = factors
            .filter { stimulants.contains($0.type) && $0.consumedAt >= wake.addingTimeInterval(-2 * 3600) }
            .sorted { $0.consumedAt > $1.consumedAt }
        guard let last = recent.first else { return nil }

        let onsetMinutes = 35.0 + Double(6 - metabolism) * 4
        let peakStart = last.consumedAt.addingTimeInterval(onsetMinutes * 60)
        let peakEnd = peakStart.addingTimeInterval(2.0 * 3600)

        guard peakEnd > now.addingTimeInterval(-30 * 60) else { return nil }

        return TimeWindow(
            kind: .caffeineBoost,
            start: peakStart,
            end: peakEnd,
            label: EnergyWindowGlossary.title(for: .caffeineBoost),
            referenceTime: last.consumedAt
        )
    }

    private static func substanceDipWindow(
        factors: [SleepFactor],
        now: Date
    ) -> TimeWindow? {
        let sedatives: Set<FactorType> = [.alcohol, .cannabis, .melatonin]
        let recent = factors
            .filter { sedatives.contains($0.type) }
            .sorted { $0.consumedAt > $1.consumedAt }
        guard let last = recent.first else { return nil }

        let onset: TimeInterval
        switch last.type {
        case .alcohol: onset = 1.5 * 3600
        case .cannabis: onset = 1.25 * 3600
        case .melatonin: onset = 45 * 60
        default: onset = 1.5 * 3600
        }

        let start = last.consumedAt.addingTimeInterval(onset)
        let end = start.addingTimeInterval(2 * 3600)
        guard end > now.addingTimeInterval(-20 * 60) else { return nil }

        return TimeWindow(
            kind: .substanceDip,
            start: start,
            end: end,
            label: EnergyWindowGlossary.title(for: .substanceDip),
            referenceTime: last.consumedAt
        )
    }

    private static func headlineFor(now: Date, windows: [TimeWindow]) -> String {
        if let current = windows.first(where: { now >= $0.start && now <= $0.end }) {
            switch current.kind {
            case .inertia: return "Inertie du sommeil — réveil difficile, c’est normal."
            case .energyPeak: return "Tu es dans ton pic d’énergie."
            case .fatigueDip: return "Coup de barre probable — pause courte utile."
            case .fatiguePeak: return "Pic de fatigue — évite les décisions lourdes."
            case .caffeineBoost: return "Effet stimulant en cours."
            case .substanceDip: return "Baisse après substances — effet retardé normal."
            case .secondWind: return "Second souffle possible ce soir."
            }
        }
        if let next = windows.first(where: { $0.start > now }) {
            let t = next.start.formatted(date: .omitted, time: .shortened)
            return "Prochain repère : \(next.label.lowercased()) vers \(t)."
        }
        return "Courbe du jour basée sur ton sommeil et tes substances."
    }

    private static func detailLine(
        wake: Date,
        logical: SleepNightGrouper.LogicalNight?,
        chronotype: Chronotype,
        debt: SleepDebtEngine.SleepDebtReport,
        cyclePhase: UserProfile.MenstrualPhase?
    ) -> String {
        var parts: [String] = [
            "Réveil \(wake.formatted(date: .omitted, time: .shortened))",
            chronotype.displayName.lowercased()
        ]
        if debt.netDebtHours > 0.5 {
            parts.append("dette \(SleepDebtEngine.formatHours(debt.netDebtHours))")
        }
        if let cyclePhase {
            parts.append("phase \(cyclePhase.displayName.lowercased())")
        }
        if let logical, logical.fragmentCount > 1 {
            parts.append("nuit en \(logical.fragmentCount) morceaux")
        }
        return parts.joined(separator: " · ")
    }
}
