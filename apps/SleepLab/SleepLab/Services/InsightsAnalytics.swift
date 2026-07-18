import Foundation

// MARK: - Modèles

struct NightlyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
}

struct NightlyScorePoint: Identifiable {
    let id = UUID()
    let date: Date
    let score: Int
}

struct NightlyDurationPoint: Identifiable {
    let id = UUID()
    let date: Date
    let hours: Double
}

struct WeekdayScore: Identifiable {
    let id = UUID()
    let weekday: Int
    let shortName: String
    let averageScore: Double
    let nightCount: Int
}

struct PhaseAverages {
    let deepPercent: Double
    let remPercent: Double
    let lightPercent: Double
    let avgDeepMinutes: Int
    let avgRemMinutes: Int
    let avgAwakenings: Double
}

struct NightlyPhaseBars: Identifiable {
    let id = UUID()
    let date: Date
    let deep: Double
    let rem: Double
    let light: Double
}

struct FactorUsageCount: Identifiable {
    let id = UUID()
    let factor: FactorType
    let count: Int
}

struct FactorComparison: Identifiable {
    let id = UUID()
    let factor: FactorType
    let avgWith: Double
    let avgWithout: Double
    let nightsWith: Int
    let nightsWithout: Int
    var delta: Double { avgWith - avgWithout }
}

struct HealthAverages {
    let avgHeartRate: Double?
    let avgHRV: Double?
    let avgSpO2: Double?
    let nightsWithData: Int
}

struct SoundInsights {
    let avgSnoringMinutes: Double
    let nightsWithSnoring: Int
    let totalSoundEvents: Int
    let topSoundType: SoundType?
}

struct CyclePhaseInsight: Identifiable {
    let id = UUID()
    let phaseName: String
    let averageScore: Double
    let count: Int
}

struct PersonalRecords {
    let bestScore: Int
    let bestScoreDate: Date?
    let longestHours: Double
    let longestDate: Date?
    let mostDeepMinutes: Int
    let mostDeepDate: Date?
}

struct OverviewStats {
    let totalNights: Int
    let avgScore7d: Double?
    let avgScore30d: Double?
    let avgScoreAll: Double
    let avgDurationHours: Double
    let avgEfficiency: Double
    let scoreTrendDelta7d: Double?
    let trackingStreak: Int
}

struct SleepInsightsDashboard {
    let overview: OverviewStats
    let scoreTrend: [NightlyScorePoint]
    let durationTrend: [NightlyDurationPoint]
    let weekdayScores: [WeekdayScore]
    let phaseAverages: PhaseAverages?
    let phaseBars: [NightlyPhaseBars]
    let health: HealthAverages?
    let sound: SoundInsights?
    let topFactors: [FactorUsageCount]
    let factorComparisons: [FactorComparison]
    let cyclePhases: [CyclePhaseInsight]
    let records: PersonalRecords?
    let tips: [String]
    let correlationReport: CorrelationReport
    let extendedCorrelations: ExtendedCorrelationReport
}

// MARK: - Calculs

enum InsightsAnalytics {
    static let correlationMinimum = 7
    static let chartNightLimit = 14

    static func emptyDashboard() -> SleepInsightsDashboard {
        let emptyReport = CorrelationReport(topPositive: [], topNegative: [], minimumNightsMet: false)
        return SleepInsightsDashboard(
            overview: OverviewStats(
                totalNights: 0,
                avgScore7d: nil,
                avgScore30d: nil,
                avgScoreAll: 0,
                avgDurationHours: 0,
                avgEfficiency: 0,
                scoreTrendDelta7d: nil,
                trackingStreak: 0
            ),
            scoreTrend: [],
            durationTrend: [],
            weekdayScores: [],
            phaseAverages: nil,
            phaseBars: [],
            health: nil,
            sound: nil,
            topFactors: [],
            factorComparisons: [],
            cyclePhases: [],
            records: nil,
            tips: [],
            correlationReport: emptyReport,
            extendedCorrelations: ExtendedCorrelationReport(
                scoreReport: emptyReport,
                metricCorrelations: [],
                stressDurationLinks: [],
                minimumNightsMet: false
            )
        )
    }

