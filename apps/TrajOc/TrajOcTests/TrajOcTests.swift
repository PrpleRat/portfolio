import CoreLocation
import XCTest
@testable import TrajOc

final class PolylineDecoderTests: XCTestCase {
    func testDecodeSimplePolyline() {
        // Polyline encodée pour un segment Toulouse → approx
        let encoded = "_p~iF~ps|U_ulLnnqC_mqNvxq`@"
        let coords = PolylineDecoder.decode(encoded)
        XCTAssertFalse(coords.isEmpty)
        XCTAssertGreaterThanOrEqual(coords.count, 2)
    }

    func testRoundTripEncodeDecode() {
        let original = [
            CLLocationCoordinate2D(latitude: 43.6114, longitude: 1.4531),
            CLLocationCoordinate2D(latitude: 43.6047, longitude: 3.8805)
        ]
        let encoded = SectionMapper.encodePolylineStatic(original.map { [$0.longitude, $0.latitude] })
        XCTAssertNotNil(encoded)
        let decoded = PolylineDecoder.decode(encoded!)
        XCTAssertEqual(decoded.count, original.count)
    }
}

final class DurationFormatterTests: XCTestCase {
    func testFormatSeconds() {
        XCTAssertEqual(DurationFormatter.format(seconds: 45), "45 min")
        XCTAssertEqual(DurationFormatter.format(seconds: 3600), "1h")
        XCTAssertEqual(DurationFormatter.format(seconds: 5580), "1h 33min")
    }
}

final class CO2CalculatorTests: XCTestCase {
    func testWalkZeroEmissions() {
        let section = JourneySection(
            id: UUID(),
            type: .streetNetwork,
            mode: .walk,
            from: samplePlace(name: "A"),
            to: samplePlace(name: "B"),
            departureTime: nil,
            arrivalTime: nil,
            duration: 600,
            distanceMeters: 500,
            line: nil,
            stopPoints: [],
            turnInstructions: [],
            encodedPolyline: nil,
            boardingPosition: nil,
            disruptions: []
        )
        XCTAssertEqual(CO2Calculator.estimate(for: [section]), 0, accuracy: 0.1)
    }
}

final class RouteOptimizerTests: XCTestCase {
    func testSingleIntermediateReturnsSameOrder() async {
        let origin = samplePlace(name: "Origin")
        let dest = samplePlace(name: "Dest")
        let stop = samplePlace(name: "Stop", lat: 43.5, lon: 1.5)
        let result = await RouteOptimizer.shared.optimizeStops(
            origin: origin,
            destination: dest,
            intermediates: [stop]
        )
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Stop")
    }
}

final class PlaceMapperTests: XCTestCase {
    func testNavitiaCoordParsing() {
        let coord = NavitiaJourneysResponse.NavitiaPlace.NavitiaCoord(lat: "43.6114", lon: "1.4531")
        XCTAssertEqual(coord.latitude, 43.6114, accuracy: 0.0001)
        XCTAssertEqual(coord.longitude, 1.4531, accuracy: 0.0001)
    }
}

private func samplePlace(name: String, lat: Double = 43.6, lon: Double = 1.44) -> Place {
    Place(
        id: UUID().uuidString,
        name: name,
        type: .address,
        coordinate: Place.Coordinate(lat: lat, lon: lon),
        city: "Toulouse",
        postalCode: nil,
        administrativeRegion: "Haute-Garonne"
    )
}
