import Foundation

/// Fréquence déduite du journal quotidien (distincte de la fréquence déclarée au questionnaire).
enum JournalFrequence: String, CaseIterable, Hashable {
    case jamais
    case occasionnel
    case frequent
    case constant

    var label: String {
        switch self {
        case .jamais: return "Jamais / résolu"
        case .occasionnel: return "Occasionnel"
        case .frequent: return "Fréquent"
        case .constant: return "Quasi quotidien"
        }
    }

    var emoji: String {
        switch self {
        case .jamais: return "✅"
        case .occasionnel: return "🔵"
        case .frequent: return "🟡"
        case .constant: return "🔴"
        }
    }

    var colorName: String {
        switch self {
        case .jamais: return "primary"
        case .occasionnel: return "secondary"
        case .frequent: return "warning"
        case .constant: return "alert"
        }
    }

    /// Conversion pour le recalcul des scores (nil = symptôme résolu, exclu du scoring).
    var scoringFrequence: Frequence? {
        switch self {
        case .jamais: return nil
        case .occasionnel: return .occasionnel
        case .frequent: return .frequent
        case .constant: return .constant
        }
    }
}

enum SymptomFrequencyEngine {

    /// Nombre de jours de suivi avant de considérer un symptôme comme « jamais » s'il n'apparaît plus.
    static let resolutionDays = 14
    /// Minimum de jours renseignés pour afficher une estimation.
    static let minDaysForEstimate = 5

    static func frequence(
        symptomeId: String,
        windowDays: Int = resolutionDays,
        resolutionDays: Int = Self.resolutionDays
    ) -> JournalFrequence? {
        let entries = SymptomJournalStorage.entries(for: symptomeId, lastDays: windowDays)
        let answered = entries.count
        guard answered >= minDaysForEstimate else { return nil }

        let present = entries.filter(\.present).count
        if present == 0, answered >= resolutionDays {
            return .jamais
        }

        let ratio = Double(present) / Double(answered)
        if ratio >= 0.55 { return .constant }
        if ratio >= 0.25 { return .frequent }
        if ratio > 0 { return .occasionnel }
        return answered >= resolutionDays ? .jamais : .occasionnel
    }

    static func resumeTexte(symptomeId: String) -> String? {
        guard let freq = frequence(symptomeId: symptomeId) else { return nil }
        let entries = SymptomJournalStorage.entries(for: symptomeId, lastDays: resolutionDays)
        let present = entries.filter(\.present).count
        return "\(freq.emoji) \(freq.label) — \(present)/\(entries.count) j sur \(resolutionDays)"
    }
}
