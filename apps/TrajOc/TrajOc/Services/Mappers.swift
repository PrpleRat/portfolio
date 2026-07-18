import CoreLocation
import Foundation

/// Utilitaires de parsing des dates Navitia (format 20250615T083000)
enum NavitiaDateParser {
    static func parse(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.timeZone = TimeZone(identifier: "Europe/Paris")
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        return formatter.date(from: value)
    }
}

/// Format requis par l'API SNCF/Navitia pour le paramètre `datetime`
enum NavitiaRequestFormatter {
    static func journeyDateTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Paris")
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        return formatter.string(from: date)
    }
}

extension JSONDecoder {
    static var navitia: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

/// Mappe les réponses Navitia vers les modèles domaine
enum JourneyMapper {
    static func map(_ raw: NavitiaJourneysResponse.NavitiaJourney) -> Journey {
        let sections = raw.sections.map { SectionMapper.map($0) }
        let fare: Fare? = {
            guard let f = raw.fare else { return nil }
            let total = Double(f.total?.value ?? "0") ?? 0
            return Fare(total: total, currency: f.total?.currency ?? "EUR", found: f.found ?? false)
        }()

        return Journey(
            id: UUID(),
            departureTime: NavitiaDateParser.parse(raw.departureDateTime) ?? Date(),
            arrivalTime: NavitiaDateParser.parse(raw.arrivalDateTime) ?? Date(),
            duration: raw.duration,
            waitingDuration: raw.waitingDuration ?? 0,
            walkingDuration: raw.walkingDuration ?? 0,
            transfers: raw.nbTransfers ?? 0,
            co2EmissionsGrams: raw.co2Emission?.value ?? CO2Calculator.estimate(for: sections),
            sections: sections,
            fare: fare,
            hasDisruptions: raw.status != "NO_SERVICE" && sections.contains { !$0.disruptions.isEmpty }
        )
    }
}

enum SectionMapper {
    static func map(_ raw: NavitiaJourneysResponse.NavitiaSection) -> JourneySection {
        let sectionType = SectionType(rawValue: raw.type) ?? .streetNetwork
        let mode = TransportModeMapper.fromNavitia(raw: raw)
        let line = raw.displayInformations.map { LineMapper.map($0, mode: mode) }
        let stops = (raw.stopDateTimes ?? []).map { PlaceMapper.map($0.stopPoint) }
        let instructions = (raw.path ?? []).compactMap { $0.name }.filter { !$0.isEmpty }
        let polyline = raw.geojson.flatMap { encodePolyline(from: $0.coordinates) }

        return JourneySection(
            id: UUID(),
            type: sectionType,
            mode: mode,
            from: PlaceMapper.map(raw.from),
            to: PlaceMapper.map(raw.to),
            departureTime: NavitiaDateParser.parse(raw.departureDateTime),
            arrivalTime: NavitiaDateParser.parse(raw.arrivalDateTime),
            duration: raw.duration ?? 0,
            distanceMeters: raw.geojson.map { polylineDistance($0.coordinates) },
            line: line,
            stopPoints: stops,
            turnInstructions: instructions,
            encodedPolyline: polyline,
            boardingPosition: nil,
            disruptions: []
        )
    }

    private static func polylineDistance(_ coords: [[Double]]) -> Double {
        guard coords.count > 1 else { return 0 }
        var total = 0.0
        for i in 1..<coords.count {
            let a = coords[i - 1]
            let b = coords[i]
            guard a.count >= 2, b.count >= 2 else { continue }
            let locA = CLLocation(latitude: a[1], longitude: a[0])
            let locB = CLLocation(latitude: b[1], longitude: b[0])
            total += locA.distance(from: locB)
        }
        return total
    }

