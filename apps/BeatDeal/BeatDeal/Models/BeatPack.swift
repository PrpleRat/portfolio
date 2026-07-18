import Foundation

struct BeatPack: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var beatIds: [String]
    var prices: CatalogBeatPrices
    var createdAt: Date

    func beats(from catalog: [CatalogBeat]) -> [CatalogBeat] {
        beatIds.compactMap { id in catalog.first { $0.id == id } }
    }

    var beatCountLabel: String {
        "\(beatIds.count) beat\(beatIds.count > 1 ? "s" : "")"
    }
}
