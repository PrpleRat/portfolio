import XCTest
@testable import Panium

final class PaniumTests: XCTestCase {
    func testHandpanConfigsCount() {
        XCTAssertEqual(HandpanConfigs.all.count, 7)
    }

    func testDefaultConfigIsAeolian() {
        XCTAssertEqual(HandpanConfigs.all[0].name, "Minor (Aeolian)")
        XCTAssertEqual(HandpanConfigs.all[0].outerPadCount, 8)
    }

    func testReverbSoundNaming() {
        XCTAssertEqual(ReverbLevels.soundWithReverb("pos1_C", level: 2), "pos1_C_v2")
    }

    func testCompactRingPadCount() {
        let mystic = HandpanConfigs.all.first { $0.name == "Mystic" }!
        XCTAssertEqual(mystic.outerPadCount, 6)
        XCTAssertTrue(mystic.usesCompactRing)
    }

    func testNoteSoundBase() {
        XCTAssertEqual(NoteSounds.soundBase(for: 1, suffix: "C"), "pos1_C")
        XCTAssertEqual(NoteSounds.noteId(from: "sA"), "Bb")
    }
}
