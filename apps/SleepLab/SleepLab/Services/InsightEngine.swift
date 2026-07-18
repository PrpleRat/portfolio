import Foundation
import SwiftData

/// Point pour graphiques dans une carte insight.
struct InsightChartPoint: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let value: Double
}

enum InsightChartKind: Equatable {
    case bar
    case line
}

/// Carte insight générée par le moteur.
struct InsightCard: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let confidence: Double
    let chartKind: InsightChartKind
    let chartData: [InsightChartPoint]
}

/// Corrélations sommeil × rêves × facteurs lifestyle (SleepFactor).
struct InsightEngine {
    static let minimumNights = 7

    static func build(
        sessions: [SleepSession],
        dreams: [DreamEntry]
    ) -> [InsightCard] {
        let completed = sessions.filter { $0.endTime != nil && $0.overallScore > 0 }
        guard completed.count >= minimumNights else { return [] }

        var cards: [InsightCard] = []
        if let c = dreamEmotionVsSleepScore(completed: completed, dreams: dreams) {
            cards.append(c)
        }
        if let c = nightmareRateAfterAlcohol(completed: completed, dreams: dreams) {
            cards.append(c)
        }
        if let c = dreamRecallVsBedtimeVariance(completed: completed, dreams: dreams) {
            cards.append(c)
        }
        return cards
    }

    static func hasEnoughData(sessions: [SleepSession]) -> Bool {
        sessions.filter { $0.endTime != nil && $0.overallScore > 0 }.count >= minimumNights
    }

    // MARK: - (1) Émotion rêve × score sommeil

    private static func dreamEmotionVsSleepScore(
        completed: [SleepSession],
        dreams: [DreamEntry]
    ) -> InsightCard? {
        var lowScores: [Double] = []
        var highScores: [Double] = []

        for session in completed {
            let sessionDreams = dreamsForNight(session, dreams: dreams)
            guard !sessionDreams.isEmpty else { continue }
            let avgEmotion = sessionDreams.map { averageEmotionScore($0) }.reduce(0, +) / Double(sessionDreams.count)
            if session.overallScore < 55 {
                lowScores.append(avgEmotion)
            } else {
                highScores.append(avgEmotion)
            }
        }

        guard lowScores.count >= 2, highScores.count >= 2 else { return nil }

        let lowAvg = lowScores.reduce(0, +) / Double(lowScores.count)
        let highAvg = highScores.reduce(0, +) / Double(highScores.count)
        let delta = highAvg - lowAvg
        let confidence = min(1, Double(min(lowScores.count, highScores.count)) / 10.0 + abs(delta) / 4.0)

        let desc: String
        if delta > 0.35 {
            desc = "Quand ton score est ≥ 55, tes rêves sont en moyenne plus positifs (+\(String(format: "%.1f", delta)) pts émotionnels vs nuits < 55)."
        } else if delta < -0.35 {
            desc = "Sur les nuits difficiles (< 55), tes rêves semblent paradoxalement plus intenses émotionnellement — peut-être du stress non digéré."
        } else {
            desc = "Peu d’écart émotionnel entre bonnes et mauvaises nuits — ton sommeil n’influence pas fortement la valence des rêves (pour l’instant)."
        }

        return InsightCard(
            id: "emotion_vs_score",
            title: "Rêves & qualité de sommeil",
            description: desc,
            confidence: confidence,
            chartKind: .bar,
            chartData: [
                InsightChartPoint(label: "Score < 55", value: lowAvg),
                InsightChartPoint(label: "Score ≥ 55", value: highAvg)
            ]
        )
    }

    // MARK: - (2) Cauchemars après alcool

