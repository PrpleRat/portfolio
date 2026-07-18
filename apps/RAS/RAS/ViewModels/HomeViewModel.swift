import Foundation
import SwiftData
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {

    enum HomeState: Equatable {
        case noSession
        case active(timeRemaining: TimeInterval)
        case pendingCheckIn(cycle: Int)
        case alertTriggered
    }

    @Published var state: HomeState = .noSession
    @Published var activeSession: SafeSession?
    @Published var recentSessions: [SafeSession] = []
    @Published var linkedConfig: AlertConfig?

    private var timer: Timer?

    func refresh(context: ModelContext) {
        let descriptor = FetchDescriptor<SafeSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        let all = (try? context.fetch(descriptor)) ?? []
        recentSessions = Array(all.filter { !$0.isActive }.prefix(5))
        activeSession = all.first(where: \.isActive)

        if let session = activeSession {
            if session.wasAlertTriggered {
                state = .alertTriggered
            } else if let deadline = session.nextDeadline, deadline <= Date() {
                state = .pendingCheckIn(cycle: estimateCycle(session))
            } else if let deadline = session.nextDeadline {
                state = .active(timeRemaining: deadline.timeIntervalSinceNow)
            } else {
                state = .active(timeRemaining: TimeInterval(session.intervalMinutes * 60))
            }
            loadConfig(session, context: context)
        } else {
            state = .noSession
            linkedConfig = nil
        }
        startTicker()
    }

    func endSession(context: ModelContext) async {
        guard let session = activeSession else { return }
        try? await SessionManager.shared.endSession(session, context: context)
        refresh(context: context)
    }

    private func loadConfig(_ session: SafeSession, context: ModelContext) {
        guard let configId = session.alertConfigId else { return }
        let descriptor = FetchDescriptor<AlertConfig>()
        linkedConfig = (try? context.fetch(descriptor))?.first { $0.id == configId }
    }

    private func estimateCycle(_ session: SafeSession) -> Int {
        max(1, session.checkIns.count + 1)
    }

    private func startTicker() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let session = self.activeSession, session.isActive else { return }
                if session.wasAlertTriggered {
                    self.state = .alertTriggered
                    return
                }
                if let deadline = session.nextDeadline {
                    let remaining = deadline.timeIntervalSinceNow
                    if remaining <= 0 {
                        self.state = .pendingCheckIn(cycle: self.estimateCycle(session))
                    } else {
                        self.state = .active(timeRemaining: remaining)
                    }
                }
            }
        }
    }

    deinit {
        timer?.invalidate()
    }
}
