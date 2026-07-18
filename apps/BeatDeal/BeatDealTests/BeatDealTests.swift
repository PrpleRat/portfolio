import XCTest
@testable import BeatDeal

final class BeatDealTests: XCTestCase {

    func testLicenseTypeDefaults() {
        XCTAssertEqual(LicenseType.mp3Lease.defaultPrice, 29)
        XCTAssertEqual(LicenseType.exclusive.defaultMaxStreams, Int.max)
    }

    func testCoProducerValidation() {
        var co = CoProducer(name: "Alex", alias: "Prod. by Alex", sharePercent: 40)
        XCTAssertTrue(co.isValid)
        XCTAssertEqual(co.mainProducerSharePercent, 60)
    }

    func testDMKitGenerator() {
        let profile = ProducerProfile(
            producerName: "Metro",
            producerAlias: "Prod. by Metro",
            email: "p@b.com",
            paymentLinkURL: "https://paypal.me/metro",
            dmCallToAction: "Envoie-moi un DM quand c'est bon !"
        )
        let contract = sampleContract(license: .wavLease, price: 49)
        let dm = DMKitGenerator.generate(contract: contract, profile: profile)
        XCTAssertTrue(dm.contains("Dark Trap"))
        XCTAssertTrue(dm.contains("WAV Lease"))
        XCTAssertTrue(dm.contains("49"))
        XCTAssertTrue(dm.contains("paypal.me/metro"))
    }

    func testContractHTMLCoProducer() {
        var contract = sampleContract(license: .wavLease, price: 49)
        contract.coProducerName = "Alex"
        contract.coProducerAlias = "Prod. by Alex"
        contract.coProducerSharePercent = 40
        let html = ContractHTMLBuilder.buildHTML(for: contract)
        XCTAssertTrue(html.contains("Co-producteur"))
        XCTAssertTrue(html.contains("Prod. by Metro"))
        XCTAssertTrue(html.contains("Prod. by Alex"))
    }

    func testContractHTMLPack() {
        var contract = sampleContract(license: .wavLease, price: 99)
        contract.packTitle = "Pack Trap Sombre"
        contract.beatTitle = "Pack Trap Sombre"
        contract.packBeatItems = [
            LicensedBeatItem(id: "1", title: "Beat 1", bpm: 140, musicalKey: "A", keyMode: "Min"),
            LicensedBeatItem(id: "2", title: "Beat 2", bpm: 150, musicalKey: "C", keyMode: "Min"),
        ]
        let html = ContractHTMLBuilder.buildHTML(for: contract)
        XCTAssertTrue(html.contains("Pack Trap Sombre"))
        XCTAssertTrue(html.contains("Beat 1"))
        XCTAssertTrue(html.contains("Beat 2"))
    }

    func testDeliveryChecklistComplete() {
        var checklist = DeliveryChecklist()
        XCTAssertEqual(checklist.completedCount, 0)
        checklist.pdfSent = true
        checklist.paymentReceived = true
        XCTAssertFalse(checklist.isComplete)
        checklist.wavSent = true
        checklist.tagIncluded = true
        checklist.contractSignedReturned = true
        XCTAssertTrue(checklist.isComplete)
    }

    func testRoyaltyCalculatorBreakEven() {
        let spotify = StreamingPlatform(id: "spotify", name: "Spotify", ratePerStreamEUR: 0.003)
        let projection = RoyaltyCalculator.project(
            platform: spotify,
            projectedStreams: 50_000,
            licensePrice: 49,
            licenseTitle: "WAV Lease"
        )
        XCTAssertTrue(projection.isProfitable)
    }

    private func sampleContract(license: LicenseType, price: Int) -> Contract {
        Contract(
            id: "abc12345-uuid",
            createdAt: Date(),
            licenseType: license,
            artistName: "Artist",
            artistEmail: "a@b.com",
            beatTitle: "Dark Trap",
            bpm: 140,
            musicalKey: "A",
            keyMode: "Min",
            producerName: "Metro",
            producerAlias: "Prod. by Metro",
            producerEmail: "p@b.com",
            producerCountry: "France",
            price: price,
            currency: .eur,
            paymentMethod: .paypal,
            paymentReference: "",
            rights: license.defaultRights,
            maxStreams: license.defaultMaxStreams == Int.max ? 999_999 : license.defaultMaxStreams,
            additionalClauses: "",
            pdfFileName: nil,
            streamsReported: 0,
            expiresAt: Contract.defaultExpiresAt(from: Date(), licenseType: license),
            catalogBeatId: nil,
            catalogPackId: nil,
            packTitle: nil,
            packBeatItems: nil,
            coProducerName: nil,
            coProducerAlias: nil,
            coProducerSharePercent: nil,
            deliveryChecklist: DeliveryChecklist()
        )
    }
}
