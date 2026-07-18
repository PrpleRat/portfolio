import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var tracker: SleepTracker
    @Query private var profiles: [UserProfile]
    @Query(
        filter: #Predicate<SleepSession> { $0.endTime != nil },
        sort: \SleepSession.startTime,
        order: .reverse
    ) private var sessions: [SleepSession]

    @State private var sessionPendingDeletion: SleepSession?
    @State private var showDeleteConfirmation = false
    @State private var recoveryMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "Aucun sommeil",
                        systemImage: "moon.zzz",
                        description: Text("Tes nuits et siestes apparaîtront ici.")
                    )
                } else {
                    List {
                        ForEach(sessions) { session in
                            NavigationLink {
                                NightDetailView(session: session)
                            } label: {
                                HistoryRow(session: session)
                            }
                            .listRowBackground(SleepTheme.card)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    sessionPendingDeletion = session
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(SleepTheme.background.ignoresSafeArea())
            .navigationTitle("Historique")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            recoverInterruptedNights()
                        } label: {
                            Label("Récupérer nuit interrompue", systemImage: "arrow.clockwise.circle")
                        }
                        NavigationLink {
                            ManualSleepEntryView()
                        } label: {
                            Label("Ajouter manuellement", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Actions historique")
                }
            }
            .confirmationDialog(
                "Supprimer cet enregistrement ?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Supprimer", role: .destructive) {
                    if let session = sessionPendingDeletion {
                        SleepSessionDeletion.delete(session, in: modelContext)
                    }
                    sessionPendingDeletion = nil
                }
                Button("Annuler", role: .cancel) {
                    sessionPendingDeletion = nil
                }
            } message: {
                if let session = sessionPendingDeletion {
                    Text("Cette \(session.kind.displayName.lowercased()) du \(session.startTime.formatted(date: .abbreviated, time: .omitted)) sera effacée. Action irréversible.")
                }
            }
            .alert("Récupération", isPresented: Binding(
                get: { recoveryMessage != nil },
                set: { if !$0 { recoveryMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                if let recoveryMessage {
                    Text(recoveryMessage)
                }
            }
        }
    }

    private func recoverInterruptedNights() {
        do {
            _ = try SleepNightGrouper.mergeFragmentedWakeDaySessions(in: modelContext)
            let recovered = try InterruptedSleepRecovery.recoverSessions(
                in: modelContext,
                profile: profiles.first,
                skipIfTracking: tracker.isTracking
            )
            _ = try SleepNightGrouper.mergeFragmentedWakeDaySessions(in: modelContext)
            if recovered.isEmpty {
                recoveryMessage =
                    "Aucune nuit interrompue trouvée. Si la nuit a totalement disparu, ajoute-la manuellement avec « Ajouter manuellement »."
            } else {
                recoveryMessage =
                    "\(recovered.count) nuit(s) récupérée(s). Vérifie les horaires dans le détail — la fin a été estimée au dernier signal enregistré."
            }
        } catch {
            recoveryMessage = "Récupération impossible : \(error.localizedDescription)"
        }
    }
}

private struct HistoryRow: View {
    let session: SleepSession

    var body: some View {
        HStack {
            Image(systemName: session.kind.systemImage)
                .foregroundStyle(SleepTheme.accent)
                .frame(width: 28)
            VStack(alignment: .leading) {
                HStack {
                    Text(session.startTime.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                    Text(session.kind.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(SleepTheme.accent.opacity(0.2))
                        .clipShape(Capsule())
                }
                Text(durationText)
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
            Spacer()
            Text("\(session.overallScore)")
                .font(.title2.bold())
                .foregroundStyle(scoreColor)
        }
        .padding(.vertical, 4)
    }

    private var durationText: String {
        let h = Int(session.totalDuration) / 3600
        let m = (Int(session.totalDuration) % 3600) / 60
        if session.kind == .nap {
            return "\(h)h\(m)m · Sieste"
        }
        if session.isManuallyEntered,
           let est = SleepPhaseTheoreticalEstimate.estimate(for: session) {
            return "\(h)h\(m)m · ~\(est.deepMinutes)m profond (estimé)"
        }
        if session.deepSleepMinutes > 0 {
            return "\(h)h\(m)m · Profond \(session.deepSleepMinutes)m"
        }
        return "\(h)h\(m)m"
    }

    private var scoreColor: Color {
        switch session.overallScore {
        case 81...100: return .green
        case 61...80: return SleepTheme.accent
        case 41...60: return .yellow
        default: return SleepTheme.phaseAwake
        }
    }
}
