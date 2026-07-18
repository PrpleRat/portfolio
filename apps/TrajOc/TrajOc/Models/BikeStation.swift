import Foundation

/// Station vélo en libre-service (JCDecaux)
struct BikeStation: Identifiable, Equatable {
    let id: Int
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let totalStands: Int
    let availableBikes: Int
    let availableStands: Int
    let isOpen: Bool
    let hasCardPayment: Bool
    let lastUpdate: Date?
    let contract: String

    var occupancyRatio: Double {
        guard totalStands > 0 else { return 0 }
        return Double(availableBikes) / Double(totalStands)
    }
}
