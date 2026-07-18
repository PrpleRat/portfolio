import Foundation

struct FactorImpact: Identifiable {
    let id = UUID()
    let factor: FactorType
    let correlation: Double
    let avgImpact: Double
    let insight: String
    let isPositive: Bool
}

struct CorrelationReport {
    let topPositive: [FactorImpact]
    let topNegative: [FactorImpact]
    let minimumNightsMet: Bool
}

enum SleepMetric: String, CaseIterable, Identifiable {
    case overallScore
    case durationHours
    case deepPercent
    case remPercent
    case efficiency
    case snoreMinutes
    case awakenings

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .overallScore: return "Score"
        case .durationHours: return "Durée"
        case .deepPercent: return "% profond"
        case .remPercent: return "% REM"
        case .efficiency: return "Efficacité"
        case .snoreMinutes: return "Ronflement (min)"
        case .awakenings: return "Réveils"
        }
    }
}

struct MetricFactorCorrelation: Identifiable {
    let id = UUID()
    let factor: FactorType
    let metric: SleepMetric
    let correlation: Double
    let insight: String
}

struct ExtendedCorrelationReport {
    let scoreReport: CorrelationReport
    let metricCorrelations: [MetricFactorCorrelation]
    let stressDurationLinks: [MetricFactorCorrelation]
    let minimumNightsMet: Bool
}

/// Corrélations Pearson entre facteurs attribués à chaque nuit et métriques de sommeil.
enum CorrelationEngine {
    static let minimumSessions = 7

    static func correlation(
        factor: FactorType,
        sessions: [SleepSession],
        allFactors: [SleepFactor] = []
    ) -> Double? {
        let pairs = dataPairs(factor: factor, sessions: sessions, allFactors: allFactors)
        guard pairs.count >= minimumSessions else { return nil }
        return pearson(pairs.map(\.0), pairs.map(\.1))
    }

    static func topImpacts(
        sessions: [SleepSession],
        allFactors: [SleepFactor] = []
    ) -> CorrelationReport {
        let nights = nightSessions(from: sessions)
        guard nights.count >= minimumSessions else {
            return CorrelationReport(topPositive: [], topNegative: [], minimumNightsMet: false)
        }

        var impacts: [FactorImpact] = []
        for factorType in FactorType.allCases {
            guard hasVariation(factor: factorType, sessions: nights, allFactors: allFactors) else { continue }
            guard let r = correlation(factor: factorType, sessions: nights, allFactors: allFactors) else { continue }
            let avg = averageImpact(factor: factorType, sessions: nights, allFactors: allFactors)
            let insight = generateInsight(factor: factorType, correlation: r, avgImpact: avg)
            impacts.append(FactorImpact(
                factor: factorType,
                correlation: r,
                avgImpact: avg,
                insight: insight,
                isPositive: r > 0
            ))
        }

        let positive = impacts.filter { $0.correlation > 0.15 }.sorted { $0.correlation > $1.correlation }.prefix(3)
        let negative = impacts.filter { $0.correlation < -0.15 }.sorted { $0.correlation < $1.correlation }.prefix(3)

        return CorrelationReport(
            topPositive: Array(positive),
            topNegative: Array(negative),
            minimumNightsMet: true
        )
    }

    static func extendedReport(
        sessions: [SleepSession],
        allFactors: [SleepFactor] = [],
        scoreReport: CorrelationReport? = nil
    ) -> ExtendedCorrelationReport {
        let nights = nightSessions(from: sessions)
        let scoreReport = scoreReport ?? topImpacts(sessions: sessions, allFactors: allFactors)
        guard nights.count >= minimumSessions else {
            return ExtendedCorrelationReport(
                scoreReport: scoreReport,
                metricCorrelations: [],
                stressDurationLinks: [],
                minimumNightsMet: false
            )
        }

        let priorityFactors: [FactorType] = [
            .caffeine, .alcohol, .nicotine, .cannabis, .melatonin, .lateEating,
            .exercise, .eveningIntenseExercise, .screenTime, .stressLevel, .anxietyLevel,
            .lateNap, .heavyMeal, .mindfulness, .roomTemperature, .partnerSnoring
        ]

        var metricLinks: [MetricFactorCorrelation] = []
        for factor in priorityFactors {
            for metric in SleepMetric.allCases {
                guard let r = metricCorrelation(factor: factor, metric: metric, sessions: nights, allFactors: allFactors),
                      abs(r) >= 0.2 else { continue }
                metricLinks.append(MetricFactorCorrelation(
                    factor: factor,
                    metric: metric,
                    correlation: r,
                    insight: metricInsight(factor: factor, metric: metric, correlation: r)
                ))
            }
        }

        let stressDuration = metricLinks.filter {
            ($0.factor == .stressLevel || $0.factor == .anxietyLevel) && $0.metric == .durationHours
        }

        return ExtendedCorrelationReport(
            scoreReport: scoreReport,
            metricCorrelations: Array(metricLinks.prefix(12)),
            stressDurationLinks: stressDuration,
            minimumNightsMet: true
        )
    }

    static func metricCorrelation(
        factor: FactorType,
        metric: SleepMetric,
        sessions: [SleepSession],
        allFactors: [SleepFactor] = []
    ) -> Double? {
        let pairs = metricPairs(factor: factor, metric: metric, sessions: sessions, allFactors: allFactors)
        guard pairs.count >= minimumSessions else { return nil }
        return pearson(pairs.map(\.0), pairs.map(\.1))
    }

