import Foundation

enum NoteSounds {
    private static let noteNames: [String: String] = [
        "C": "C",
        "F": "F",
        "G": "G",
        "A": "A",
        "sG": "Ab",
        "B": "B",
        "sA": "Bb",
        "C2": "C",
        "D2": "D",
        "E2": "E",
        "sD2": "Eb",
        "F2": "F",
    ]

    private static let wavPositionForSuffix: [String: Int] = [
        "F": 2,
        "G": 3,
        "sG": 4,
        "A": 4,
        "sA": 5,
        "B": 5,
        "C2": 6,
        "D2": 7,
        "sD2": 8,
        "E2": 8,
        "F2": 9,
    ]

    static func wavPosition(for suffix: String) -> Int {
        guard let position = wavPositionForSuffix[suffix] else {
            fatalError("Suffixe inconnu: \(suffix)")
        }
        return position
    }

    static func soundBase(for position: Int, suffix: String) -> String {
        "pos\(position)_\(suffix)"
    }

    static func soundBase(for suffix: String) -> String {
        soundBase(for: wavPosition(for: suffix), suffix: suffix)
    }

    static func noteId(from suffix: String) -> String {
        noteNames[suffix] ?? suffix
    }

    static func padLabel(
        mode: PadLabelMode,
        noteId: String,
        position: Int? = nil,
        ringNumber: Int? = nil
    ) -> String {
        switch mode {
        case .off:
            ""
        case .position:
            "\(ringNumber ?? position ?? 0)"
        case .noteName:
            noteId
        }
    }
}
