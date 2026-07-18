import Foundation

/// Regroupement calendrier & raccourcis pour le journal substances.
enum FactorJournalHelpers {
    static func isJournalSubstance(_ type: FactorType) -> Bool {
        switch type.category {
        case .stimulant, .substance, .supplement, .food:
            return true
        default:
            return false
        }
    }

    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    /// Combine le jour calendrier cible avec l’heure d’une autre date (journal : jour sélectionné + heure saisie).
    static func timestamp(on day: Date, preservingTimeFrom reference: Date) -> Date {
        let cal = Calendar.current
        let targetDay = startOfDay(day)
        var comps = cal.dateComponents([.year, .month, .day], from: targetDay)
        let time = cal.dateComponents([.hour, .minute], from: reference)
        comps.hour = time.hour
        comps.minute = time.minute
        comps.second = 0
        return cal.date(from: comps) ?? targetDay
    }

    static func factors(on day: Date, from all: [SleepFactor]) -> [SleepFactor] {
        let start = startOfDay(day)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return [] }
        return all
            .filter { $0.consumedAt >= start && $0.consumedAt < end }
            .sorted { $0.consumedAt > $1.consumedAt }
    }

    static func daysWithEntries(in month: Date, factors: [SleepFactor]) -> Set<Date> {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .month, for: month) else { return [] }
        var days = Set<Date>()
        for factor in factors where factor.consumedAt >= interval.start && factor.consumedAt < interval.end {
            days.insert(startOfDay(factor.consumedAt))
        }
        return days
    }

    /// Les 3 dernières prises (substances) pour répétition rapide dans le popup.
    static func recentSubstancePicks(from all: [SleepFactor], limit: Int = 3) -> [RecentSubstancePick] {
        let substanceLogs = all
            .filter { isJournalSubstance($0.type) }
            .sorted { $0.consumedAt > $1.consumedAt }

        var picks: [RecentSubstancePick] = []
        var seen = Set<String>()

        for log in substanceLogs {
            let key = "\(log.type.rawValue)|\(log.value)"
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            picks.append(RecentSubstancePick(
                type: log.type,
                value: log.value,
                displayLabel: pickLabel(for: log)
            ))
            if picks.count >= limit { break }
        }
        return picks
    }

    private static func pickLabel(for log: SleepFactor) -> String {
        if let quick = PreSleepFactorCatalog.allQuickPicks.first(where: {
            $0.type == log.type && abs($0.value - log.value) < 0.001
        }) {
            return quick.label
        }
        if log.value > 0, !log.unit.isEmpty {
            let v = log.value.rounded() == log.value ? "\(Int(log.value))" : String(format: "%.1f", log.value)
            return "\(log.type.displayName) (\(v)\(log.unit))"
        }
        return log.type.displayName
    }
}

struct RecentSubstancePick: Identifiable {
    let id = UUID()
    let type: FactorType
    let value: Double
    let displayLabel: String
}