    private static func nightSessions(from sessions: [SleepSession]) -> [SleepSession] {
        sessions.filter { $0.kind == .night && $0.endTime != nil }
    }

    private static func attributed(
        session: SleepSession,
        allFactors: [SleepFactor],
        nights: [SleepSession]
    ) -> [SleepFactor] {
        let idx = nights.firstIndex(where: { $0.id == session.id })
        let prevEnd = idx.flatMap { i in i > 0 ? nights[i - 1].endTime : nil }
        return SleepFactorAttribution.factors(for: session, allFactors: allFactors, previousSessionEnd: prevEnd)
    }

    private static func hasVariation(
        factor: FactorType,
        sessions: [SleepSession],
        allFactors: [SleepFactor]
    ) -> Bool {
        var withFactor = 0
        var without = 0
        for session in sessions {
            let total = attributed(session: session, allFactors: allFactors, nights: sessions)
                .filter { $0.type == factor }
                .map(\.value)
                .reduce(0, +)
            if total > 0 { withFactor += 1 } else { without += 1 }
        }
        return withFactor >= 2 && without >= 2
    }

    private static func metricPairs(
        factor: FactorType,
        metric: SleepMetric,
        sessions: [SleepSession],
        allFactors: [SleepFactor]
    ) -> [(Double, Double)] {
        let nights = nightSessions(from: sessions)
        return nights.compactMap { session in
            let value = attributed(session: session, allFactors: allFactors, nights: nights)
                .filter { $0.type == factor }
                .map(\.value)
                .reduce(0, +)
            guard value > 0, let y = metricValue(metric, session: session) else { return nil }
            return (value, y)
        }
    }

    private static func metricValue(_ metric: SleepMetric, session: SleepSession) -> Double? {
        switch metric {
        case .overallScore:
            return Double(session.overallScore)
        case .durationHours:
            guard session.totalDuration > 0 else { return nil }
            return session.totalDuration / 3600
        case .deepPercent:
            let total = session.deepSleepMinutes + session.lightSleepMinutes + session.remSleepMinutes
            guard total > 0 else { return nil }
            return Double(session.deepSleepMinutes) / Double(total) * 100
        case .remPercent:
            let total = session.deepSleepMinutes + session.lightSleepMinutes + session.remSleepMinutes
            guard total > 0 else { return nil }
            return Double(session.remSleepMinutes) / Double(total) * 100
        case .efficiency:
            return Double(session.efficiencyScore)
        case .snoreMinutes:
            return Double(session.snoringMinutes)
        case .awakenings:
            return Double(session.awakenings)
        }
    }

    static func metricInsight(factor: FactorType, metric: SleepMetric, correlation: Double) -> String {
        let dir = correlation < 0 ? "diminue" : "augmente"
        return "Quand \(factor.displayName.lowercased()) est présent, \(metric.displayName.lowercased()) \(dir) (r=\(String(format: "%.2f", correlation)))."
    }

    static func generateInsight(factor: FactorType, correlation: Double, avgImpact: Double) -> String {
        let pts = Int(abs(avgImpact))
        let direction = correlation < 0 ? "baisse" : "augmente"
        switch factor {
        case .caffeine:
            return "Quand tu consommes de la caféine avant cette nuit, ton score \(direction) d’environ \(pts) pts."
        case .alcohol:
            return "L’alcool dans la fenêtre de la nuit fait \(direction) ton score d’environ \(pts) pts."
        case .exercise:
            return "L’exercice dans la journée \(direction) ton score de \(pts) pts."
        case .stressLevel:
            return "Un stress élevé le soir \(direction) ton score de \(pts) pts."
        case .screenTime:
            return "Plus d’écran avant le coucher \(direction) ton score de \(pts) pts."
        default:
            return "\(factor.displayName) \(direction) ton score de sommeil de \(pts) pts en moyenne."
        }
    }

    private static func dataPairs(
        factor: FactorType,
        sessions: [SleepSession],
        allFactors: [SleepFactor]
    ) -> [(Double, Double)] {
        let nights = nightSessions(from: sessions)
        return nights.compactMap { session in
            let value = attributed(session: session, allFactors: allFactors, nights: nights)
                .filter { $0.type == factor }
                .map(\.value)
                .reduce(0, +)
            guard value > 0 else { return nil }
            return (value, Double(session.overallScore))
        }
    }

    private static func averageImpact(
        factor: FactorType,
        sessions: [SleepSession],
        allFactors: [SleepFactor]
    ) -> Double {
        let nights = nightSessions(from: sessions)
        let withFactor = nights.filter { session in
            attributed(session: session, allFactors: allFactors, nights: nights)
                .contains { $0.type == factor && $0.value > 0 }
        }
        let without = nights.filter { session in
            !attributed(session: session, allFactors: allFactors, nights: nights)
                .contains { $0.type == factor && $0.value > 0 }
        }
        guard withFactor.count >= 2, without.count >= 2 else { return 0 }
        let avgWith = withFactor.map { Double($0.overallScore) }.reduce(0, +) / Double(withFactor.count)
        let avgWithout = without.map { Double($0.overallScore) }.reduce(0, +) / Double(without.count)
        return avgWith - avgWithout
    }

    private static func pearson(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count, x.count > 1 else { return 0 }
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        let num = n * sumXY - sumX * sumY
        let den = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        guard den != 0 else { return 0 }
        return num / den
    }
}
