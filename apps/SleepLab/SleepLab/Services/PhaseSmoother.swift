import Foundation

/// Lisse les phases dans le temps (évite les sauts erratiques).
final class PhaseSmoother {
    private var history: [SleepPhaseType] = []
    private let windowSize = 50
    private var lastPublished: SleepPhaseType = .light

    func reset() {
        history.removeAll(keepingCapacity: false)
        lastPublished = .light
    }

    func smooth(_ proposed: SleepPhaseType) -> SleepPhaseType {
        history.append(proposed)
        if history.count > windowSize {
            history.removeFirst(history.count - windowSize)
        }
        guard !history.isEmpty else { return proposed }

        let counts = Dictionary(grouping: history, by: { $0 }).mapValues(\.count)
        let majority = counts.max(by: { $0.value < $1.value })?.key ?? proposed

        let deepCount = history.filter { $0 == .deep }.count
        let remCount = history.filter { $0 == .rem }.count
        let n = history.count

        if majority == .deep {
            guard Double(deepCount) / Double(n) >= 0.38 else {
                return fallbackExcluding(.deep, default: .light)
            }
        }

        if majority == .rem {
            guard Double(remCount) / Double(n) >= 0.32 else {
                return fallbackExcluding(.rem, default: .light)
            }
        }

        if proposed == .awake, counts[.awake, default: 0] >= 8 {
            lastPublished = .awake
            return .awake
        }

        lastPublished = majority
        return majority
    }

    private func fallbackExcluding(_ excluded: SleepPhaseType, default fallback: SleepPhaseType) -> SleepPhaseType {
        let filtered = history.filter { $0 != excluded }
        guard !filtered.isEmpty else { return fallback }
        let counts = Dictionary(grouping: filtered, by: { $0 }).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key ?? fallback
    }
}
