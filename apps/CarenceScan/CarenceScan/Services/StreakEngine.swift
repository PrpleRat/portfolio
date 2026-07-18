import Foundation

struct GamificationBadge: Identifiable, Hashable {
    let id: String
    let titre: String
    let detail: String
    let icon: String
    let obtenu: Bool
}

@MainActor
enum StreakEngine {

    static func streakActuel(tracker: SymptomTrackerViewModel) -> Int {
        let ids = tracker.trackedSymptomeIds
        guard !ids.isEmpty else { return 0 }
        var count = 0
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        while true {
            let hasEntry = ids.contains { id in
                tracker.journalEntries.contains {
                    $0.symptomeId == id && cal.isDate($0.date, inSameDayAs: day)
                }
            }
            guard hasEntry else { break }
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    static func mettreAJourRecord(tracker: SymptomTrackerViewModel) {
        let actuel = streakActuel(tracker: tracker)
        if actuel > tracker.settings.longestStreak {
            tracker.settings.longestStreak = actuel
            tracker.persistSettings()
        }
    }

    static func badges(tracker: SymptomTrackerViewModel, evolutif: EvolutiveBilanResult?) -> [GamificationBadge] {
        let streak = streakActuel(tracker: tracker)
        let record = tracker.settings.longestStreak
        let resolus = evolutif?.symptomesResolus.count ?? 0
        let jours = evolutif?.joursSuivi ?? 0

        return [
            GamificationBadge(
                id: "streak_3",
                titre: "3 jours d'affilée",
                detail: "Check-in quotidien 3 jours consécutifs",
                icon: "flame",
                obtenu: streak >= 3 || record >= 3
            ),
            GamificationBadge(
                id: "streak_7",
                titre: "Semaine complète",
                detail: "7 jours de suivi consécutifs",
                icon: "flame.fill",
                obtenu: streak >= 7 || record >= 7
            ),
            GamificationBadge(
                id: "streak_14",
                titre: "2 semaines régulières",
                detail: "14 jours de suivi — bilan évolutif fiable",
                icon: "star.fill",
                obtenu: streak >= 14 || record >= 14
            ),
            GamificationBadge(
                id: "resolved",
                titre: "Symptômes en baisse",
                detail: "\(resolus) symptôme\(resolus > 1 ? "s" : "") considéré\(resolus > 1 ? "s" : "") résolu\(resolus > 1 ? "s" : "")",
                icon: "arrow.down.circle.fill",
                obtenu: resolus > 0
            ),
            GamificationBadge(
                id: "suivi_14j",
                titre: "Suivi établi",
                detail: "\(jours) jours de suivi cumulés",
                icon: "calendar.badge.checkmark",
                obtenu: jours >= 14
            )
        ]
    }
}