    private static func nightmareRateAfterAlcohol(
        completed: [SleepSession],
        dreams: [DreamEntry]
    ) -> InsightCard? {
        var withAlcoholDreams = 0
        var withAlcoholNightmares = 0
        var withoutAlcoholDreams = 0
        var withoutAlcoholNightmares = 0

        for session in completed {
            let hadAlcohol = session.factors.contains { $0.type == .alcohol }
            let sessionDreams = dreamsForNight(session, dreams: dreams)
            for dream in sessionDreams {
                if hadAlcohol {
                    withAlcoholDreams += 1
                    if dream.category == .nightmare || dream.emotions.contains(.fear) || dream.emotions.contains(.anxiety) {
                        withAlcoholNightmares += 1
                    }
                } else {
                    withoutAlcoholDreams += 1
                    if dream.category == .nightmare || dream.emotions.contains(.fear) || dream.emotions.contains(.anxiety) {
                        withoutAlcoholNightmares += 1
                    }
                }
            }
        }

        guard withAlcoholDreams >= 2, withoutAlcoholDreams >= 2 else { return nil }

        let rateAlcohol = Double(withAlcoholNightmares) / Double(withAlcoholDreams)
        let rateClean = Double(withoutAlcoholNightmares) / Double(withoutAlcoholDreams)
        let lift = rateAlcohol - rateClean
        let confidence = min(1, Double(withAlcoholDreams) / 8.0 + abs(lift) * 2)

        return InsightCard(
            id: "alcohol_nightmare",
            title: "Alcool & cauchemars",
            description: "Après une soirée avec alcool : \(Int(rateAlcohol * 100)) % de rêves difficiles vs \(Int(rateClean * 100)) % sans alcool (\(lift > 0 ? "+" : "")\(Int(lift * 100)) pts).",
            confidence: confidence,
            chartKind: .bar,
            chartData: [
                InsightChartPoint(label: "Avec alcool", value: rateAlcohol * 100),
                InsightChartPoint(label: "Sans alcool", value: rateClean * 100)
            ]
        )
    }

    // MARK: - (3) Rappel de rêve × variance coucher

    private static func dreamRecallVsBedtimeVariance(
        completed: [SleepSession],
        dreams: [DreamEntry]
    ) -> InsightCard? {
        guard completed.count >= minimumNights else { return nil }

        let bedtimes = completed.map { bedtimeMinutes($0.startTime) }
        let mean = bedtimes.reduce(0, +) / bedtimes.count
        let variance = bedtimes.map { abs($0 - mean) }

        var stableRecall: [Double] = []
        var chaoticRecall: [Double] = []
        let medianVar = variance.sorted()[variance.count / 2]

        for (i, session) in completed.enumerated() {
            let recalled = dreamsForNight(session, dreams: dreams).isEmpty ? 0.0 : 1.0
            if variance[i] <= medianVar {
                stableRecall.append(recalled)
            } else {
                chaoticRecall.append(recalled)
            }
        }

        guard stableRecall.count >= 3, chaoticRecall.count >= 3 else { return nil }

        let stableRate = stableRecall.reduce(0, +) / Double(stableRecall.count)
        let chaoticRate = chaoticRecall.reduce(0, +) / Double(chaoticRecall.count)
        let confidence = min(1, Double(completed.count) / 14.0 + abs(chaoticRate - stableRate))

        return InsightCard(
            id: "bedtime_recall",
            title: "Régularité & rappel de rêve",
            description: "Rappel noté sur \(Int(stableRate * 100)) % des nuits à heure stable vs \(Int(chaoticRate * 100)) % quand l’heure de coucher varie beaucoup.",
            confidence: confidence,
            chartKind: .line,
            chartData: [
                InsightChartPoint(label: "Stable", value: stableRate * 100),
                InsightChartPoint(label: "Variable", value: chaoticRate * 100)
            ]
        )
    }

    // MARK: - Helpers

    private static func dreamsForNight(_ session: SleepSession, dreams: [DreamEntry]) -> [DreamEntry] {
        dreams.filter { dream in
            if let linked = dream.session, linked.id == session.id { return true }
            let nightEnd = session.endTime ?? session.startTime
            return abs(dream.dreamDate.timeIntervalSince(nightEnd)) < 18 * 3600
        }
    }

    private static func averageEmotionScore(_ dream: DreamEntry) -> Double {
        let emotions = dream.emotions.isEmpty ? (dream.primaryEmotion.map { [$0] } ?? []) : dream.emotions
        guard !emotions.isEmpty else { return 0 }
        let sum = emotions.map { emotionNumericScore($0) }.reduce(0, +)
        return sum / Double(emotions.count)
    }

    private static func emotionNumericScore(_ emotion: DreamEmotion) -> Double {
        switch emotion {
        case .joy: return 4
        case .peace: return 3.5
        case .love: return 4
        case .excitement: return 3
        case .surprise: return 1
        case .sadness: return -2
        case .fear: return -3.5
        case .anxiety: return -3
        case .anger: return -2.5
        case .disgust: return -2
        case .confusion: return -1
        case .shame: return -2.5
        }
    }

    private static func bedtimeMinutes(_ date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}
