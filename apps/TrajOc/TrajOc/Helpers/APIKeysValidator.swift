import Foundation

/// Vérifie que les clés API ne sont pas les placeholders du template
enum APIKeysValidator {
    private static let placeholders = [
        "TON_TOKEN_SNCF_ICI",
        "TON_TOKEN_NAVITIA_ICI",
        "TA_CLE_HEIGIT_ICI",
        "TA_CLE_ORS_ICI",
        "TA_CLE_JCDECAUX_ICI"
    ]

    static var isConfigured: Bool {
        !placeholders.contains(APIKeys.navitia)
            && !placeholders.contains(APIKeys.openRouteService)
            && !placeholders.contains(APIKeys.jcDecaux)
            && !APIKeys.navitia.isEmpty
            && !APIKeys.openRouteService.isEmpty
    }

    static var configurationHint: String {
        if isConfigured { return "Clés API configurées." }
        return "Clés API manquantes — ajoute SNCF_API_KEY (ou NAVITIA_API_KEY), ORS_API_KEY et JCDECAUX_API_KEY dans GitHub Secrets, puis relance TestFlight."
    }
}
