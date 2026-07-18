import ActivityKit
import Foundation

@MainActor
enum SleepLiveActivityManager {
    private static var activity: Activity<SleepTrackingAttributes>?

    static var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    @discardableResult
    static func start(sessionKind: SleepSessionKind) -> Bool {
        guard isSupported else { return false }
        end()

        let attributes = SleepTrackingAttributes(sessionKindTitle: sessionKind.displayName)
        let state = SleepTrackingAttributes.ContentState(
            phaseName: SleepPhaseType.light.displayName,
            elapsedText: "0h00",
            isPaused: false,
            sessionKindTitle: sessionKind.displayName
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            return true
        } catch {
            return false
        }
    }

    static func update(phase: SleepPhaseType, elapsed: TimeInterval, isPaused: Bool, kind: SleepSessionKind) {
        guard let activity else { return }
        let h = Int(elapsed) / 3600
        let m = (Int(elapsed) % 3600) / 60
        let state = SleepTrackingAttributes.ContentState(
            phaseName: isPaused ? "En pause" : phase.displayName,
            elapsedText: String(format: "%dh%02d", h, m),
            isPaused: isPaused,
            sessionKindTitle: kind.displayName
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    static func end() {
        guard let activity else { return }
        let final = SleepTrackingAttributes.ContentState(
            phaseName: "Terminé",
            elapsedText: "—",
            isPaused: false,
            sessionKindTitle: activity.attributes.sessionKindTitle
        )
        Task {
            await activity.end(.init(state: final, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.activity = nil
    }
}
