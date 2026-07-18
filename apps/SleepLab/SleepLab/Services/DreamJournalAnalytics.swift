import Foundation

struct DreamEmotionStat: Identifiable {
    let emotion: DreamEmotion
    let count: Int

    var id: String { emotion.rawValue }
}

struct DreamJournalStats {
    let total: Int
    let lucidCount: Int
    let nightmareCount: Int
    let avgClarity: Double
    let emotionBreakdown: [DreamEmotionStat]
    let topTags: [(String, Int)]
    let linkedToSleepCount: Int
    let avgScoreWhenLinked: Double?
}

extension DreamJournalStats {
    static let empty = DreamJournalStats(
        total: 0,
        lucidCount: 0,
        nightmareCount: 0,
        avgClarity: 0,
        emotionBreakdown: [],
        topTags: [],
        linkedToSleepCount: 0,
        avgScoreWhenLinked: nil
    )
}

enum DreamJournalAnalytics {
    static func stats(from dreams: [DreamEntry]) -> DreamJournalStats {
        let total = dreams.count
        let lucid = dreams.filter { $0.isLucid || $0.category == .lucid }.count
        let nightmares = dreams.filter { $0.category == .nightmare }.count
        let clarity = dreams.isEmpty ? 0 : Double(dreams.map(\.clarity).reduce(0, +)) / Double(dreams.count)

        var emotionCounts: [DreamEmotion: Int] = [:]
        for dream in dreams {
            for e in dream.emotions {
                emotionCounts[e, default: 0] += 1
            }
        }
        let breakdown = emotionCounts
            .sorted { $0.value > $1.value }
            .map { DreamEmotionStat(emotion: $0.key, count: $0.value) }

        var tagCounts: [String: Int] = [:]
        for dream in dreams {
            for tag in dream.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        let topTags = tagCounts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }

        let linked = dreams.compactMap { $0.session }
        let avgScore = linked.isEmpty ? nil : Double(linked.map(\.overallScore).reduce(0, +)) / Double(linked.count)

        return DreamJournalStats(
            total: total,
            lucidCount: lucid,
            nightmareCount: nightmares,
            avgClarity: clarity,
            emotionBreakdown: breakdown,
            topTags: topTags,
            linkedToSleepCount: linked.count,
            avgScoreWhenLinked: avgScore
        )
    }
}

/// Tags suggérés pour structurer le journal.
enum DreamTagSuggestions {
    static let common: [String] = [
        "Vol", "Chute", "Eau", "Dents", "Poursuite", "Ex-partenaire",
        "Famille", "Travail", "Maison", "Animal", "Mort", "Voyage",
        "École", "Nu", "Retard", "Bébé", "Feu", "Mer"
    ]
}
