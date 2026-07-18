import Combine
import Foundation

@MainActor
final class NotePlaybackTracker: ObservableObject {
    private struct PadGlow {
        let peak: Double
        let start: Date
        let end: Date

        var isFinished: Bool { Date() > end }

        func currentGlow(at now: Date = Date()) -> Double {
            guard now <= end else { return 0 }
            let total = end.timeIntervalSince(start)
            guard total > 0 else { return 0 }
            let elapsed = now.timeIntervalSince(start)
            let life = min(max(elapsed / total, 0), 1)
            let decay = pow(1 - life, 1.45)
            return min(max(peak * decay * 1.12, 0), 1)
        }
    }

    @Published private var pads: [String: PadGlow] = [:]
    private var tickTimer: Timer?

    func glow(for padId: String) -> Double {
        pads[padId]?.currentGlow() ?? 0
    }

    func registerPlayback(padId: String, durationMs: Int, peakIntensity: Double) {
        guard durationMs > 0 else { return }

        let now = Date()
        let proposedEnd = now.addingTimeInterval(Double(durationMs) / 1000.0)
        let existing = pads[padId]
        let end = (existing?.end ?? .distantPast) > proposedEnd ? existing!.end : proposedEnd

        pads[padId] = PadGlow(peak: peakIntensity, start: now, end: end)
        ensureTicking()
    }

    private func ensureTicking() {
        guard tickTimer == nil else { return }
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.pads = self.pads.filter { !$0.value.isFinished }
                if self.pads.isEmpty {
                    self.tickTimer?.invalidate()
                    self.tickTimer = nil
                }
            }
        }
    }
}
