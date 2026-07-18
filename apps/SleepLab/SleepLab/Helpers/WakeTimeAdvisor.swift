import Foundation

/// Suggestions de lever alignées sur cycles de sommeil (~90 min) et objectif du profil.
enum WakeTimeAdvisor {
    static let fallAsleepLatencyMinutes = 15
    static let cycleMinutes = 90

    struct Suggestion: Identifiable {
        let id = UUID()
        let wakeTime: Date
        let label: String
        let detail: String
        let sleepMinutes: Int
        let isRecommended: Bool
    }

    static func suggestions(bedtime: Date, profile: UserProfile?, now: Date = Date()) -> [Suggestion] {
        let calendar = Calendar.current
        let targetHours = profile?.targetSleepDuration ?? 8
        let targetSleepMinutes = Int(targetHours * 60)

        guard let sleepOnset = calendar.date(
            byAdding: .minute,
            value: fallAsleepLatencyMinutes,
            to: bedtime
        ) else { return [] }

        let cycleOptions: [(cycles: Int, shortLabel: String)] = [
            (4, "6 h"),
            (5, "7 h 30"),
            (6, "9 h"),
        ]

        let built: [Suggestion] = cycleOptions.compactMap { option in
            let sleepMin = option.cycles * cycleMinutes
            guard let wake = calendar.date(byAdding: .minute, value: sleepMin, to: sleepOnset) else {
                return nil
            }
            guard wake > now.addingTimeInterval(20 * 60) else { return nil }

            return Suggestion(
                wakeTime: wake,
                label: wake.formatted(date: .omitted, time: .shortened),
                detail: "\(option.shortLabel) · \(option.cycles) cycles",
                sleepMinutes: sleepMin,
                isRecommended: false
            )
        }

        guard !built.isEmpty else { return [] }

        let recommendedIndex = built.enumerated().min(by: { a, b in
            abs(a.element.sleepMinutes - targetSleepMinutes) < abs(b.element.sleepMinutes - targetSleepMinutes)
        })?.offset ?? min(1, built.count - 1)

        return built.enumerated().map { index, item in
            Suggestion(
                wakeTime: item.wakeTime,
                label: item.label,
                detail: index == recommendedIndex
                    ? "\(item.detail) · conseillé"
                    : item.detail,
                sleepMinutes: item.sleepMinutes,
                isRecommended: index == recommendedIndex
            )
        }
    }

    static func defaultWakeTime(bedtime: Date, profile: UserProfile?, now: Date = Date()) -> Date {
        suggestions(bedtime: bedtime, profile: profile, now: now)
            .first(where: \.isRecommended)?
            .wakeTime
            ?? suggestions(bedtime: bedtime, profile: profile, now: now).first?.wakeTime
            ?? bedtime.addingTimeInterval(8 * 3600)
    }

    static func sleepDurationText(from bedtime: Date, to wakeTime: Date) -> String {
        let onset = bedtime.addingTimeInterval(TimeInterval(fallAsleepLatencyMinutes * 60))
        let minutes = max(0, Int(wakeTime.timeIntervalSince(onset) / 60))
        let h = minutes / 60
        let m = minutes % 60
        if m == 0 { return "\(h) h de sommeil estimé" }
        return "\(h) h \(m) de sommeil estimé"
    }
}