    static func build(from sessions: [SleepSession], allFactors: [SleepFactor] = []) -> SleepInsightsDashboard {
        let sorted = sessions.sorted { $0.startTime < $1.startTime }
        let recent = Array(sorted.suffix(chartNightLimit))
        let correlationReport = CorrelationEngine.topImpacts(sessions: sorted, allFactors: allFactors)

        return SleepInsightsDashboard(
            overview: overview(from: sorted),
            scoreTrend: scoreTrend(from: recent),
            durationTrend: durationTrend(from: recent),
            weekdayScores: weekdayScores(from: sorted),
            phaseAverages: sessionsWithMeasuredPhases(sorted).isEmpty
                ? nil
                : phaseAverages(from: sorted),
            phaseBars: phaseBars(from: recent),
            health: healthAverages(from: sorted),
            sound: soundInsights(from: sorted),
            topFactors: topFactorUsage(from: sorted, allFactors: allFactors, limit: 8),
            factorComparisons: keyComparisons(from: sorted, allFactors: allFactors),
            cyclePhases: cycleInsights(from: sorted),
            records: sorted.isEmpty ? nil : personalRecords(from: sorted),
            tips: generateTips(sessions: sorted, allFactors: allFactors),
            correlationReport: correlationReport,
            extendedCorrelations: CorrelationEngine.extendedReport(
                sessions: sorted,
                allFactors: allFactors,
                scoreReport: correlationReport
            )
        )
    }

    // MARK: Overview

    private static func overview(from sessions: [SleepSession]) -> OverviewStats {
        let now = Date()
        let last7 = sessions.filter { daysBetween($0.startTime, now) <= 7 }
        let last30 = sessions.filter { daysBetween($0.startTime, now) <= 30 }

        let avgAll = average(sessions.map { Double($0.overallScore) }) ?? 0
        let avg7 = average(last7.map { Double($0.overallScore) })
        let avg30 = average(last30.map { Double($0.overallScore) })

        var trendDelta: Double?
        if last7.count >= 3 {
            let half = last7.count / 2
            let older = Array(last7.prefix(last7.count - half))
            let newer = Array(last7.suffix(half))
            if let o = average(older.map { Double($0.overallScore) }),
               let n = average(newer.map { Double($0.overallScore) }) {
                trendDelta = n - o
            }
        }

        return OverviewStats(
            totalNights: sessions.count,
            avgScore7d: avg7,
            avgScore30d: avg30,
            avgScoreAll: avgAll,
            avgDurationHours: average(sessions.map { $0.totalDuration / 3600 }) ?? 0,
            avgEfficiency: average(sessions.map { Double($0.efficiencyScore) }) ?? 0,
            scoreTrendDelta7d: trendDelta,
            trackingStreak: trackingStreak(sessions)
        )
    }

    private static func trackingStreak(_ sessions: [SleepSession]) -> Int {
        guard !sessions.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 0
        var day = calendar.startOfDay(for: Date())
        let nights = Set(sessions.map { calendar.startOfDay(for: $0.startTime) })
        while nights.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    // MARK: Trends

    private static func scoreTrend(from sessions: [SleepSession]) -> [NightlyScorePoint] {
        sessions.map { NightlyScorePoint(date: $0.startTime, score: $0.overallScore) }
    }

    private static func durationTrend(from sessions: [SleepSession]) -> [NightlyDurationPoint] {
        sessions.map { NightlyDurationPoint(date: $0.startTime, hours: $0.totalDuration / 3600) }
    }

    private static func weekdayScores(from sessions: [SleepSession]) -> [WeekdayScore] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        let symbols = formatter.shortWeekdaySymbols ?? []

        return (1...7).compactMap { weekday -> WeekdayScore? in
            let matching = sessions.filter {
                Calendar.current.component(.weekday, from: $0.startTime) == weekday
            }
            guard !matching.isEmpty else { return nil }
            let avg = average(matching.map { Double($0.overallScore) }) ?? 0
            let name = symbols.indices.contains(weekday - 1) ? symbols[weekday - 1] : "?"
            return WeekdayScore(weekday: weekday, shortName: name.capitalized, averageScore: avg, nightCount: matching.count)
        }
    }

    // MARK: Phases

    private static func sessionsWithMeasuredPhases(_ sessions: [SleepSession]) -> [SleepSession] {
        sessions.filter { session in
            !session.isManuallyEntered && !SleepPhaseTheoreticalEstimate.lacksMeasuredPhases(session)
        }
    }

