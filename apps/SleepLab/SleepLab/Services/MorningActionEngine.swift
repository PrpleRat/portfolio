import Foundation

/// Une action concrète le matin, basée sur la dernière nuit, la dette et les corrélations locales.
enum MorningActionEngine {
    struct MorningAction {
        let headline: String
        let instruction: String
        let rationale: String
        let sfSymbol: String
    }

    private struct Candidate {
        let score: Int
        let action: MorningAction
    }

    static func action(
        for lastSession: SleepSession,
        sessions: [SleepSession],
        profile: UserProfile?,
        recentFactors: [SleepFactor] = [],
        now: Date = Date()
    ) -> MorningAction {
        let completed = sessions.filter { $0.endTime != nil && $0.kind == .night && $0.overallScore > 0 }
        let debt = SleepDebtEngine.report(sessions: sessions, profile: profile, now: now)
        let factorsForNight = factorsLinked(to: lastSession, recentFactors: recentFactors)

        var candidates: [Candidate] = []

        if lastSession.kind == .night {
            candidates.append(contentsOf: debtActions(debt: debt))
            candidates.append(contentsOf: lastNightFactorActions(
                session: lastSession,
                factors: factorsForNight,
                completed: completed,
                allFactors: recentFactors
            ))
            candidates.append(contentsOf: correlationActions(completed: completed, allFactors: recentFactors))
            candidates.append(contentsOf: sessionQualityActions(session: lastSession, completed: completed))
            candidates.append(contentsOf: cycleActions(profile: profile, session: lastSession))
        }

        if let best = candidates.max(by: { $0.score < $1.score }) {
            return best.action
        }

        return fallback(session: lastSession, debt: debt)
    }

    // MARK: - Candidats

    private static func debtActions(debt: SleepDebtEngine.SleepDebtReport) -> [Candidate] {
        guard debt.netDebtHours > 1 else { return [] }
        let advance = debt.netDebtHours > 3 ? "60–90" : "30–45"
        var instruction = "Ce soir, avance ton coucher de \(advance) minutes."
        if let bed = debt.recommendedBedtime {
            instruction = "Ce soir, vise un coucher vers \(bed.formatted(date: .omitted, time: .shortened))."
        }
        let nights = debt.estimatedRecoveryNights.map { "~\($0) nuit\($0 > 1 ? "s" : "") pour équilibrer" } ?? ""
        return [Candidate(
            score: debt.netDebtHours > 3 ? 95 : 80,
            action: MorningAction(
                headline: "Rattraper ta dette",
                instruction: instruction,
                rationale: "Tu as accumulé \(SleepDebtEngine.formatHours(debt.netDebtHours)) de dette sur 7 jours. \(nights)",
                sfSymbol: "bed.double.fill"
            )
        )]
    }

