import XCTest
@testable import RAS

final class PINServiceTests: XCTestCase {

    override func setUp() async throws {
        await PINService.shared.clearPIN()
        await PINService.shared.resetAttempts()
    }

    func testSetAndVerifyPIN() async {
        await PINService.shared.setPIN("123456")
        let valid = await PINService.shared.verifyPIN("123456")
        let invalid = await PINService.shared.verifyPIN("000000")
        XCTAssertTrue(valid)
        XCTAssertFalse(invalid)
    }

    func testHasPIN() async {
        XCTAssertFalse(await PINService.shared.hasPIN)
        await PINService.shared.setPIN("654321")
        XCTAssertTrue(await PINService.shared.hasPIN)
    }

    func testCustomQuestion() async {
        await PINService.shared.setCustomQuestion("Ville de naissance ?", answer: "Paris")
        XCTAssertTrue(await PINService.shared.verifyAnswer("paris"))
        XCTAssertFalse(await PINService.shared.verifyAnswer("Lyon"))
    }
}
