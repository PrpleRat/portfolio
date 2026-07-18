import Foundation

enum BeatGenre: String, Codable, CaseIterable, Identifiable {
    case trap, drill, rnb, pop, afro, boomBap = "boom_bap", loFi = "lo_fi", autre

    var id: String { rawValue }

    var label: String {
        switch self {
        case .trap: return "Trap"
        case .drill: return "Drill"
        case .rnb: return "R&B"
        case .pop: return "Pop"
        case .afro: return "Afro"
        case .boomBap: return "Boom bap"
        case .loFi: return "Lo-fi"
        case .autre: return "Autre"
        }
    }
}

struct CatalogBeatPrices: Codable, Equatable {
    var mp3Lease: Int
    var wavLease: Int
    var trackoutLease: Int
    var exclusive: Int

    static func defaults() -> CatalogBeatPrices {
        CatalogBeatPrices(
            mp3Lease: LicenseType.mp3Lease.defaultPrice,
            wavLease: LicenseType.wavLease.defaultPrice,
            trackoutLease: LicenseType.trackoutLease.defaultPrice,
            exclusive: LicenseType.exclusive.defaultPrice
        )
    }

    func price(for type: LicenseType) -> Int {
        switch type {
        case .mp3Lease: return mp3Lease
        case .wavLease: return wavLease
        case .trackoutLease: return trackoutLease
        case .exclusive: return exclusive
        }
    }

    mutating func setPrice(_ price: Int, for type: LicenseType) {
        switch type {
        case .mp3Lease: mp3Lease = price
        case .wavLease: wavLease = price
        case .trackoutLease: trackoutLease = price
        case .exclusive: exclusive = price
        }
    }
}

struct CatalogBeat: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var bpm: Int?
    var musicalKey: String?
    var keyMode: String?
    var genre: BeatGenre
    var prices: CatalogBeatPrices
    var createdAt: Date
    var coProducer: CoProducer?

    var tonaliteLabel: String? {
        guard let musicalKey, let keyMode else { return nil }
        return "\(musicalKey) \(keyMode)"
    }
}
