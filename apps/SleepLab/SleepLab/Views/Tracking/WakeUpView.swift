import SwiftData
import SwiftUI

struct WakeUpView: View {
    let session: SleepSession
    var onDismiss: () -> Void

    @Query(
        filter: #Predicate<SleepSession> { $0.endTime != nil },
        sort: \SleepSession.startTime,
        order: .reverse
    ) private var completedSessions: [SleepSession]
    @Query(sort: \SleepFactor.consumedAt, order: .reverse) private var allFactors: [SleepFactor]
    @Query private var profiles: [UserProfile]

    @State private var showDreamJournal = false

    private var morningAction: MorningActionEngine.MorningAction? {
        guard session.kind == .night else { return nil }
        return MorningActionEngine.action(
            for: session,
            sessions: completedSessions,
            profile: profiles.first,
            recentFactors: allFactors
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text(session.kind == .nap ? "Sieste terminée" : "Bonjour !")
                        .font(.largeTitle.bold())

                    if let action = morningAction {
                        MorningActionCard(action: action)
                    }

                    SleepScoreView(
                        score: session.overallScore,
                        label: SleepScoreCalculator.labelForScore(session.overallScore, kind: session.kind)
                    )

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        reportCell("Durée", formatDuration(session.totalDuration))
                        reportCell("Efficacité", "\(session.efficiencyScore)%")
                        reportCell("Profond", "\(session.deepSleepMinutes) min")
                        reportCell("REM", "\(session.remSleepMinutes) min")
                        reportCell("Réveils", "\(session.awakenings)")
                        reportCell("Ronflements", snoreSummary)
                    }

                    if !session.snoreEvents.isEmpty {
                        SnoreTimelineView(session: session)
                    }

                    if session.avgHeartRate != nil || session.avgHRV != nil {
                        healthRow
                    }

                    NavigationLink {
                        HypnogramView(session: session)
                    } label: {
                        Label("Voir l'hypnogramme", systemImage: "chart.bar.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SleepTheme.accent)

                    NavigationLink {
                        SoundLibraryView(session: session)
                    } label: {
                        Label("Sons de la nuit (\(session.soundEvents.count))", systemImage: "waveform")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        showDreamJournal = true
                    } label: {
                        Label("Noter mon rêve de cette nuit", systemImage: "book.closed.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SleepTheme.phaseREM)

                    MedicalDisclaimer()
                }
                .padding()
            }
            .background(SleepTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { onDismiss() }
                }
            }
            .sheet(isPresented: $showDreamJournal) {
                DreamEditorView(session: session)
            }
        }
    }

    private var healthRow: some View {
        HStack {
            if let hr = session.avgHeartRate {
                reportCell("FC moy.", String(format: "%.0f bpm", hr))
            }
            if let hrv = session.avgHRV {
                reportCell("HRV", String(format: "%.0f ms", hrv))
            }
        }
    }

    private var snoreSummary: String {
        guard !session.snoreEvents.isEmpty else {
            return session.snoringMinutes > 0 ? "\(session.snoringMinutes) min" : "—"
        }
        return "\(SnoreAnalytics.formatDuration(session.totalSnoreDuration)) · \(String(format: "%.0f", session.snorePercentOfNight)) %"
    }

    private func reportCell(_ title: String, _ value: String) -> some View {
        VStack {
            Text(value).font(.headline)
            Text(title).font(.caption).foregroundStyle(SleepTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        return "\(h)h \(m)m"
    }
}
