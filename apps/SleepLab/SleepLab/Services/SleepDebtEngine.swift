import Foundation

/// Dette de sommeil sur 7 nuits + objectif ajusté (cycle) et coucher conseillé.
enum SleepDebtEngine {
    static let rollingDays = 7
    /// Rattrapage réaliste par nuit (heures « en plus » utiles).
    static let maxRecoveryPerNightHours = 1.25

    enum DebtStatus: String {
        case surplus
        case balanced
        case mild
        case moderate
        case high

        var displayName: String {
            switch self {
            case .surplus: return "En avance"
            case .balanced: return "Équilibré"
            case .mild: return "Léger retard"
            case .moderate: return "Dette modérée"
            case .high: return "Dette élevée"
            }
        }

        var sfSymbol: String {
            switch self {
            case .surplus: return "checkmark.circle.fill"
            case .balanced: return "equal.circle.fill"
            case .mild: return "moon.zzz"
            case .moderate: return "exclamationmark.circle.fill"
            case .high: return "battery.25"
            }
        }
    }

    struct NightlyBalance: Identifiable {
        let id = UUID()
        let date: Date
        let sleptHours: Double
        let needHours: Double
        let balanceHours: Double
        let fragmentCount: Int
        let inertiaPenaltyHours: Double
    }

    struct SleepDebtReport {
        let netDebtHours: Double
        let grossDebtHours: Double
        let recoveryCreditHours: Double
        let baseTargetHours: Double
        let adjustedTargetHours: Double
        let cycleAdjustmentHours: Double
        let averageSleptHours7d: Double
        let recommendedBedtime: Date?
        let estimatedRecoveryNights: Int?
        let status: DebtStatus
        let nightlyBalances: [NightlyBalance]
        let summaryLine: String
        let detailLine: String
    }

    static func report(
        sessions: [SleepSession],
        profile: UserProfile?,
        now: Date = Date()
    ) -> SleepDebtReport {
        let baseTarget = (profile?.targetSleepDuration ?? 8) + (profile?.biologicalSleepNeedAdjustmentHours ?? 0)
        let cycleAdj = cycleAdjustmentHours(profile: profile, on: now)
        let adjustedTarget = baseTarget + cycleAdj

        let logicalNights = SleepNightGrouper.logicalNights(
            from: sessions,
            days: rollingDays,
            now: now
        )
        var grossDebt = 0.0
        var credit = 0.0
        var balances: [NightlyBalance] = []
        var sleptTotal = 0.0

        for night in logicalNights {
            let need = needHours(
                for: night.primarySession,
                profile: profile,
                defaultTarget: baseTarget
            )
            let slept = night.effectiveSleptHours
            sleptTotal += slept
            let balance = slept - need
            balances.append(NightlyBalance(
                date: night.wakeDay,
                sleptHours: slept,
                needHours: need,
                balanceHours: balance,
                fragmentCount: night.fragmentCount,
                inertiaPenaltyHours: night.inertiaPenaltyHours
            ))
            if balance < 0 {
                grossDebt += abs(balance)
            } else {
                credit += balance
            }
        }

        let netDebt = max(0, grossDebt - credit * 0.65)
        let avgSlept = logicalNights.isEmpty ? 0 : sleptTotal / Double(logicalNights.count)
        let status = classify(netDebt: netDebt, credit: credit, grossDebt: grossDebt)
        let recoveryNights: Int? = netDebt > 0.25
            ? Int(ceil(netDebt / maxRecoveryPerNightHours))
            : nil

        let bedtime = recommendedBedtime(
            profile: profile,
            netDebtHours: netDebt,
            now: now
        )

        let summary = summaryLine(netDebt: netDebt, status: status, recoveryNights: recoveryNights)
        let detail = detailLine(
            netDebt: netDebt,
            adjustedTarget: adjustedTarget,
            avgSlept: avgSlept,
            cycleAdj: cycleAdj,
            bedtime: bedtime,
            balances: balances
        )

        return SleepDebtReport(
            netDebtHours: netDebt,
            grossDebtHours: grossDebt,
            recoveryCreditHours: credit,
            baseTargetHours: baseTarget,
            adjustedTargetHours: adjustedTarget,
            cycleAdjustmentHours: cycleAdj,
            averageSleptHours7d: avgSlept,
            recommendedBedtime: bedtime,
            estimatedRecoveryNights: recoveryNights,
            status: status,
            nightlyBalances: balances.sorted { $0.date > $1.date },
            summaryLine: summary,
            detailLine: detail
        )
    }