    private static func phaseAverages(from sessions: [SleepSession]) -> PhaseAverages {
        let measured = sessionsWithMeasuredPhases(sessions)
        var deepP: [Double] = []
        var remP: [Double] = []
        var lightP: [Double] = []
        var deepM: [Int] = []
        var remM: [Int] = []
        var awake: [Double] = []

        for s in measured {
            let total = max(1, s.deepSleepMinutes + s.remSleepMinutes + s.lightSleepMinutes)
            deepP.append(Double(s.deepSleepMinutes) / Double(total) * 100)
            remP.append(Double(s.remSleepMinutes) / Double(total) * 100)
            lightP.append(Double(s.lightSleepMinutes) / Double(total) * 100)
            deepM.append(s.deepSleepMinutes)
            remM.append(s.remSleepMinutes)
            awake.append(Double(s.awakenings))
        }

        return PhaseAverages(
            deepPercent: average(deepP) ?? 0,
            remPercent: average(remP) ?? 0,
            lightPercent: average(lightP) ?? 0,
            avgDeepMinutes: Int(average(deepM.map(Double.init)) ?? 0),
            avgRemMinutes: Int(average(remM.map(Double.init)) ?? 0),
            avgAwakenings: average(awake) ?? 0
        )
    }

    private static func phaseBars(from sessions: [SleepSession]) -> [NightlyPhaseBars] {
        sessionsWithMeasuredPhases(sessions).map { s in
            let total = max(1.0, Double(s.deepSleepMinutes + s.remSleepMinutes + s.lightSleepMinutes))
            return NightlyPhaseBars(
                date: s.startTime,
                deep: Double(s.deepSleepMinutes) / total * 100,
                rem: Double(s.remSleepMinutes) / total * 100,
                light: Double(s.lightSleepMinutes) / total * 100
            )
        }
    }

    // MARK: Health & sound

    private static func healthAverages(from sessions: [SleepSession]) -> HealthAverages? {
        let withHR = sessions.compactMap { $0.avgHeartRate }
        let withHRV = sessions.compactMap { $0.avgHRV }
        let withSpO2 = sessions.compactMap { $0.avgSPO2 }
        guard !withHR.isEmpty || !withHRV.isEmpty else { return nil }
        return HealthAverages(
            avgHeartRate: average(withHR),
            avgHRV: average(withHRV),
            avgSpO2: average(withSpO2),
            nightsWithData: max(withHR.count, withHRV.count)
        )
    }

    private static func soundInsights(from sessions: [SleepSession]) -> SoundInsights? {
        guard sessions.contains(where: { $0.snoringMinutes > 0 || !$0.soundEvents.isEmpty }) else { return nil }
        let snoring = sessions.map { Double($0.snoringMinutes) }
        let events = sessions.reduce(0) { $0 + $1.soundEvents.count }
        var typeCounts: [SoundType: Int] = [:]
        for s in sessions {
            for e in s.soundEvents {
                typeCounts[e.soundType, default: 0] += 1
            }
        }
        let top = typeCounts.max(by: { $0.value < $1.value })?.key
        return SoundInsights(
            avgSnoringMinutes: average(snoring) ?? 0,
            nightsWithSnoring: sessions.filter { $0.snoringMinutes > 0 }.count,
            totalSoundEvents: events,
            topSoundType: top
        )
    }

    // MARK: Facteurs

