import SwiftData
import SwiftUI

struct AlarmRingView: View {
    @EnvironmentObject private var tracker: SleepTracker
    @Query(sort: \SleepSession.startTime, order: .reverse) private var sessions: [SleepSession]

    @State private var showDismissHUD = false

    private var sessionForHUD: SleepSession? {
        tracker.currentSession ?? tracker.lastCompletedSession ?? sessions.first { $0.endTime != nil }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [SleepTheme.phaseREM.opacity(0.35), SleepTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Text("Bon réveil")
                    .font(.largeTitle.bold())
                    .foregroundStyle(SleepTheme.textPrimary)

                Image(systemName: "sun.max.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(SleepTheme.accent)
                    .symbolEffect(.pulse)

                Text("Réveil dans ta fenêtre de sommeil léger")
                    .font(.subheadline)
                    .foregroundStyle(SleepTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Arrêter le réveil") {
                    dismissAlarm()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(SleepTheme.accent)
            }
            .padding()

            if showDismissHUD, let session = sessionForHUD {
                AlarmDismissHUD(session: session) {
                    showDismissHUD = false
                    tracker.smartAlarm?.stopAlarm()
                    Task { await tracker.stopNight() }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func dismissAlarm() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            showDismissHUD = true
        }
    }
}

struct AlarmDismissHUD: View {
    let session: SleepSession
    let onContinue: () -> Void

    private var deepestPhaseTime: String {
        let deepest = session.phases
            .filter { $0.phaseType == .deep }
            .max(by: { $0.duration < $1.duration })
        guard let phase = deepest else { return "—" }
        return phase.startTime.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 16) {
                Text("Ta nuit en bref")
                    .font(.headline)
                    .foregroundStyle(SleepTheme.textPrimary)

                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("\(session.overallScore)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(SleepTheme.accent)
                        Text("Score")
                            .font(.caption)
                            .foregroundStyle(SleepTheme.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        hudRow("Durée", formatDuration(session.totalDuration))
                        hudRow("Sommeil profond", deepestPhaseTime)
                    }
                }

                Button("Continuer") {
                    onContinue()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .tint(SleepTheme.accent)
            }
            .padding(20)
            .background(SleepTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 20, y: -4)
            .padding()
        }
    }

    private func hudRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(SleepTheme.textPrimary)
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        return "\(h) h \(m) min"
    }
}
