import Foundation

/// Ligne de transport (TER 12345, Bus 23, Métro A...)
struct TransitLine: Codable, Equatable {
    let id: String
    let code: String
    let name: String
    let mode: TransportMode
    let colorHex: String
    let textColorHex: String
    let network: String
    let direction: String?
    let commercialMode: String
}