    private static func encodePolyline(from coordinates: [[Double]]) -> String? {
        guard !coordinates.isEmpty else { return nil }
        var encoded = ""
        var lastLat = 0
        var lastLon = 0
        for coord in coordinates where coord.count >= 2 {
            let lat = Int(round(coord[1] * 1e5))
            let lon = Int(round(coord[0] * 1e5))
            encoded += PolylineEncoder.encodeValue(lat - lastLat)
            encoded += PolylineEncoder.encodeValue(lon - lastLon)
            lastLat = lat
            lastLon = lon
        }
        return encoded.isEmpty ? nil : encoded
    }
}

enum PlaceMapper {
    static func map(_ raw: NavitiaJourneysResponse.NavitiaPlace) -> Place {
        if let stopArea = raw.stopArea {
            return Place(
                id: stopArea.id,
                name: stopArea.name,
                type: .stopArea,
                coordinate: Place.Coordinate(lat: stopArea.coord.latitude, lon: stopArea.coord.longitude),
                city: stopArea.administrativeRegions?.first(where: { $0.level == 8 })?.name,
                postalCode: nil,
                administrativeRegion: stopArea.administrativeRegions?.first(where: { $0.level == 6 })?.name
            )
        }
        if let stopPoint = raw.stopPoint {
            return mapStopPoint(stopPoint) ?? Place(
                id: raw.id ?? stopPoint.id,
                name: raw.name ?? stopPoint.name,
                type: .stopPoint,
                coordinate: Place.Coordinate(lat: stopPoint.coord.latitude, lon: stopPoint.coord.longitude),
                city: nil,
                postalCode: nil,
                administrativeRegion: nil
            )
        }
        if let address = raw.address {
            return Place(
                id: address.id ?? raw.id ?? UUID().uuidString,
                name: address.label ?? address.name ?? raw.name ?? "Adresse",
                type: .address,
                coordinate: Place.Coordinate(lat: address.coord.latitude, lon: address.coord.longitude),
                city: address.administrativeRegions?.first(where: { $0.level == 8 })?.name,
                postalCode: nil,
                administrativeRegion: address.administrativeRegions?.first(where: { $0.level == 6 })?.name
            )
        }
        return Place(
            id: raw.id ?? UUID().uuidString,
            name: raw.name ?? "Lieu",
            type: Place.PlaceType(rawValue: raw.embeddedType ?? "") ?? .poi,
            coordinate: Place.Coordinate(lat: AppConstants.searchBiasLat, lon: AppConstants.searchBiasLon),
            city: nil,
            postalCode: nil,
            administrativeRegion: nil
        )
    }

    static func map(_ raw: NavitiaPlacesResponse.NavitiaRawPlace) -> Place {
        if let stopArea = raw.stopArea {
            return Place(
                id: stopArea.id,
                name: stopArea.name,
                type: .stopArea,
                coordinate: Place.Coordinate(lat: stopArea.coord.latitude, lon: stopArea.coord.longitude),
                city: stopArea.administrativeRegions?.first(where: { $0.level == 8 })?.name,
                postalCode: nil,
                administrativeRegion: stopArea.administrativeRegions?.first(where: { $0.level == 6 })?.name
            )
        }
        if let address = raw.address {
            return Place(
                id: address.id ?? raw.id,
                name: address.label ?? raw.name,
                type: .address,
                coordinate: Place.Coordinate(lat: address.coord.latitude, lon: address.coord.longitude),
                city: address.administrativeRegions?.first(where: { $0.level == 8 })?.name,
                postalCode: nil,
                administrativeRegion: address.administrativeRegions?.first(where: { $0.level == 6 })?.name
            )
        }
        return Place(
            id: raw.id,
            name: raw.name,
            type: Place.PlaceType(rawValue: raw.embeddedType) ?? .poi,
            coordinate: Place.Coordinate(lat: AppConstants.searchBiasLat, lon: AppConstants.searchBiasLon),
            city: nil,
            postalCode: nil,
            administrativeRegion: nil
        )
    }

