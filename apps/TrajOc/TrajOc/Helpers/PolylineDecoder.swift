import CoreLocation
import Foundation

/// Décodage encoded polyline Google (format utilisé par Navitia/ORS)
enum PolylineDecoder {
    static func decode(_ encoded: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var index = encoded.startIndex
        var lat = 0
        var lon = 0

        while index < encoded.endIndex {
            let (newLat, nextIndex) = decodeValue(from: encoded, start: index)
            index = nextIndex
            lat += newLat

            let (newLon, nextIndex2) = decodeValue(from: encoded, start: index)
            index = nextIndex2
            lon += newLon

            coordinates.append(CLLocationCoordinate2D(
                latitude: Double(lat) / 1e5,
                longitude: Double(lon) / 1e5
            ))
        }

        return coordinates
    }

    private static func decodeValue(from encoded: String, start: String.Index) -> (Int, String.Index) {
        var result = 0
        var shift = 0
        var index = start

        while index < encoded.endIndex {
            let ascii = Int(encoded[index].asciiValue ?? 0) - 63
            index = encoded.index(after: index)
            result |= (ascii & 0x1F) << shift
            shift += 5
            if ascii < 0x20 { break }
        }

        let value = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
        return (value, index)
    }
}