    // MARK: - Calculs

    private static func needHours(
        for session: SleepSession,
        profile: UserProfile?,
        defaultTarget: Double
    ) -> Double {
        guard let profile, profile.tracksMenstrualCycle else {
            return defaultTarget
        }
        let referenceDate = session.endTime ?? session.actualWakeTime ?? session.startTime
        let day = session.cycleDay ?? profile.currentCycleDay(on: referenceDate)
        guard let day else { return defaultTarget }
        let phase = profile.menstrualPhase(for: day)
        return defaultTarget + phaseAdjustment(phase)
    }

    private static func cycleAdjustmentHours(profile: UserProfile?, on date: Date) -> Double {
        guard let profile, profile.tracksMenstrualCycle, let day = profile.currentCycleDay(on: date) else {
            return 0
        }
        return phaseAdjustment(profile.menstrualPhase(for: day))
    }

    private static func phaseAdjustment(_ phase: UserProfile.MenstrualPhase) -> Double {
        switch phase {
        case .menstrual: return 0.25
        case .luteal: return 0.5
        case .follicular, .ovulation: return 0
        }
    }

    private static func classify(netDebt: Double, credit: Double, grossDebt: Double) -> DebtStatus {
        if netDebt <= 0.25, credit > grossDebt, grossDebt < 0.5 {
            return .surplus
        }
        if netDebt <= 0.5 { return .balanced }
        if netDebt <= 2 { return .mild }
        if netDebt <= 5 { return .moderate }
        return .high
    }

    private static func recommendedBedtime(
        profile: UserProfile?,
        netDebtHours: Double,
        now: Date
    ) -> Date? {
        let cal = Calendar.current
        var base = profile?.targetBedtime ?? defaultBedtime(on: now)
        if netDebtHours > 0.5 {
            let advanceMinutes = Int(min(netDebtHours * 35, 90))
            base = cal.date(byAdding: .minute, value: -advanceMinutes, to: base) ?? base
        }
        if base <= now.addingTimeInterval(30 * 60) {
            base = cal.date(byAdding: .day, value: 1, to: base) ?? base
        }
        return base
    }

    private static func defaultBedtime(on date: Date) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        c.hour = 23
        c.minute = 0
        return Calendar.current.date(from: c) ?? date
    }

    private static func summaryLine(
        netDebt: Double,
        status: DebtStatus,
        recoveryNights: Int?
    ) -> String {
        if netDebt <= 0.25 {
            return "Tu es à jour sur ton sommeil."
        }
        let h = formatHours(netDebt)
        if let nights = recoveryNights, nights > 0 {
            return "Dette estimée : \(h) · rattrapage ~\(nights) nuit\(nights > 1 ? "s" : "")."
        }
        return "Dette estimée : \(h) (\(status.displayName.lowercased()))."
    }

    private static func detailLine(
        netDebt: Double,
        adjustedTarget: Double,
        avgSlept: Double,
        cycleAdj: Double,
        bedtime: Date?,
        balances: [NightlyBalance]
    ) -> String {
        var parts: [String] = []
        parts.append("Objectif \(formatHours(adjustedTarget))/nuit")
        if cycleAdj > 0 {
            parts.append("+\(formatHours(cycleAdj)) cycle")
        }
        parts.append("moy. \(formatHours(avgSlept)) sur 7 j (jours de réveil)")
        if let fragmented = balances.first(where: { $0.fragmentCount > 1 && $0.inertiaPenaltyHours > 0 }) {
            parts.append("inertie \(formatHours(fragmented.inertiaPenaltyHours))")
        }
        if netDebt > 0.5, let bedtime {
            parts.append("coucher conseillé \(bedtime.formatted(date: .omitted, time: .shortened))")
        }
        return parts.joined(separator: " · ")
    }

    static func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        if m == 0 { return "\(h) h" }
        return "\(h) h \(m)"
    }
}
