import Foundation

/// Références courtes (méta-analyses, revues) — éducation, pas diagnostic.
extension FactorType {
    var scienceBrief: String? {
        switch self {
        case .caffeine:
            return "Drake et al., J Clin Sleep Med 2013 — caféine jusqu’à 6 h avant le coucher réduit la qualité du sommeil."
        case .nicotine, .vapingNicotine:
            return "Jaehne et al., Addict Biol 2009 — nicotine perturbe l’endormissement et l’architecture du sommeil."
        case .alcohol:
            return "Ebrahim et al., Alcohol Clin Exp Res 2013 — l’alcool fragmente le sommeil et réduit le REM malgré une sensation initiale de sédation."
        case .cannabis:
            return "Gates et al., Sleep Med Rev 2014 — usage chronique associé à moins de sommeil profond/REM."
        case .cbdOil:
            return "Kuhathasan et al., Sleep Med Rev 2019 — preuves limitées ; effets variables selon dose et produit."
        case .melatonin:
            return "Ferracioli-Oda et al., PLoS One 2013 — mélatonine peut réduire la latence d’endormissement (surtout décalage horaire/jet lag)."
        case .magnesium:
            return "Mah et al., Nutrients 2021 — supplémentation parfois associée à une meilleure qualité subjective (données hétérogènes)."
        case .valerian:
            return "Bent et al., Am J Med 2006 — effet modeste sur l’insomnie subjective ; qualité des études variable."
        case .theanine:
            return "Hidese et al., Nutrients 2019 — L-théanine peut favoriser la relaxation et le sommeil non-REM chez certains profils."
        case .chocolate:
            return "Theobromine + caféine résiduelle — sensibilité individuelle, surtout si consommée tard."
        case .energyDrink:
            return "Combinaison caféine + stimulants — effets plus longs sur l’éveil que une boisson classique."
        case .lateEating, .heavyMeal:
            return "Crispim et al., Chronobiol Int 2011 — repas tardif lié à plus de micro-éveils et sommeil moins réparateur."
        case .spicyMeal:
            return "Reflux nocturne (GERD) — association fréquente avec réveils et sommeil léger."
        case .highGlycemicEvening:
            return "St-Onge et al., Adv Nutr 2016 — repas à index glycémique élevé peut influencer thermogenèse et sommeil."
        case .hydration:
            return "Hydratation excessive tardive → réveils pour miction (pratique clinique courante)."
        case .exercise:
            return "Kredlow et al., J Behav Med 2015 — activité régulière améliore la qualité du sommeil ; timing individuel."
        case .eveningIntenseExercise:
            return "Stutz et al., Sports Med 2019 — effort intense tard peut retarder l’endormissement chez certains."
        case .lateNap:
            return "Milner & Cote, Sleep Med 2009 — sieste longue tardive réduit la pression de sommeil."
        case .screenTime, .brightLightEvening:
            return "Cajochen et al., J Appl Physiol 2011 — lumière bleue le soir retarde la mélatonine et l’endormissement."
        case .sunExposure:
            return "Wright et al., Curr Biol 2013 — lumière matinale renforce le rythme circadien."
        case .mindfulness:
            return "Black et al., JAMA Intern Med 2015 — méditation de pleine conscience améliore l’insomnie subjective."
        case .stressLevel, .anxietyLevel, .rumination:
            return "Harvey, Sleep Med Rev 2002 — hyperéveil cognitif/émotionnel majeur dans l’insomnie."
        case .shiftWork, .jetLag:
            return "Boivin & Boudreau, Sleep 2014 — décalage circadien : qualité et durée du sommeil altérées."
        case .roomTemperature:
            return "Okamoto-Mizuno & Mizuno, J Physiol Anthropol 2012 — chambre trop chaude dégrade le sommeil profond."
        case .noisyEnvironment, .partnerSnoring:
            return "WHO — bruit nocturne associé à fragmentation du sommeil et réveils."
        case .pain, .restlessLegs:
            return "Ohayon et al., Sleep Med Rev 2012 — douleur et RLS fragmentent le sommeil."
        case .medicationSleep, .benzodiazepine:
            return "Sateia et al., AASM 2017 — hypnotiques : bénéfice court terme ; vigilance dépendance/effets résiduels."
        case .ssri:
            return "Wichniak et al., Pharmacol Rep 2017 — ISRS peuvent réduire le REM et modifier l’architecture."
        case .antihistamineSedative:
            return "Sedating H1 — somnolence résiduelle possible le lendemain."
        case .menstrualDiscomfort, .hotFlash:
            return "Baker et al., Sleep Med Rev 2018 — symptômes hormonaux/ménopause liés à l’insomnie."
        default:
            return nil
        }
    }

    /// Facteurs proposés dans l’écran « avant de dormir » (les plus actionnables).
    static var preSleepQuickPickTypes: [FactorType] {
        allCases.filter { $0.isQuickPick }
    }

    var isQuickPick: Bool {
        switch category {
        case .stimulant, .substance, .supplement, .food, .activity, .environment:
            return true
        case .wellbeing, .medical, .circadian:
            return self == .stressLevel || self == .anxietyLevel || self == .rumination
                || self == .pain || self == .allergySymptoms
        }
    }
}
