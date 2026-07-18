import Foundation

struct HandpanPadSlot: Identifiable, Equatable {
    let position: Int
    let ringIndex: Int?
    let sound: String
    let noteId: String

    var id: String { padId }

    var displayNumber: Int {
        ringIndex.map { $0 + 2 } ?? position
    }

    var padId: String {
        if let ringIndex {
            "ring_\(ringIndex)"
        } else {
            HandpanLayout.padId(for: position)
        }
    }

    static func fromSuffix(_ suffix: String, ringIndex: Int? = nil) -> HandpanPadSlot {
        let position = NoteSounds.wavPosition(for: suffix)
        return HandpanPadSlot(
            position: position,
            ringIndex: ringIndex,
            sound: NoteSounds.soundBase(for: position, suffix: suffix),
            noteId: NoteSounds.noteId(from: suffix)
        )
    }
}

struct HandpanConfig: Identifiable, Equatable {
    let name: String
    let padsByPosition: [Int: HandpanPadSlot]
    let compactOuterOrder: [String]?

    var id: String { name }

    var center: HandpanPadSlot? { padsByPosition[1] }

    var usesCompactRing: Bool { compactOuterOrder != nil }

    var displayOuterPads: [HandpanPadSlot] {
        if let compactOuterOrder {
            return compactOuterOrder.enumerated().map { index, suffix in
                HandpanPadSlot.fromSuffix(suffix, ringIndex: index)
            }
        }
        return activeOuterPads
    }

    var activeOuterPads: [HandpanPadSlot] {
        HandpanLayout.outerPositions.compactMap { padsByPosition[$0] }
    }

    var outerPadCount: Int { displayOuterPads.count }
}