    private static func lastNightFactorActions(
        session: SleepSession,
        factors: [SleepFactor],
        completed: [SleepSession],
        allFactors: [SleepFactor]
    ) -> [Candidate] {
        var out: [Candidate] = []
        let cal = Calendar.current

        if factors.contains(where: { $0.type == .alcohol }) {
            if let cmp = factorComparison(.alcohol, sessions: completed, allFactors: allFactors), cmp.delta <= -5 {
                out.append(Candidate(
                    score: 88,
                    action: MorningAction(
                        headline: "Alcool hier",
                        instruction: "Ce soir, pas d’alcool après 20h (ou coupe complètement).",
                        rationale: "Avec alcool, ton score baisse en moyenne de \(Int(abs(cmp.delta))) pts sur tes nuits enregistrées.",
                        sfSymbol: "wineglass.fill"
                    )
                ))
            } else {
                out.append(Candidate(
                    score: 72,
                    action: MorningAction(
                        headline: "Alcool hier",
                        instruction: "Évite l’alcool ce soir pour voir si ton sommeil s’améliore.",
                        rationale: "Tu as noté de l’alcool avant cette nuit (score \(session.overallScore)).",
                        sfSymbol: "wineglass.fill"
                    )
                ))
            }
        }

        let lateCaffeine = factors.filter {
            $0.type == .caffeine || $0.type == .energyDrink || $0.type == .theanine
        }.filter { cal.component(.hour, from: $0.consumedAt) >= 15 }

        if !lateCaffeine.isEmpty {
            if let cmp = factorComparison(.caffeine, sessions: completed, allFactors: allFactors), cmp.delta <= -5 {
                out.append(Candidate(
                    score: 85,
                    action: MorningAction(
                        headline: "Caféine tardive",
                        instruction: "Pas de caféine après 14h aujourd’hui.",
                        rationale: "Tes nuits avec caféine tardive ont un score plus bas de \(Int(abs(cmp.delta))) pts en moyenne.",
                        sfSymbol: "cup.and.saucer.fill"
                    )
                ))
            } else {
                out.append(Candidate(
                    score: 70,
                    action: MorningAction(
                        headline: "Caféine tardive",
                        instruction: "Coupe caféine et energy drinks après 14h.",
                        rationale: "Tu as consommé de la caféine tard hier — souvent lié à un sommeil plus léger.",
                        sfSymbol: "cup.and.saucer.fill"
                    )
                ))
            }
        }

        if factors.contains(where: { $0.type == .screenTime || $0.type == .brightLightEvening }) {
            out.append(Candidate(
                score: 68,
                action: MorningAction(
                    headline: "Écrans hier soir",
                    instruction: "Ce soir, écrans off 60 min avant le coucher (livre ou audio calme).",
                    rationale: "Tu as noté écran / lumière vive — ça retarde l’endormissement chez beaucoup de monde.",
                    sfSymbol: "iphone.slash"
                )
            ))
        }

        if let stress = factors.first(where: { $0.type == .stressLevel || $0.type == .anxietyLevel }),
           stress.value >= 3 {
            out.append(Candidate(
                score: 65,
                action: MorningAction(
                    headline: "Stress élevé",
                    instruction: "Bloc 10 min de respiration ou marche lente avant de te coucher.",
                    rationale: "Stress noté à \(Int(stress.value))/5 avant la nuit — priorité décompression ce soir.",
                    sfSymbol: "brain.head.profile"
                )
            ))
        }

        return out
    }

    private static func correlationActions(completed: [SleepSession], allFactors: [SleepFactor]) -> [Candidate] {
        guard completed.count >= 7 else { return [] }
        let report = CorrelationEngine.topImpacts(sessions: completed, allFactors: allFactors)
        guard let top = report.topNegative.first, abs(top.avgImpact) >= 4 else { return [] }

        return [Candidate(
            score: 75,
            action: MorningAction(
                headline: "Levier #1",
                instruction: instructionFor(factor: top.factor),
                rationale: top.insight,
                sfSymbol: top.factor.sfSymbol
            )
        )]
    }

    private static func sessionQualityActions(
        session: SleepSession,
        completed: [SleepSession]
    ) -> [Candidate] {
        var out: [Candidate] = []
        let recent = completed.suffix(7)
        let avgScore = recent.isEmpty ? 0 : Double(recent.map(\.overallScore).reduce(0, +)) / Double(recent.count)

        if Double(session.overallScore) < avgScore - 10, avgScore > 0 {
            out.append(Candidate(
                score: 60,
                action: MorningAction(
                    headline: "Nuit en dessous de ta moyenne",
                    instruction: "Garde les mêmes horaires ce soir (±30 min max).",
                    rationale: "Score \(session.overallScore) vs moyenne \(Int(avgScore)) sur 7 jours — la régularité aide à remonter.",
                    sfSymbol: "clock.fill"
                )
            ))
        }

        let totalPhase = session.deepSleepMinutes + session.lightSleepMinutes + session.remSleepMinutes
        if totalPhase > 30 {
            let deepPct = Double(session.deepSleepMinutes) / Double(totalPhase) * 100
            if deepPct < 12 {
                out.append(Candidate(
                    score: 58,
                    action: MorningAction(
                        headline: "Peu de profond",
                        instruction: "Chambre plus fraîche (18–19 °C) et coucher à heure fixe ce soir.",
                        rationale: "Seulement \(Int(deepPct)) % de profond cette nuit — température et régularité aident souvent.",
                        sfSymbol: "thermometer.medium"
                    )
                ))
            }
        }

        if session.snoringMinutes >= 25 || session.snorePercentOfNight > 15 {
            out.append(Candidate(
                score: 55,
                action: MorningAction(
                    headline: "Ronflement marqué",
                    instruction: "Dors sur le côté ce soir ; évite alcool et repas tardifs.",
                    rationale: "\(session.snoringMinutes) min de ronflement détectées — position et alimentation changent souvent la donne.",
                    sfSymbol: "waveform.path"
                )
            ))
        }

        return out
    }

