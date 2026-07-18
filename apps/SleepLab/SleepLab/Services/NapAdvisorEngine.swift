import Foundation

/// Recommandations de sieste : durée, heure de réveil, effets énergie / inertie.
enum NapAdvisorEngine {
    enum NapKind: String, CaseIterable, Identifiable {
        case power
        case recovery
        case fullCycle

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .power: return "Sieste éclair"
            case .recovery: return "Sieste récup"
            case .fullCycle: return "Cycle complet"
            }
        }

        var durationMinutes: Int {
            switch self {
            case .power: return 20
            case .recovery: return 26
            case .fullCycle: return 90
            }
        }

        var icon: String {
            switch self {
            case .power: return "bolt.fill"
            case .recovery: return "leaf.fill"
            case .fullCycle: return "moon.zzz.fill"
            }
        }
    }

    struct NapPlan: Identifiable {
        let id = UUID()
        let kind: NapKind
        let durationMinutes: Int
        let recommendedWakeTime: Date
        let energyGainLabel: String
        let inertiaRiskLabel: String
        let inertiaMinutes: Int
        let tip: String
    }

    static func plans(now: Date = Date(), chronotype: Chronotype = .neutral) -> [NapPlan] {
        NapKind.allCases.map { kind in
            plan(for: kind, now: now, chronotype: chronotype)
        }
    }

    static func plan(for kind: NapKind, now: Date = Date(), chronotype: Chronotype = .neutral) -> NapPlan {
        let duration = kind.durationMinutes
        let wake = now.addingTimeInterval(Double(duration) * 60)
        let (energy, inertia, inertiaMin, tip) = effects(for: kind, chronotype: chronotype)

        return NapPlan(
            kind: kind,
            durationMinutes: duration,
            recommendedWakeTime: wake,
            energyGainLabel: energy,
            inertiaRiskLabel: inertia,
            inertiaMinutes: inertiaMin,
            tip: tip
        )
    }

    private static func effects(
        for kind: NapKind,
        chronotype: Chronotype
    ) -> (energy: String, inertia: String, inertiaMinutes: Int, tip: String) {
        let owl = chronotype == .nightOwl
        switch kind {
        case .power:
            return (
                "Boost court (+15–25 % vigilance)",
                owl ? "Faible" : "Très faible",
                owl ? 12 : 8,
                "Idéal avant 16 h. Réveille-toi à l’heure indiquée pour éviter l’inertie."
            )
        case .recovery:
            return (
                "Récupération modérée (phase N2)",
                "Faible à modéré",
                owl ? 18 : 14,
                "~26 min : limite l’inertie tout en rechargeant. Pas après 17 h si tu te couches tôt."
            )
        case .fullCycle:
            return (
                "Récupération profonde possible",
                "Élevé si réveil en phase profonde",
                owl ? 35 : 28,
                "90 min = cycle complet. Prévois 20–35 min d’inertie au réveil avant d’être au top."
            )
        }
    }
}
