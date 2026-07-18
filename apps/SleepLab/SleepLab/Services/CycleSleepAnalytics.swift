import Foundation

/// Scores de sommeil comparés par phase du cycle (sur plusieurs cycles).
enum CycleSleepAnalytics {
    struct PhaseSleepStats: Identifiable {
        let id = UUID()
        let phase: CyclePhase
        let averageScore: Double
        let nightCount: Int
        let averageDurationHours: Double
    }

    struct PhaseComparison {
        let stats: [PhaseSleepStats]
        let cycleCount: Int
        let insight: String
    }

    static func compare(
        sessions: [SleepSession],
        profile: UserProfile?
    ) -> PhaseComparison? {
        guard let profile, profile.tracksMenstrualCycle else { return nil }

        let nights = SleepNightGrouper.logicalNights(from: sessions.filter { $0.kind == .night })
        guard nights.count >= 6 else { return nil }

        var byPhase: [CyclePhase: [(score: Int, duration: TimeInterval)]] = [:]

        for night in nights {
            let ref = night.primarySession.endTime ?? night.primarySession.startTime
            guard let day = profile.currentCycleDay(on: ref) else { continue }
            let phase = CyclePhase.from(cycleDay: day, cycleLength: profile.averageCycleLength)
            byPhase[phase, default: []].append((night.primarySession.overallScore, night.primarySession.totalDuration))
        }

        let phases: [CyclePhase] = [.follicular, .ovulatory, .luteal, .menstrual]
        let stats = phases.compactMap { phase -> PhaseSleepStats? in
            guard let rows = byPhase[phase], !rows.isEmpty else { return nil }
            let avgScore = Double(rows.map(\.score).reduce(0, +)) / Double(rows.count)
            let avgDur = rows.map(\.duration).reduce(0, +) / Double(rows.count) / 3600
            return PhaseSleepStats(
                phase: phase,
                averageScore: avgScore,
                nightCount: rows.count,
                averageDurationHours: avgDur
            )
        }

        guard stats.count >= 2 else { return nil }

        let estimatedCycles = max(1, nights.count / max(1, profile.averageCycleLength / 7))

        var insight = "Comparaison sur \(nights.count) nuits."
        if let best = stats.max(by: { $0.averageScore < $1.averageScore }),
           let worst = stats.min(by: { $0.averageScore < $1.averageScore }),
           best.phase != worst.phase {
            insight = "Meilleur score en \(best.phase.displayName.lowercased()) (\(Int(best.averageScore))), plus fragile en \(worst.phase.displayName.lowercased()) (\(Int(worst.averageScore)))."
        }

        return PhaseComparison(stats: stats, cycleCount: estimatedCycles, insight: insight)
    }
}
