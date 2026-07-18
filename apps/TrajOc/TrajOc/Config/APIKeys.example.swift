// APIKeys.example.swift
// Copie en APIKeys.swift (local) ou secrets GitHub (TestFlight).
//
// SNCF (trains, TER, horaires) — GRATUIT 150k req/mois :
//   https://numerique.sncf.com/startup/api/
// OpenRouteService / HeiGIT (voiture, vélo, marche) :
//   https://account.heigit.org/manage/key
// JCDecaux (vélos) :
//   https://developer.jcdecaux.com

enum APIKeys {

    /// Token API SNCF (même format que Navitia — Basic Auth, mot de passe vide)
    static let navitia = "TON_TOKEN_SNCF_ICI"

    /// Clé HeiGIT / OpenRouteService
    static let openRouteService = "TA_CLE_HEIGIT_ICI"

    /// Clé JCDecaux
    static let jcDecaux = "TA_CLE_JCDECAUX_ICI"
}
