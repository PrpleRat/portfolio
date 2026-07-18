import Foundation

struct SessionPreset: Identifiable, Codable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let defaultIntervalMinutes: Int
    let recommendedMethod: CheckInMethod
    let suggestedActions: [AlertAction]
    let warningText: String

    static let all: [SessionPreset] = [
        SessionPreset(
            id: "hiking",
            name: "Randonnée / Trekking",
            emoji: "🥾",
            description: "Zone sans réseau, terrain difficile",
            defaultIntervalMinutes: 120,
            recommendedMethod: .biometric,
            suggestedActions: [.sms, .shareLocation, .callEmergency],
            warningText: "Préviens quelqu'un de ton itinéraire prévu avant de partir"
        ),
        SessionPreset(
            id: "skiing",
            name: "Ski hors-piste / Alpinisme",
            emoji: "⛷️",
            description: "Zone avalanche, risque élevé",
            defaultIntervalMinutes: 60,
            recommendedMethod: .biometric,
            suggestedActions: [.sms, .shareLocation, .callEmergency],
            warningText: "Emporte toujours un DVA et informe le peloton de gendarmerie"
        ),
        SessionPreset(
            id: "solo_drive",
            name: "Trajet solo nocturne",
            emoji: "🚗",
            description: "Long trajet seul, risque d'endormissement",
            defaultIntervalMinutes: 45,
            recommendedMethod: .tapButton,
            suggestedActions: [.sms, .shareLocation],
            warningText: "Si tu es fatigué, arrête-toi. Ne conduis pas somnolent."
        ),
        SessionPreset(
            id: "elderly",
            name: "Vérification quotidienne",
            emoji: "🏠",
            description: "Personne vivant seule, check-in journalier",
            defaultIntervalMinutes: 1440,
            recommendedMethod: .tapButton,
            suggestedActions: [.iMessage, .sms, .email],
            warningText: "Configurez ce preset avec un proche de confiance"
        ),
        SessionPreset(
            id: "cycling",
            name: "Cyclisme / VTT solo",
            emoji: "🚵",
            description: "Sortie vélo seul, zone isolée",
            defaultIntervalMinutes: 90,
            recommendedMethod: .biometric,
            suggestedActions: [.sms, .shareLocation],
            warningText: "Porte toujours un casque et une trousse de premiers secours"
        ),
        SessionPreset(
            id: "climbing",
            name: "Escalade / Via ferrata",
            emoji: "🧗",
            description: "Pratique en solo ou en zone sans réseau",
            defaultIntervalMinutes: 180,
            recommendedMethod: .biometric,
            suggestedActions: [.sms, .shareLocation, .callEmergency],
            warningText: "Informe toujours quelqu'un de la voie et de l'heure prévue de retour"
        ),
        SessionPreset(
            id: "isolated_worker",
            name: "Travailleur isolé",
            emoji: "👷",
            description: "Chantier, site isolé, travail de nuit",
            defaultIntervalMinutes: 60,
            recommendedMethod: .pin,
            suggestedActions: [.sms, .iMessage, .shareLocation],
            warningText: "Conformément au Code du travail, le travailleur isolé doit pouvoir être secouru"
        ),
        SessionPreset(
            id: "custom",
            name: "Personnalisé",
            emoji: "⚙️",
            description: "Configure tous les paramètres manuellement",
            defaultIntervalMinutes: 60,
            recommendedMethod: .biometric,
            suggestedActions: [.sms],
            warningText: ""
        ),
    ]
}