    static func mapStopPoint(_ stopPoint: NavitiaJourneysResponse.NavitiaPlace.StopPoint?) -> Place? {
        guard let stopPoint else { return nil }
        return Place(
            id: stopPoint.id,
            name: stopPoint.name,
            type: .stopPoint,
            coordinate: Place.Coordinate(lat: stopPoint.coord.latitude, lon: stopPoint.coord.longitude),
            city: nil,
            postalCode: nil,
            administrativeRegion: nil
        )
    }
}

enum LineMapper {
    static func map(_ info: NavitiaJourneysResponse.NavitiaSection.DisplayInfo, mode: TransportMode) -> TransitLine {
        let code = info.code ?? ""
        let label = info.label ?? code
        let color = info.color ?? "888888"
        let textColor = info.textColor ?? "FFFFFF"
        return TransitLine(
            id: code,
            code: label.isEmpty ? code : label,
            name: info.name ?? label,
            mode: mode,
            colorHex: color.hasPrefix("#") ? color : "#\(color)",
            textColorHex: textColor.hasPrefix("#") ? textColor : "#\(textColor)",
            network: info.network ?? "",
            direction: info.direction ?? "",
            commercialMode: info.commercialMode ?? ""
        )
    }
}

enum TransportModeMapper {
    static func fromNavitia(raw: NavitiaJourneysResponse.NavitiaSection) -> TransportMode {
        if raw.type == "street_network", let mode = raw.mode {
            return TransportMode(rawValue: mode) ?? .walk
        }
        guard let info = raw.displayInformations else { return .bus }
        let commercial = (info.commercialMode ?? "").lowercased()
        if commercial.contains("ter") { return .ter }
        if commercial.contains("tgv") || commercial.contains("intercit") { return .intercity }
        if commercial.contains("tram") { return .tram }
        if commercial.contains("metro") { return .metro }
        if commercial.contains("bus") || commercial.contains("car") { return .bus }
        if commercial.contains("coach") { return .coach }
        return .train
    }
}

enum DepartureMapper {
    static func map(_ raw: NavitiaDeparturesResponse.NavitiaDeparture) -> Departure {
        let scheduled = NavitiaDateParser.parse(raw.stopDateTime.baseDateTime ?? raw.stopDateTime.departureDateTime) ?? Date()
        let real = NavitiaDateParser.parse(raw.stopDateTime.departureDateTime) ?? scheduled
        let mode = TransportModeMapper.fromCommercial(raw.displayInformations.commercialMode ?? "")
        let line = LineMapper.map(raw.displayInformations, mode: mode)
        return Departure(
            id: UUID().uuidString,
            line: line,
            direction: raw.route.direction.name,
            scheduledTime: scheduled,
            realTime: real,
            hasDisruption: false
        )
    }
}

extension TransportModeMapper {
    static func fromCommercial(_ commercial: String) -> TransportMode {
        let lower = commercial.lowercased()
        if lower.contains("ter") { return .ter }
        if lower.contains("tram") { return .tram }
        if lower.contains("metro") { return .metro }
        if lower.contains("bus") { return .bus }
        return .train
    }
}

enum DisruptionMapper {
    static func map(_ raw: NavitiaDisruptionsResponse.NavitiaRawDisruption) -> Disruption {
        let severity = Disruption.Severity(rawValue: raw.severity.effect) ?? .information
        let status = Disruption.Status(rawValue: raw.status) ?? .active
        let title = raw.messages.first?.text ?? "Perturbation"
        let period = raw.applicationPeriods.first
        return Disruption(
            id: raw.id,
            severity: severity,
            status: status,
            title: title,
            message: raw.messages.map(\.text).joined(separator: "\n"),
            startDate: NavitiaDateParser.parse(period?.begin),
            endDate: NavitiaDateParser.parse(period?.end),
            affectedLines: raw.impactedObjects?.compactMap { $0.ptObject?.id } ?? [],
            updatedAt: NavitiaDateParser.parse(raw.updatedAt) ?? Date()
        )
    }
}

enum NominatimMapper {
    static func map(_ result: GeocodingService.NominatimResult) -> Place {
        let city = result.address?.city ?? result.address?.town ?? result.address?.village
        return Place(
            id: "nominatim-\(result.placeId)",
            name: result.displayName.components(separatedBy: ",").first ?? result.displayName,
            type: .address,
            coordinate: Place.Coordinate(lat: Double(result.lat) ?? 0, lon: Double(result.lon) ?? 0),
            city: city,
            postalCode: result.address?.postcode,
            administrativeRegion: result.address?.county
        )
    }
}

enum ORSMapper {
    static func map(_ response: OpenRouteService.ORSResponse, profile: OpenRouteService.ORSProfile) -> Journey {
        let feature = response.features.first
        let summary = feature?.properties.summary
        let mode: TransportMode = {
            switch profile {
            case .drivingCar: return .car
            case .cyclingRegular: return .bike
            case .footWalking: return .walk
            }
        }()
        let instructions = feature?.properties.segments.flatMap { $0.steps.map(\.instruction) } ?? []
        let coords = feature?.geometry.coordinates ?? []
        let fromCoord = coords.first ?? [0, 0]
        let toCoord = coords.last ?? fromCoord
        let from = Place(
            id: UUID().uuidString,
            name: "Départ",
            type: .address,
            coordinate: Place.Coordinate(lat: fromCoord.count > 1 ? fromCoord[1] : 0, lon: fromCoord.first ?? 0),
            city: nil,
            postalCode: nil,
            administrativeRegion: nil
        )
        let to = Place(
            id: UUID().uuidString,
            name: "Arrivée",
            type: .address,
            coordinate: Place.Coordinate(lat: toCoord.count > 1 ? toCoord[1] : 0, lon: toCoord.first ?? 0),
            city: nil,
            postalCode: nil,
            administrativeRegion: nil
        )
        let polyline = SectionMapper.encodePolylineStatic(coords)
        let duration = Int(summary?.duration ?? 0)
        let section = JourneySection(
            id: UUID(),
            type: .streetNetwork,
            mode: mode,
            from: from,
            to: to,
            departureTime: Date(),
            arrivalTime: Date().addingTimeInterval(TimeInterval(duration)),
            duration: duration,
            distanceMeters: summary?.distance,
            line: nil,
            stopPoints: [],
            turnInstructions: instructions,
            encodedPolyline: polyline,
            boardingPosition: nil,
            disruptions: []
        )
        return Journey(
            id: UUID(),
            departureTime: Date(),
            arrivalTime: Date().addingTimeInterval(TimeInterval(duration)),
            duration: duration,
            waitingDuration: 0,
            walkingDuration: mode == .walk ? duration : 0,
            transfers: 0,
            co2EmissionsGrams: CO2Calculator.estimate(for: [section]),
            sections: [section],
            fare: nil,
            hasDisruptions: false
        )
    }
}

extension SectionMapper {
    static func encodePolylineStatic(_ coordinates: [[Double]]) -> String? {
        guard !coordinates.isEmpty else { return nil }
        var encoded = ""
        var lastLat = 0
        var lastLon = 0
        for coord in coordinates where coord.count >= 2 {
            let lat = Int(round(coord[1] * 1e5))
            let lon = Int(round(coord[0] * 1e5))
            encoded += PolylineEncoder.encodeValue(lat - lastLat)
            encoded += PolylineEncoder.encodeValue(lon - lastLon)
            lastLat = lat
            lastLon = lon
        }
        return encoded.isEmpty ? nil : encoded
    }
}

/// Encodeur polyline Google (inverse du décodeur)
enum PolylineEncoder {
    static func encodeValue(_ value: Int) -> String {
        var v = value < 0 ? ~(value << 1) : value << 1
        var result = ""
        while v >= 0x20 {
            result.append(Character(UnicodeScalar((0x20 | (v & 0x1f)) + 63)!))
            v >>= 5
        }
        result.append(Character(UnicodeScalar(v + 63)!))
        return result
    }
}
