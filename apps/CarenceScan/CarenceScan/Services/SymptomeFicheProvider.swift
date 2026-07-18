import Foundation
import SwiftUI

enum SymptomeFicheProvider {

    private static let overrides: [String: (description: String, quandSinquieter: String)] = [
        "fatigue_intense": (
            "Fatigue persistante malgré le repos. Signe très fréquent de carences (fer, B12, vitamine D, magnésium) mais aussi de dépression, hypothyroïdie ou anémie.",
            "Consultez si la fatigue dure plus de 3 semaines, s'aggrave, ou s'accompagne de fièvre, perte de poids inexpliquée, essoufflement ou malaises."
        ),
        "brouillard_mental": (
            "Difficultés de concentration et ralentissement cognitif. Peut refléter un déficit en fer, B12, vitamine D, magnésium ou oméga-3.",
            "Consultez si apparition brutale, troubles de la parole, céphalées intenses ou confusion — urgence médicale."
        ),
        "fourmillements": (
            "Paresthésies mains/pieds, souvent liées à B12, B6, magnésium ou diabète non contrôlé.",
            "Consultez rapidement si les fourmillements s'étendent, s'accompagnent de faiblesse musculaire ou persistent sans cause."
        ),
        "palpitations": (
            "Battements cardiaques ressentis. Carences en fer, magnésium ou B1 possibles ; aussi anxiété, thyroïde ou arythmie.",
            "Consultez en urgence si douleur thoracique, syncope, essoufflement au repos ou palpitations très rapides (>120/min au repos)."
        ),
        "ecchymoses_faciles": (
            "Hématomes sans choc important. Évocatif de carence en vitamine C, K ou parfois fer/plaquettes.",
            "Consultez si saignements de nez/gencives abondants, petites taches rouges sur la peau ou ecchymoses multiples sans cause."
        ),
        "plaies_lentes": (
            "Cicatrisation retardée. Classique en carence de vitamine C, zinc, fer ou protéines.",
            "Consultez si plaie infectée, fièvre, plaie qui ne se referme pas après 4 semaines ou signes de diabète."
        ),
        "cheveux_cassants": (
            "Chute ou fragilité capillaire. Lié au fer, zinc, biotine (B8), protéines, thyroïde ou stress prolongé.",
            "Consultez si chute en plaques, perte > 100 cheveux/jour pendant un mois ou signes d'hypothyroïdie associés."
        ),
        "crampes_nocturnes": (
            "Contractions musculaires nocturnes, très suggestives de magnésium bas (aussi potassium, fer).",
            "Consultez si crampes diurnes répétées, faiblesse musculaire ou douleur persistante entre les crises."
        ),
        "vision_trouble": (
            "Baisse de vision ou gêne en basse lumière. Carence en vitamine A classique ; aussi diabète ou hypertension.",
            "Consultez en urgence si vision floue brutale, double vision, flashs lumineux ou perte de champ visuel."
        ),
        "sensibilite_froid": (
            "Frilosité excessive. Évocatif d'hypothyroïdie, carence en fer, iode ou vitamine B12.",
            "Consultez si frilosité nouvelle avec prise de poids, constipation, peau sèche ou ralentissement général."
        ),
        "tristesse_fond": (
            "Humeur basse persistante. Peut être dépression, carence en oméga-3, B6, B12, vitamine D ou fer.",
            "Consultez si idées noires, isolement, incapacité à travailler ou pensées suicidaires — contactez le 3114 (France)."
        ),
        "mauvais_sommeil": (
            "Insomnie ou sommeil fragmenté. Magnésium, B6, fer, mélatonine/endocrinien ou stress/anxiété.",
            "Consultez si apnée suspectée (ronflements + somnolence), réveils avec panique ou insomnie > 1 mois invalidante."
        )
    ]

