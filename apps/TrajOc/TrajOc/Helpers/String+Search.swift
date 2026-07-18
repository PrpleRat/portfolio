import Foundation

extension String {
    /// Normalise pour comparaison (minuscules, sans accents)
    var normalizedForSearch: String {
        folding(options: .diacriticInsensitive, locale: Locale(identifier: "fr_FR"))
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum UserFacingError {
    static func message(for error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        if error is DecodingError {
            return "Réponse du réseau SNCF illisible. Choisis une gare dans les suggestions (ex. Toulouse Matabiau) puis réessaie."
        }
        return error.localizedDescription
    }
}
