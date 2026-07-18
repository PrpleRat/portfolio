import Foundation

/// Messages bienveillants liés au cycle (non médical).
enum CycleComfortContent {

    struct Card {
        let title: String
        let message: String
        let sleepTip: String
        let selfCare: String
    }

    static func card(
        phase: CyclePhase,
        isOnPeriod: Bool,
        daysUntilNextPeriod: Int?
    ) -> Card {
        if isOnPeriod {
            return Card(
                title: "Pendant tes règles",
                message: "C’est normal d’être plus fatiguée, sensible ou d’avoir un sommeil plus léger. Ton corps récupère — pas besoin de « performer ».",
                sleepTip: "Couche-toi 20–30 min plus tôt si possible, chaleur au bas-ventre, évite les écrans violents avant le dodo.",
                selfCare: "Hydrate-toi, repas chauds légers, dis non aux obligations non essentielles ce soir."
            )
        }

        switch phase {
        case .menstrual:
            return Card(
                title: "Phase menstruelle",
                message: "Fin de cycle : l’énergie remonte doucement. Écoute ta fatigue sans te juger.",
                sleepTip: "Priorise la régularité des horaires de coucher plutôt que la durée parfaite.",
                selfCare: "Mouvement doux (marche, étirements) plutôt qu’entraînement intense."
            )
        case .follicular:
            return Card(
                title: "Phase folliculaire",
                message: "Souvent la période où l’énergie et l’humeur remontent — bon moment pour projets et sport modéré.",
                sleepTip: "Profite-en pour ancrer une heure de coucher stable ; ton sommeil profond peut être plus stable.",
                selfCare: "Planifie les tâches exigeantes en journée, garde le soir plus calme."
            )
        case .ovulatory:
            return Card(
                title: "Phase ovulatoire",
                message: "Pic d’énergie possible ; certaines personnes dorment un peu moins ou sont plus réveillées.",
                sleepTip: "Chambre fraîche et obscure ; limite caféine après 14 h si tu es sensible.",
                selfCare: "Note si tu te sens plus sociale ou dispersée — adapte ton agenda."
            )
        case .luteal:
            let extra = daysUntilNextPeriod.map { d in
                d <= 7 ? " Tes règles approchent peut‑être dans \(d) jour\(d > 1 ? "s" : "")." : ""
            } ?? ""
            return Card(
                title: "Phase lutéale",
                message: "Le SPM peut toucher sommeil, humeur et envies sucrées — ce n’est pas « dans ta tête ».\(extra)",
                sleepTip: "Routine apaisante (tisane, lecture, respiration). Évite l’alcool qui fragmente le sommeil.",
                selfCare: "Magnésium / repas équilibrés si ça t’aide ; sois indulgente avec les baisses d’énergie."
            )
        }
    }
}