    private static func cycleActions(profile: UserProfile?, session: SleepSession) -> [Candidate] {
        guard let profile, profile.tracksMenstrualCycle, let day = session.cycleDay ?? profile.currentCycleDay() else {
            return []
        }
        let phase = profile.menstrualPhase(for: day)
        guard phase == .luteal || phase == .menstrual else { return [] }

        return [Candidate(
            score: 52,
            action: MorningAction(
                headline: "Phase \(phase.displayName)",
                instruction: "Prévois +30 min de sommeil ce soir et couche-toi sans écran.",
                rationale: "En phase \(phase.displayName.lowercased()), le besoin de sommeil augmente souvent — sois indulgent avec ton horaire.",
                sfSymbol: "circle.dotted"
            )
        )]
    }

    private static func fallback(
        session: SleepSession,
        debt: SleepDebtEngine.SleepDebtReport
    ) -> MorningAction {
        if session.overallScore >= 80 {
            return MorningAction(
                headline: "Belle nuit",
                instruction: "Garde le même rituel du soir ce soir.",
                rationale: "Score \(session.overallScore) — répéter ce qui a marché est le meilleur levier.",
                sfSymbol: "sparkles"
            )
        }
        return MorningAction(
            headline: "Routine ce soir",
            instruction: "Note caféine et écrans dans le journal dès que ça arrive.",
            rationale: debt.detailLine,
            sfSymbol: "list.bullet.clipboard"
        )
    }

    // MARK: - Helpers

    private static func factorsLinked(to session: SleepSession, recentFactors: [SleepFactor]) -> [SleepFactor] {
        SleepFactorAttribution.factors(for: session, allFactors: recentFactors)
    }

    private static func factorComparison(
        _ factor: FactorType,
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
        guard withF.count >= 2, without.count >= 2 else { return nil }
        let avgWith = Double(withF.map(\.overallScore).reduce(0, +)) / Double(withF.count)
        let avgWithout = Double(without.map(\.overallScore).reduce(0, +)) / Double(without.count)
        return FactorComparison(
            factor: factor,
            avgWith: avgWith,
            avgWithout: avgWithout,
            nightsWith: withF.count,
            nightsWithout: without.count
        )
    }

    private static func instructionFor(factor: FactorType) -> String {
        switch factor {
        case .caffeine, .energyDrink, .theanine, .chocolate:
            return "Pas de caféine après 14h aujourd’hui."
        case .alcohol:
            return "Pas d’alcool ce soir (ou avant 20h au plus tard)."
        case .screenTime, .brightLightEvening:
            return "Écrans off 60 min avant le coucher."
        case .eveningIntenseExercise, .exercise:
            return "Pas de sport intense après 19h."
        case .lateEating, .heavyMeal, .spicyMeal:
            return "Dîner léger, fini 3 h avant le coucher."
        case .stressLevel, .anxietyLevel, .rumination:
            return "10 min de respiration ou journal avant de dormir."
        case .lateNap:
            return "Pas de sieste après 15h aujourd’hui."
        case .nicotine, .vapingNicotine:
            return "Évite nicotine/vape en soirée."
        default:
            return "Réduis \(factor.displayName.lowercased()) ce soir et observe demain."
        }
    }
}
