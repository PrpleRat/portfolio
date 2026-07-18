import Foundation

enum HandpanConfigs {
    private typealias Layout = [Int: String]

    private static let aeolian: Layout = [
        1: "C", 2: "F", 3: "G", 4: "sG", 5: "sA",
        6: "C2", 7: "D2", 8: "sD2", 9: "F2",
    ]

    private static let harmonicMinor: Layout = [
        1: "C", 2: "F", 3: "G", 4: "sG", 5: "B",
        6: "C2", 7: "D2", 8: "sD2", 9: "F2",
    ]

    private static let celticOuter = ["G", "sA", "C2", "D2", "sD2", "F2", "G", "C2"]
    private static let kurdOuter = ["G", "sG", "sA", "C2", "D2", "sD2", "F2", "G"]
    private static let mysticOuter = ["G", "sA", "C2", "D2", "sD2", "F2"]
    private static let majorPentatonicOuter = ["G", "A", "C2", "D2", "E2"]
    private static let akebonoOuter = ["F", "G", "sG", "sD2"]

    static let all: [HandpanConfig] = [
        fullConfig(name: "Minor (Aeolian)", layout: aeolian),
        compactConfig(name: "Celtic Minor", center: "C", outerInPitchOrder: celticOuter),
        compactConfig(name: "Kurd", center: "C", outerInPitchOrder: kurdOuter),
        compactConfig(name: "Mystic", center: "C", outerInPitchOrder: mysticOuter),
        compactConfig(name: "Major Pentatonic", center: "C", outerInPitchOrder: majorPentatonicOuter),
        compactConfig(name: "Akebono", center: "C", outerInPitchOrder: akebonoOuter),
        fullConfig(name: "Harmonic Minor", layout: harmonicMinor),
    ]

    private static func fullConfig(name: String, layout: Layout) -> HandpanConfig {
        var pads: [Int: HandpanPadSlot] = [:]
        for (position, suffix) in layout {
            pads[position] = HandpanPadSlot(
                position: position,
                ringIndex: nil,
                sound: NoteSounds.soundBase(for: position, suffix: suffix),
                noteId: NoteSounds.noteId(from: suffix)
            )
        }
        return HandpanConfig(name: name, padsByPosition: pads, compactOuterOrder: nil)
    }

    private static func compactConfig(
        name: String,
        center: String,
        outerInPitchOrder: [String]
    ) -> HandpanConfig {
        HandpanConfig(
            name: name,
            padsByPosition: [
                1: HandpanPadSlot(
                    position: 1,
                    ringIndex: nil,
                    sound: NoteSounds.soundBase(for: 1, suffix: center),
                    noteId: NoteSounds.noteId(from: center)
                ),
            ],
            compactOuterOrder: outerInPitchOrder
        )
    }
}
