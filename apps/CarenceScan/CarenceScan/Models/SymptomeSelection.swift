import Foundation

enum Frequence: String, Codable, CaseIterable, Hashable {
    case occasionnel
    case frequent
    case constant

    var coefficient: Double {
        switch self {
        case .occasionnel: return 0.5
        case .frequent: return 1.0
        case .constant: return 1.5
        }
    }

    var label: String {
        switch self {
        case .occasionnel: return "Occasionnel"
        case .frequent: return "Fréquent"
        case .constant: return "Constant"
        }
    }

    var emoji: String {
        switch self {
        case .occasionnel: return "🔵"
        case .frequent: return "🟡"
        case .constant: return "🔴"
        }
    }
}

struct SymptomeSelection: Codable, Identifiable, Hashable {
    var id: String { symptomeId }
    let symptomeId: String
    var frequence: Frequence

    init(symptomeId: String, frequence: Frequence = .frequent) {
        self.symptomeId = symptomeId
        self.frequence = frequence
    }
}
