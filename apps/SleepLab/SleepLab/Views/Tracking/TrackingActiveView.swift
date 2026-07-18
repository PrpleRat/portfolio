import SwiftUI

struct TrackingActiveView: View {
    @EnvironmentObject private var tracker: SleepTracker
    @Environment(\.dismiss) private var dismiss
    /// Ferme l’écran plein écran tracking (ex. après « OK » sur le rapport du matin).
    var onComplete: () -> Void = {}
    @State private var showMorningFeedback = false
    @State private var showWakeUp = false

    var body: some View {
        ZStack {
            SleepTheme.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(SleepTheme.accent)
                    .symbolEffect(.pulse)

                Text(currentTimeString)
                    .font(.system(size: 56, weight: .thin, design: .rounded))
                    .monospacedDigit()

                Text(tracker.currentSession?.kind.trackingTitle ?? "Tracking actif")
                    .font(.headline)
                    .foregroundStyle(SleepTheme.textSecondary)

                phaseIndicator

                HStack(spacing: 24) {
                    metric(icon: "waveform", value: String(format: "%.0f dB", tracker.soundMonitor.currentDBLevel))
                    metric(icon: "figure.walk", value: tracker.motionAnalyzer.currentPhase.displayName)
                }

                if let alarm = tracker.smartAlarm {
                    Text("Réveil vers \(formatTime(alarm.targetWakeTime))")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.textSecondary)
                }

                Text("Pose l'iPhone sur le matelas, écran vers le bas.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if !tracker.audioMonitoringEnabled {
                    Text("Micro non actif — suivi mouvement uniquement. Active le micro dans Réglages → \(AppBrand.displayName) pour l’audio.")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if tracker.isPaused {
                    Text("Pause — même nuit (réveil nocturne). Reprends quand tu te recouches.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if let session = tracker.currentSession, session.pauseCount > 0, !tracker.isPaused {
                    Text("Nuit fractionnée · \(session.pauseCount) pause(s)")
                        .font(.caption2)
                        .foregroundStyle(SleepTheme.textSecondary)
                }

                if tracker.snoreDetection.detectionsThisSession > 0 {
                    Text("Ronflements IA : \(tracker.snoreDetection.detectionsThisSession) s détecté(s)")
                        .font(.caption2)
                        .foregroundStyle(.red.opacity(0.9))
                }
                if let last = tracker.currentSession?.soundEvents.max(by: { $0.timestamp < $1.timestamp }) {
                    Text("Dernier son : \(SoundEventFormatting.clockLabel(for: last.timestamp))")
                        .font(.caption2)
                        .foregroundStyle(SleepTheme.textSecondary)
                }

                Spacer()

                if tracker.smartAlarm?.isRinging == true {
                    NavigationLink { AlarmRingView() } label: {
                        Text("Réveil !")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SleepTheme.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                }

                if tracker.isPaused {
                    Button("Reprendre le sommeil") {
                        Task { await tracker.resumeTracking() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SleepTheme.accent)
                } else {
                    Button("Pause (réveil nocturne)") {
                        tracker.pauseTracking()
                    }
                    .buttonStyle(.bordered)
                }

                Button(tracker.currentSession?.kind == .nap ? "Terminer la sieste" : "Terminer la nuit") {
                    Task {
                        await tracker.stopNight()
                        let isNight = tracker.lastCompletedSession?.kind == .night
                        if isNight, SleepCalibrationManager.shared.shouldShowMorningFeedback {
                            showMorningFeedback = true
                        } else {
                            showWakeUp = true
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(SleepTheme.phaseAwake)
                .padding(.bottom, 40)
            }
            .padding()
        }
        .sheet(isPresented: $showMorningFeedback) {
            MorningFeedbackView {
                showMorningFeedback = false
                showWakeUp = true
            }
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
        }
        .fullScreenCover(isPresented: $showWakeUp) {
            if let session = tracker.lastCompletedSession {
                WakeUpView(session: session) {
                    showWakeUp = false
                    onComplete()
                }
            } else {
                Color.clear.onAppear {
                    showWakeUp = false
                    onComplete()
                }
            }
        }
        .onAppear {
            if !tracker.isTracking, tracker.lastCompletedSession != nil {
                showWakeUp = true
            }
        }
        .onChange(of: tracker.smartAlarm?.isRinging) { _, ringing in
            if ringing == true { /* AlarmRingView via navigation */ }
        }
    }

    private var phaseIndicator: some View {
        HStack(spacing: 8) {
            ForEach(SleepPhaseType.allCases, id: \.self) { phase in
                Circle()
                    .fill(SleepTheme.phaseColor(phase))
                    .frame(width: tracker.motionAnalyzer.currentPhase == phase ? 14 : 8,
                           height: tracker.motionAnalyzer.currentPhase == phase ? 14 : 8)
            }
        }
    }

    private func metric(icon: String, value: String) -> some View {
        VStack {
            Image(systemName: icon)
            Text(value).font(.caption)
        }
        .foregroundStyle(SleepTheme.textSecondary)
    }

    private var currentTimeString: String {
        formatTime(Date())
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