    private static func topFactorUsage(
        from sessions: [SleepSession],
        allFactors: [SleepFactor],
        limit: Int
    ) -> [FactorUsageCount] {
        var counts: [FactorType: Int] = [:]
        let nights = sessions.filter { $0.kind == .night && $0.endTime != nil }
        for s in nights {
            for f in SleepFactorAttribution.factors(for: s, allFactors: allFactors) {
                counts[f.type, default: 0] += 1
            }
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { FactorUsageCount(factor: $0.key, count: $0.value) }
    }

    private static func keyComparisons(
        from sessions: [SleepSession],
        allFactors: [SleepFactor]
    ) -> [FactorComparison] {
        let keys: [FactorType] = [
            .caffeine, .alcohol, .exercise, .screenTime, .stressLevel,
            .lateNap, .eveningIntenseExercise, .melatonin
        ]
        return keys.compactMap { compare(factor: $0, sessions: sessions, allFactors: allFactors) }
            .filter { $0.nightsWith >= 2 && $0.nightsWithout >= 2 }
            .sorted { abs($0.delta) > abs($1.delta) }
            .prefix(5)
            .map { $0 }
    }

    private static func compare(
        factor: FactorType,
        sessions: [SleepSession],
        allFactors: [SleepFactor]
    ) -> FactorComparison? {
        let nights = sessions.filter { $0.kind == .night && $0.endTime != nil }
        let withF = nights.filter { session in
            SleepFactorAttribution.factors(for: session, allFactors: allFactors)
                .contains { $0.type == factor && $0.value > 0 }
        }
        let without = nights.filter { session in
            !SleepFactorAttribution.factors(for: session, allFactors: allFactors)
                .contains { $0.type == factor && $0.value > 0 }
        }
        guard !withF.isEmpty, !without.isEmpty else { return nil }
        return FactorComparison(
            factor: factor,
            avgWith: average(withF.map { Double($0.overallScore) }) ?? 0,
            avgWithout: average(without.map { Double($0.overallScore) }) ?? 0,
            nightsWith: withF.count,
            nightsWithout: without.count
        )
    }

    private static func cycleInsights(from sessions: [SleepSession]) -> [CyclePhaseInsight] {
        let withCycle = sessions.filter { $0.cycleDay != nil }
        guard withCycle.count >= 3 else { return [] }

        var buckets: [UserProfile.MenstrualPhase: [Int]] = [:]
        for s in sessions {
            guard let day = s.cycleDay else { continue }
            let phase = UserProfile().menstrualPhase(for: day)
            buckets[phase, default: []].append(s.overallScore)
        }
        return buckets.map { phase, scores in
            CyclePhaseInsight(
                phaseName: phase.displayName,
                averageScore: average(scores.map(Double.init)) ?? 0,
                count: scores.count
            )
        }.sorted { $0.averageScore > $1.averageScore }
    }

    private static func personalRecords(from sessions: [SleepSession]) -> PersonalRecords {
        let best = sessions.max(by: { $0.overallScore < $1.overallScore })
        let longest = sessions.max(by: { $0.totalDuration < $1.totalDuration })
        let deep = sessions.max(by: { $0.deepSleepMinutes < $1.deepSleepMinutes })
        return PersonalRecords(
            bestScore: best?.overallScore ?? 0,
            bestScoreDate: best?.startTime,
            longestHours: (longest?.totalDuration ?? 0) / 3600,
            longestDate: longest?.startTime,
            mostDeepMinutes: deep?.deepSleepMinutes ?? 0,
            mostDeepDate: deep?.startTime
        )
    }

    // MARK: Conseils auto

    private static func generateTips(sessions: [SleepSession], allFactors: [SleepFactor]) -> [String] {
        guard sessions.count >= 3 else {
            return ["Continue à enregistrer tes nuits — les tendances apparaissent vite après 3–4 nuits."]
        }
        var tips: [String] = []
        let overview = overview(from: sessions)

        if let delta = overview.scoreTrendDelta7d {
            if delta >= 5 {
                tips.append("Ton score moyen progresse de \(Int(delta)) pts sur la dernière semaine — continue ce qui marche.")
            } else if delta <= -5 {
                tips.append("Ton score baisse de \(Int(abs(delta))) pts cette semaine — regarde les facteurs « Comparaisons » ci-dessous.")
            }
        }

        if let weekdays = weekdayScores(from: sessions).max(by: { $0.averageScore < $1.averageScore }),
           let worst = weekdayScores(from: sessions).min(by: { $0.averageScore < $1.averageScore }),
           weekdays.nightCount >= 2, worst.nightCount >= 2, weekdays.averageScore - worst.averageScore >= 8 {
            tips.append("Tu dors mieux le \(weekdays.shortName) (+\(Int(weekdays.averageScore - worst.averageScore)) pts vs \(worst.shortName)).")
        }

        let phases = phaseAverages(from: sessions)
        if phases.deepPercent < 15 {
            tips.append("Sommeil profond faible (\(Int(phases.deepPercent)) %) — chambre plus fraîche (18–19 °C) et horaires réguliers peuvent aider.")
        }
        if phases.avgAwakenings >= 2 {
            tips.append("En moyenne \(String(format: "%.1f", phases.avgAwakenings)) réveils > 5 min par nuit — limite alcool et écrans le soir.")
        }

        if let cafe = compare(factor: .caffeine, sessions: sessions, allFactors: allFactors), cafe.delta <= -8 {
            tips.append("Les nuits avec caféine coïncident avec un score plus bas de \(Int(abs(cafe.delta))) pts en moyenne.")
        }

        if tips.isEmpty {
            tips.append("Tes habitudes sont stables — utilise les corrélations pour affiner ce qui te convient.")
        }
        return Array(tips.prefix(4))
    }

    // MARK: Helpers

    private static func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func daysBetween(_ from: Date, _ to: Date) -> Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: from), to: Calendar.current.startOfDay(for: to)).day ?? 0
    }
}
