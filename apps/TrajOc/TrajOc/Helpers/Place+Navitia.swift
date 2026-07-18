import Foundation

extension Place {
    /// Coordonnées au format Navitia/SNCF : `lon;lat`
    var navitiaCoordinateRef: String {
        String(format: "%.6f;%.6f", coordinate.lon, coordinate.lat)
    }

    /// ID utilisable sur `coverage/sncf` (API SNCF gratuite)
    var isSNCFNativeID: Bool {
        id.hasPrefix("stop_area:SNCF:")
            || id.hasPrefix("stop_point:SNCF:")
            || id.hasPrefix("address:SNCF:")
    }

    /// IDs embarqués historiques (coverage OIF) — invalides sur l'API SNCF
    var isLegacyEmbeddedStationID: Bool {
        id.hasPrefix("stop_area:OIF:") || id.hasPrefix("stop_area:OIF-")
    }

    /// Paramètre `from` / `to` pour `/coverage/sncf/journeys`
    var navitiaLocationRef: String {
        if isSNCFNativeID {
            return id
        }
        // Toujours préférer les coordonnées pour gares embarquées et adresses BAN
        return navitiaCoordinateRef
    }

    /// Chemin URL pour les horaires — coords si ID legacy
    var navitiaDeparturesPath: String {
        if isSNCFNativeID {
            let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
            return "stop_areas/\(encoded)/departures"
        }
        let encodedCoord = navitiaCoordinateRef.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            ?? navitiaCoordinateRef
        return "coords/\(encodedCoord)/departures"
    }

    var isStation: Bool {
        type == .gare || type == .stopArea || type == .stopPoint
    }
}