    static func fiche(for symptomeId: String) -> SymptomeFicheDetail? {
        guard let symptome = CarenceDatabase.shared.symptomes.first(where: { $0.id == symptomeId }) else {
            return nil
        }
        let links = CarenceDatabase.carencesLiees(symptomeId: symptomeId)
        let override = overrides[symptomeId]
        return SymptomeFicheDetail(
            symptomeId: symptomeId,
            label: symptome.label,
            categorie: SymptomCategory(rawValue: symptome.categorie)?.title ?? symptome.categorie,
            description: override?.description ?? descriptionParDefaut(categorie: symptome.categorie),
            quandSinquieter: override?.quandSinquieter ?? quandSinquieterParDefaut(categorie: symptome.categorie),
            carencesLiees: links
        )
    }

    private static func descriptionParDefaut(categorie: String) -> String {
        "Ce symptôme peut orienter vers plusieurs carences nutritionnelles selon son intensité, sa fréquence et les signes associés. CarenceScan croise vos réponses avec une base de 18 carences documentées."
    }

    private static func quandSinquieterParDefaut(categorie: String) -> String {
        switch categorie {
        case "bouche", "peau", "cheveux_ongles":
            return "Consultez si le symptôme persiste plus de 2 à 4 semaines malgré les mesures d'hygiène/alimentation, s'aggrave ou s'accompagne de fièvre ou douleur intense."
        case "energie", "humeur", "sommeil":
            return "Consultez si le symptôme dure plus de 3 semaines, impacte votre vie quotidienne ou s'accompagne de signes neurologiques, cardiaques ou de perte de poids."
        case "membres":
            return "Consultez si douleur intense, faiblesse progressive, engourdissement unilatéral ou troubles de la marche apparaissent."
        case "digestion":
            return "Consultez si sang dans les selles, vomissements persistants, perte de poids involontaire ou douleur abdominale sévère."
        case "autre":
            return "Consultez si le symptôme est nouveau, s'aggrave rapidement ou s'accompagne de signes d'alerte (fièvre, essoufflement, douleur thoracique)."
        default:
            return "En cas de doute ou de persistance > 1 mois, parlez-en à votre médecin avant toute supplémentation."
        }
    }
}

extension Carence {
    var quandSinquieterText: String {
        if let custom = quandSinquieter, !custom.isEmpty { return custom }
        switch urgence.lowercased() {
        case "haute":
            return "Priorité élevée : un bilan sanguin est recommandé avant supplémentation. Consultez rapidement si les symptômes s'aggravent ou touchent plusieurs domaines (peau + fatigue + bouche)."
        case "médicale", "medicale":
            return "Consultez votre médecin pour confirmer la carence par analyse avant tout complément. Ne pas automédiquer si vous avez des traitements chroniques."
        default:
            return "Surveillez l'évolution sur 2 à 4 semaines. Consultez si les symptômes persistent malgré une alimentation équilibrée ou s'intensifient."
        }
    }

    var signesAlerteItems: [String] {
        if let custom = signesAlerte, !custom.isEmpty { return custom }
        switch id {
        case "fer":
            return ["Essoufflement à l'effort", "Pâleur, vertiges", "Palpitations au repos"]
        case "vitamine_b12", "vitamine_b9":
            return ["Fourmillements progressifs", "Troubles de l'équilibre", "Langue rouge et douloureuse"]
        case "vitamine_c":
            return ["Gencives qui saignent abondamment", "Ecchymoses multiples", "Fièvre avec fatigue extrême"]
        case "iode", "selenium":
            return ["Goitre visible", "Prise ou perte de poids inexpliquée", "Intolérance au froid/chaleur"]
        default:
            return ["Aggravation rapide des symptômes", "Apparition de signes neurologiques ou cardiaques", "Symptômes persistants > 1 mois"]
        }
    }

    var urgenceLabel: String {
        switch urgence.lowercased() {
        case "haute": return "Priorité haute"
        case "médicale", "medicale": return "Avis médical recommandé"
        default: return "Surveillance"
        }
    }

    var urgenceColor: Color {
        switch urgence.lowercased() {
        case "haute": return CarenceColors.alert
        case "médicale", "medicale": return CarenceColors.warning
        default: return CarenceColors.primary
        }
    }
}