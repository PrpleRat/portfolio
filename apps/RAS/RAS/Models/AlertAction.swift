import Foundation

enum AlertAction: String, Codable, CaseIterable, Identifiable {

    case iMessage = "imessage"
    case sms = "sms"
    case email = "email"
    case shareLocation = "share_location"
    case shortcut = "shortcut"
    case callEmergency = "call_112"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .iMessage: return "Message (SMS/iMessage)"
        case .sms: return "SMS (GSM, 1× Envoyer)"
        case .email: return "Email"
        case .shareLocation: return "Partager ma position GPS"
        case .shortcut: return "Raccourci Siri"
        case .callEmergency: return "Appel d'urgence (112)"
        }
    }

    var sfSymbol: String {
        switch self {
        case .iMessage: return "message.fill"
        case .sms: return "phone.arrow.up.right"
        case .email: return "envelope.fill"
        case .shareLocation: return "location.fill"
        case .shortcut: return "shortcuts"
        case .callEmergency: return "phone.fill.arrow.up.right"
        }
    }

    var worksOffline: Bool {
        switch self {
        case .sms, .shareLocation, .callEmergency: return true
        default: return false
        }
    }

    var description: String {
        switch self {
        case .sms:
            return "Ouvre Messages avec le texte prêt — 1 appui sur Envoyer (limite Apple, pas d'envoi 100 % silencieux)"
        case .iMessage:
            return "Comme SMS — message pré-rempli, tu confirmes avec Envoyer"
        case .email:
            return "Envoie un email — nécessite une connexion internet"
        case .shareLocation:
            return "Inclut tes coordonnées GPS dans tous les messages envoyés"
        case .shortcut:
            return "Déclenche un Raccourci Siri que tu as créé dans l'app Raccourcis"
        case .callEmergency:
            return "Effectue un appel vers le 112 — à utiliser en dernier recours"
        }
    }
}
