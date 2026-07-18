import CoreLocation
import Foundation

/// Optimisateur d'itinéraires multi-stops (heuristique plus proche voisin)
actor RouteOptimizer {

    static let shared = RouteOptimizer()
    private let navitia = NavitiaService.shared

    func optimizeStops(
        origin: Place,
        destination: Place,
        intermediates: [Place]
    ) async -> [Place] {
        guard intermediates.count > 1 else { return intermediates }

        let allPoints = [origin] + intermediates + [destination]

        guard let matrix = try? await durationMatrix(places: allPoints) else {
            return intermediates
        }

        var unvisited = Array(1...intermediates.count)
        var route: [Int] = []
        var current = 0

        while !unvisited.isEmpty {
            let nearest = unvisited.min(by: { matrix[current][$0] < matrix[current][$1] })!
            route.append(nearest)
            unvisited.removeAll { $0 == nearest }
            current = nearest
        }

        return route.map { allPoints[$0] }
    }

    private func durationMatrix(places: [Place]) async throws -> [[Int]] {
        var matrix = Array(repeating: Array(repeating: 0, count: places.count), count: places.count)

        await withTaskGroup(of: (row: Int, col: Int, duration: Int).self) { group in
            for i in 0..<places.count {
                for j in 0..<places.count where i != j {
                    group.addTask {
                        let duration = (try? await self.navitia.journeys(
                            from: places[i],
                            to: places[j]
                        ).first?.duration) ?? Int.max
                        return (row: i, col: j, duration: duration)
                    }
                }
            }

            for await result in group {
                matrix[result.row][result.col] = result.duration
            }
        }

        return matrix
    }
}
