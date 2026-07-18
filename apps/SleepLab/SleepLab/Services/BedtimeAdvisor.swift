import Foundation

/// Fenêtre de coucher personnalisée (dette, cycle, chronotype, substances, coucher minimum).
enum BedtimeAdvisor {
    struct BedtimeRecommendation {
        let idealBedtime: Date
        let windowStart: Date
        let windowEnd: Date
        let message: String
        let factorsSummary: String
        let wasClampedToMinimum: Bool
    }

    static func recommend(
        profile: UserProfile?,
        sessions: [SleepSession],
        factors: [SleepFactor],
        now: Date = Date()
    ) -> BedtimeRecommendation? {
        guard let profile else { return nil }

        let cal = Calendar.current
        let debt = SleepDebtEngine.report(sessions: sessions, profile: profile, now: now)
        var ideal = debt.recommendedBedtime ?? profile.targetBedtime ?? defaultBedtime(on: now)
        var notes: [String] = []
        var wasClamped = false

        if debt.netDebtHours > 0.5 {
            notes.append("dette \(SleepDebtEngine.formatHours(debt.netDebtHours))")
        }

        if let phase = cyclePhase(profile: profile, on: now) {
            switch phase {
            case .luteal:
                ideal = cal.date(byAdding: .minute, value: -30, to: ideal) ?? ideal
                notes.append("phase lutéale")
            case .menstrual:
                ideal = cal.date(byAdding: .minute, value: -15, to: ideal) ?? ideal
                notes.append("phase menstruelle")
            default:
                break
            }
        }

        let cutoff = CaffeinePersonalizationEngine.suggestedCutoffHour(factors: factors, sessions: sessions)
        let lateCaf = factors.contains {
            $0.type == .caffeine
                && cal.isDate($0.consumedAt, inSameDayAs: now)
                && cal.component(.hour, from: $0.consumedAt) >= cutoff
        }
        if lateCaf {
            ideal = cal.date(byAdding: .minute, value: -20, to: ideal) ?? ideal
            notes.append("caféine tardive")
        }

        switch profile.chronotype {
        case .earlyBird:
            ideal = cal.date(byAdding: .minute, value: -20, to: ideal) ?? ideal
        case .nightOwl:
            ideal = cal.date(byAdding: .minute, value: 25, to: ideal) ?? ideal
        case .neutral:
            break
        }

        let minimumTonight = minimumBedtimeTonight(profile: profile, now: now)
        if ideal < minimumTonight {
            ideal = minimumTonight
            wasClamped = true
            notes.append("coucher min. \(minimumTonight.formatted(date: .omitted, time: .shortened))")
        }

        if ideal <= now.addingTimeInterval(30 * 60) {
            ideal = cal.date(byAdding: .day, value: 1, to: ideal) ?? ideal
        }

        let windowStart = max(ideal.addingTimeInterval(-30 * 60), minimumTonight)
        let windowEnd = ideal.addingTimeInterval(30 * 60)
        let timeFmt = ideal.formatted(date: .omitted, time: .shortened)
        var message = "Ton coucher idéal ce soir : vers \(timeFmt)."
        if wasClamped {
            message += " (pas avant ton heure minimum)"
        }

        let factorsSummary = notes.isEmpty
            ? "Basé sur ton objectif sommeil et ton rythme."
            : notes.joined(separator: " · ")

        return BedtimeRecommendation(
            idealBedtime: ideal,
            windowStart: windowStart,
            windowEnd: windowEnd,
            message: message,
            factorsSummary: factorsSummary,
            wasClampedToMinimum: wasClamped
        )
    }

    private static func minimumBedtimeTonight(profile: UserProfile, now: Date) -> Date {
        let cal = Calendar.current
        var c = cal.dateComponents([.year, .month, .day], from: now)
        c.hour = profile.minimumBedtimeHour
        c.minute = profile.minimumBedtimeMinute
        c.second = 0
        var date = cal.date(from: c) ?? now
        if date <= now.addingTimeInterval(2 * 3600) {
            date = cal.date(byAdding: .day, value: 1, to: date) ?? date
        }
        return date
    }

    private static func cyclePhase(profile: UserProfile, on date: Date) -> CyclePhase? {
        guard profile.tracksMenstrualCycle, let day = profile.currentCycleDay(on: date) else { return nil }
        return CyclePhase.from(cycleDay: day, cycleLength: profile.averageCycleLength)
    }

    private static func defaultBedtime(on date: Date) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        c.hour = 23
        c.minute = 0
        return Calendar.current.date(from: c) ?? date
    }
}
