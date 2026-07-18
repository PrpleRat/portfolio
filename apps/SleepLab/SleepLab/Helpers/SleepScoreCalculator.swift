import Foundation

/// Calcule le score de sommeil 0-100 selon la pondération du cahier des charges
enum SleepScoreCalculator {

    struct Input {
        var totalSleepMinutes: Int
        var timeInBedMinutes: Int
        var deepSleepMinutes: Int
        var remSleepMinutes: Int
        var awakeningsOver5Min: Int
        var targetSleepHours: Double
        var avgHRV: Double?
    }

    struct Result {
        var overall: Int
        var efficiency: Int
        var label: String
        var breakdown: [String: Int]
    }

    static func calculate(_ input: Input) -> Result {
        let targetMinutes = Int(input.targetSleepHours * 60)
        let total = max(1, input.totalSleepMinutes)
        let inBed = max(total, input.timeInBedMinutes)

        // Durée vs objectif (25 pts)
        let durationRatio = min(1.0, Double(total) / Double(max(1, targetMinutes)))
        let durationPts = Int(durationRatio * 25)

        // Sommeil profond 20-25% idéal (20 pts)
        let deepRatio = Double(input.deepSleepMinutes) / Double(total)
        let deepPts = scoreForIdealRatio(deepRatio, idealLow: 0.18, idealHigh: 0.28, maxPoints: 20)

        // REM 20-25% (20 pts)
        let remRatio = Double(input.remSleepMinutes) / Double(total)
        let remPts = scoreForIdealRatio(remRatio, idealLow: 0.18, idealHigh: 0.28, maxPoints: 20)

        // Efficacité (15 pts)
        let efficiency = Double(total) / Double(inBed)
        let efficiencyPts = Int(min(1, efficiency) * 15)
        let efficiencyScore = Int(efficiency * 100)

        // Continuité (10 pts) — pénalité par réveil > 5 min
        let continuityPts = max(0, 10 - input.awakeningsOver5Min * 2)

        // HRV (10 pts) si disponible — normalisation simple
        var hrvPts = 0
        if let hrv = input.avgHRV {
            let normalized = min(1, max(0, (hrv - 20) / 80))
            hrvPts = Int(normalized * 10)
        } else {
            hrvPts = 5 // neutre sans données
        }

        let overall = min(100, durationPts + deepPts + remPts + efficiencyPts + continuityPts + hrvPts)
        let label = labelForScore(overall)

        return Result(
            overall: overall,
            efficiency: efficiencyScore,
            label: label,
            breakdown: [
                "duration": durationPts,
                "deep": deepPts,
                "rem": remPts,
                "efficiency": efficiencyPts,
                "continuity": continuityPts,
                "hrv": hrvPts
            ]
        )
    }

    static func labelForScore(_ score: Int, kind: SleepSessionKind = .night) -> String {
        switch kind {
        case .nap:
            switch score {
            case 0...40: return "Sieste courte"
            case 41...60: return "Sieste correcte"
            case 61...80: return "Bonne sieste"
            default: return "Sieste réparatrice"
            }
        case .night:
            switch score {
            case 0...40: return "Mauvaise nuit"
            case 41...60: return "Nuit correcte"
            case 61...80: return "Bonne nuit"
            default: return "Excellente nuit"
            }
        }
    }

    private static func scoreForIdealRatio(
        _ ratio: Double,
        idealLow: Double,
        idealHigh: Double,
        maxPoints: Int
    ) -> Int {
        if ratio >= idealLow && ratio <= idealHigh { return maxPoints }
        if ratio < idealLow {
            return Int((ratio / idealLow) * Double(maxPoints))
        }
        let over = ratio - idealHigh
        let penalty = min(1, over / 0.15)
        return Int(Double(maxPoints) * (1 - penalty * 0.5))
    }

    static func apply(to session: SleepSession, profile: UserProfile?) {
        let end = session.endTime ?? Date()
        let totalMins = Int(end.timeIntervalSince(session.startTime) / 60)

        if session.kind == .nap {
            applyNapScore(to: session, totalMinutes: totalMins, profile: profile)
            return
        }

        let asleep = session.deepSleepMinutes + session.remSleepMinutes + session.lightSleepMinutes
        let input = Input(
            totalSleepMinutes: max(asleep, totalMins),
            timeInBedMinutes: totalMins,
            deepSleepMinutes: session.deepSleepMinutes,
            remSleepMinutes: session.remSleepMinutes,
            awakeningsOver5Min: session.awakenings,
            targetSleepHours: adjustedTargetSleepHours(profile: profile, session: session, fallback: 8),
            avgHRV: session.avgHRV
        )
        let result = calculate(input)
        session.overallScore = result.overall
        session.efficiencyScore = result.efficiency
    }

    /// Score sieste : durée vs objectif typique (20–90 min), sans exiger REM/profond.
    private static func applyNapScore(to session: SleepSession, totalMinutes: Int, profile: UserProfile?) {
        let targetMin = Int((profile?.targetSleepDuration ?? 8) > 6 ? 30 : 25)
        let idealMax = 90
        let mins = max(1, totalMinutes)

        let durationScore: Int
        if mins >= 15 && mins <= idealMax {
            durationScore = min(100, 55 + Int((Double(mins) / Double(targetMin)) * 25))
        } else if mins < 15 {
            durationScore = max(20, mins * 3)
        } else {
            durationScore = max(50, 85 - (mins - idealMax))
        }

        let efficiency = min(100, Int((Double(min(mins, idealMax)) / Double(mins)) * 100))
        session.overallScore = min(100, durationScore)
        session.efficiencyScore = efficiency
    }

    private static func adjustedTargetSleepHours(
        profile: UserProfile?,
        session: SleepSession,
        fallback: Double
    ) -> Double {
        guard let profile else { return fallback }
        let base = profile.targetSleepDuration + profile.biologicalSleepNeedAdjustmentHours
        guard profile.tracksMenstrualCycle else { return base }
        let referenceDate = session.endTime ?? session.actualWakeTime ?? session.startTime
        let cycleDay = session.cycleDay ?? profile.currentCycleDay(on: referenceDate)
        guard let cycleDay else { return base }
        switch profile.menstrualPhase(for: cycleDay) {
        case .menstrual:
            return base + 0.25
        case .luteal:
            return base + 0.5
        case .follicular, .ovulation:
            return base
        }
    }
}
