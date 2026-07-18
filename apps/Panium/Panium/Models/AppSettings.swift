import Foundation

enum AudioStatus: Equatable {
    case loading
    case ready
    case unavailable
}

enum PadLabelMode: String, CaseIterable, Identifiable {
    case off
    case position
    case noteName

    var id: String { rawValue }

    var label: String {
        switch self {
        case .off: "Off"
        case .position: "#"
        case .noteName: "Notes"
        }
    }
}

struct TuningOption: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let rate: Double
}

enum Tunings {
    static let defaultRate = 1.0
    static let rate432 = 432.0 / 440.0

    static let options: [TuningOption] = [
        TuningOption(label: "440 Hz", rate: defaultRate),
        TuningOption(label: "432 Hz", rate: rate432),
    ]
}

struct ReverbOption: Identifiable, Equatable {
    let level: Int
    let label: String

    var id: Int { level }
}

enum ReverbLevels {
    static let defaultLevel = 1

    static let options: [ReverbOption] = [
        ReverbOption(level: 0, label: "Reverb 1"),
        ReverbOption(level: 1, label: "Reverb 2"),
        ReverbOption(level: 2, label: "Reverb 3"),
    ]

    static func soundWithReverb(_ soundBase: String, level: Int) -> String {
        "\(soundBase)_v\(level)"
    }
}
