import Foundation

enum EnergyWindowGlossary {
    static func title(for kind: CircadianEnergyEngine.TimeWindow.Kind) -> String {
        switch kind {
        case .inertia: return "Inertie du sommeil"
        case .energyPeak: return "Pic d’énergie"
        case .fatigueDip: return "Coup de barre"
        case .fatiguePeak: return "Pic de fatigue"
        case .caffeineBoost: return "Boost caféine"
        case .substanceDip: return "Baisse post-substances"
        case .secondWind: return "Second souffle"
        }
    }

    static func explanation(for kind: CircadianEnergyEngine.TimeWindow.Kind) -> String {
        switch kind {
        case .inertia:
            return "Les 30–90 min après le réveil : le corps met du temps à passer en mode « éveillé ». Normal après une nuit courte ou fragmentée."
        case .energyPeak:
            return "Fenêtre où ta vigilance naturelle est au plus haut selon ton chronotype et ton sommeil de la nuit."
        case .fatigueDip:
            return "Baisse circadienne classique (souvent l’après-midi). Pause courte ou marche de 10 min peuvent aider."
        case .fatiguePeak:
            return "Moment où la fatigue accumulée (dette de sommeil, cycle) est la plus forte. Évite les décisions importantes."
        case .caffeineBoost:
            return "Effet stimulant estimé après ta dernière prise (café, boisson énergisante). Le pic arrive ~30–60 min après la consommation selon ton métabolisme."
        case .substanceDip:
            return "Après alcool, cannabis ou sédatifs : baisse de vigilance quand l’effet « masque la fatigue » retombe — souvent 1 à 3 h après la prise, pas immédiatement."
        case .secondWind:
            return "Remontée d’énergie en fin de journée, fréquente chez les couche-tard. Utile pour des tâches légères, mais peut retarder l’endormissement si tu te couches tôt."
        }
    }
}
