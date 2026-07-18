import Foundation

/// Conseils du soir adaptés à la phase du cycle.
enum EveningAdviceEngine {
    struct EveningAdvice {
        let title: String
        let body: String
        let icon: String
    }

    static func advice(profile: UserProfile?, on date: Date = Date()) -> EveningAdvice? {
        guard let profile, profile.tracksMenstrualCycle else { return nil }
        guard let day = profile.currentCycleDay(on: date) else { return nil }
        let phase = CyclePhase.from(cycleDay: day, cycleLength: profile.averageCycleLength)

        switch phase {
        case .luteal:
            return EveningAdvice(
                title: "Soirée lutéale",
                body: "Vise un coucher ~30 min plus tôt. Routine apaisante : lumière tamisée, pas d’écran intense, respiration ou étirements doux.",
                icon: "moon.zzz.fill"
            )
        case .menstrual:
            return EveningAdvice(
                title: "Soirée menstruelle",
                body: "Hydratation et douceur : pas d’objectif performance. Écoute ton corps, chaleur locale si crampes, coucher sans pression.",
                icon: "drop.fill"
            )
        case .follicular:
            return EveningAdvice(
                title: "Soirée folliculaire",
                body: "Énergie souvent plus haute : garde une heure de coucher stable pour capitaliser sur cette phase.",
                icon: "leaf.fill"
            )
        case .ovulatory:
            return EveningAdvice(
                title: "Soirée ovulatoire",
                body: "Sommeil parfois plus léger : évite la caféine tardive et prépare un environnement frais et sombre.",
                icon: "sparkles"
            )
        }
    }
}
