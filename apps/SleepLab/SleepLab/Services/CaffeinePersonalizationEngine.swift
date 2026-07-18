import Foundation

/// Apprend un seuil caféine personnel à partir des scores de nuit.
enum CaffeinePersonalizationEngine {
    struct CaffeineInsight {
        let cutoffHour: Int
        let averageScoreDrop: Double
        let sampleCount: Int
        let message: String
    }

    static let defaultCutoffHour = 14

    static func suggestedCutoffHour(
        factors: [SleepFactor],
        sessions: [SleepSession]
    ) -> Int {
        insight(factors: factors, sessions: sessions)?.cutoffHour ?? defaultCutoffHour
    }

    static func insight(
        factors: [SleepFactor],
        sessions: [SleepSession]
    ) -> CaffeineInsight? {
        let nights = SleepNightGrouper.logicalNights(from: sessions.filter { $0.kind == .night })
        guard nights.count >= 5 else { return nil }

        var dropsByHour: [Int: [Double]] = [:]
        let recent = Array(nights.suffix(30))
        for index in recent.indices {
            let night = recent[index]
            let score = Double(night.primarySession.overallScore)
            let bedtime = night.primarySession.startTime
            let prevEnd = index > 0 ? recent[index - 1].primarySession.endTime : nil
            let attributed = SleepFactorAttribution.factors(
                for: night.primarySession,
                allFactors: factors,
                previousSessionEnd: prevEnd
            )
            let caffeineBeforeBed = attributed.filter { $0.type == .caffeine && $0.consumedAt <= bedtime }
            guard !caffeineBeforeBed.isEmpty else { continue }

            let baseline = nights
                .filter { $0.wakeDay < night.wakeDay }
                .suffix(10)
                .map { Double($0.primarySession.overallScore) }
            let baselineAvg = baseline.isEmpty ? score : baseline.reduce(0, +) / Double(baseline.count)

            for factor in caffeineBeforeBed {
                let h = Calendar.current.component(.hour, from: factor.consumedAt)
                dropsByHour[h, default: []].append(baselineAvg - score)
            }
        }

        guard !dropsByHour.isEmpty else { return nil }

        var bestHour = defaultCutoffHour
        var bestDrop = 0.0
        var bestCount = 0

        for hour in 12...18 {
            let drops = (hour...23).flatMap { dropsByHour[$0] ?? [] }
            guard drops.count >= 3 else { continue }
            let avg = drops.reduce(0, +) / Double(drops.count)
            if avg > bestDrop {
                bestDrop = avg
                bestHour = hour
                bestCount = drops.count
            }
        }

        guard bestDrop > 2 else { return nil }

        let message = "Après \(bestHour)h, ton score baisse d’environ \(Int(bestDrop.rounded())) pts en moyenne (\(bestCount) nuits)."
        return CaffeineInsight(
            cutoffHour: bestHour,
            averageScoreDrop: bestDrop,
            sampleCount: bestCount,
            message: message
        )
    }
}
