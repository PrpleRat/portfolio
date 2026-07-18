import CoreLocation
import Foundation

/// Constantes globales de l'application TrajOc
enum AppConstants {

    // Réseau
    static let networkTimeout: Double = 12.0
    static let maxRetries = 2
    static let userAgent = "TrajOc/1.0 (iOS; contact: dev@trajoc.app)"

    // Transport en commun — API SNCF gratuite (150 000 req/mois), format Navitia
    // Inscription : https://numerique.sncf.com/startup/api/
    static let navitiaBaseURL = "https://api.sncf.com/v1"
    static let navitiaCoverage = "sncf"
    static let navitiaMaxJourneys = 5
    static let navitiaMaxDuration = 14400

    // OpenRouteService / HeiGIT (clés depuis account.heigit.org)
    static let orsBaseURL = "https://api.heigit.org/openrouteservice"

    // Base Adresse Nationale (France) — api-adresse.data.gouv.fr
    static let banBaseURL = "https://api-adresse.data.gouv.fr"
    // Nominatim (secours)
    static let nominatimBaseURL = "https://nominatim.openstreetmap.org"
    static let searchBiasLat = 43.6047
    static let searchBiasLon = 1.4442
    static let searchCountryCode = "fr"
    static let nominatimMinInterval: TimeInterval = 1.1

    // OpenStreetMap Overpass — arrêts bus locaux (liO, etc.)
    static let overpassBaseURL = "https://overpass-api.de/api/interpreter"

    // JCDecaux
    static let jcDecauxBaseURL = "https://api.jcdecaux.com/vls/v1"
    static let bikeContracts = ["toulouse", "montpellier", "nimes", "perpignan"]

    // Carte
    static let defaultRegionLatDelta = 0.15
    static let defaultRegionLonDelta = 0.15
    static let occitanieCenter = CLLocationCoordinate2D(latitude: 43.6, longitude: 2.35)

    // Cache
    static let cacheExpiry: Double = 300

    // Optimisation multi-stops
    static let maxIntermediateStops = 6

    // Widget / favoris partagés
    static let appGroupID = "group.com.trajoc.shared"
    static let widgetFavoriteKey = "trajoc.widget.favorite"
}
