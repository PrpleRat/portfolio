import Foundation

struct StreamingPlatform: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let ratePerStreamEUR: Double
}

struct RoyaltyRatesFile: Codable {
    let defaultPlatformId: String
    let platforms: [StreamingPlatform]
}

enum RoyaltyRates {
    static let shared: RoyaltyRatesFile = load()

    static func load() -> RoyaltyRatesFile {
        guard let url = Bundle.main.url(forResource: "royalty_rates", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(RoyaltyRatesFile.self, from: data) else {
            return RoyaltyRatesFile(
                defaultPlatformId: "spotify",
                platforms: [StreamingPlatform(id: "spotify", name: "Spotify", ratePerStreamEUR: 0.003)]
            )
        }
        return file
    }

    static func platform(id: String) -> StreamingPlatform? {
        shared.platforms.first { $0.id == id }
    }

    static var defaultPlatform: StreamingPlatform {
        platform(id: shared.defaultPlatformId) ?? shared.platforms[0]
    }
}

struct RoyaltyProjection: Equatable {
    let platform: StreamingPlatform
    let projectedStreams: Int
    let licensePrice: Int
    let licenseTitle: String
    let estimatedRevenueEUR: Double
    let breakEvenStreams: Int
    let isProfitable: Bool

    var summaryLine: String {
        let revenue = estimatedRevenueEUR.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
        let rate = platform.ratePerStreamEUR.formatted(.number.precision(.fractionLength(3)))
        return "Si ton son fait \(projectedStreams.formatted()) streams sur \(platform.name) (~\(rate) €/stream), t'aurais gagné environ \(revenue)."
    }

    var breakEvenLine: String {
        "Ton \(licenseTitle) te coûte \(licensePrice) €, c'est rentable dès \(breakEvenStreams.formatted()) streams."
    }
}

enum RoyaltyCalculator {

    static func project(
        platform: StreamingPlatform,
        projectedStreams: Int,
        licensePrice: Int,
        licenseTitle: String
    ) -> RoyaltyProjection {
        let revenue = Double(projectedStreams) * platform.ratePerStreamEUR
        let breakEven = licensePrice > 0
            ? Int(ceil(Double(licensePrice) / platform.ratePerStreamEUR))
            : 0
        return RoyaltyProjection(
            platform: platform,
            projectedStreams: projectedStreams,
            licensePrice: licensePrice,
            licenseTitle: licenseTitle,
            estimatedRevenueEUR: revenue,
            breakEvenStreams: breakEven,
            isProfitable: revenue >= Double(licensePrice)
        )
    }
}
