import SwiftData
import SwiftUI

struct NightDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: SleepSession

    @Query private var linkedDreams: [DreamEntry]

    @State private var snoreEvents: [SnoreEvent] = []
    @State private var soundEventCount = 0
    @State private var showDreamEditor = false
    @State private var showDeleteConfirmation = false

    init(session: SleepSession) {
        self.session = session
        let sessionId = session.id
        _linkedDreams = Query(
            filter: #Predicate<DreamEntry> { $0.session?.id == sessionId },
            sort: \DreamEntry.dreamDate,
            order: .reverse
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SleepScoreView(
                    score: session.overallScore,
                    label: SleepScoreCalculator.labelForScore(session.overallScore, kind: session.kind)
                )
                .frame(maxWidth: .infinity)

                HStack(spacing: 8) {
                    Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(SleepTheme.textSecondary)
                    if session.isManuallyEntered {
                        Text("Manuelle")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(SleepTheme.accent.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    if session.pauseCount > 0 {
                        Text("Fractionnée · \(session.pauseCount) pause(s)")
                            .font(.caption2)
                            .foregroundStyle(SleepTheme.textSecondary)
                    }
                }

                if let theoretical = SleepPhaseTheoreticalEstimate.estimate(for: session) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Phases possibles")
                            .font(.headline)
                        TheoreticalPhaseEstimateCard(architecture: theoretical)
                        NavigationLink {
                            HypnogramView(session: session)
                        } label: {
                            Label("Voir l’hypothèse en graphique", systemImage: "chart.xyaxis.line")
                        }
                        .font(.subheadline)
                    }
                } else {
                    NavigationLink { HypnogramView(session: session) } label: {
                        Label("Hypnogramme", systemImage: "chart.xyaxis.line")
                    }
                }

                if !session.isManuallyEntered, session.snoringMinutes > 0 || !snoreEvents.isEmpty {
                    SnoreTimelineView(session: session, events: snoreEvents)
                }

                if !session.factors.isEmpty {
                    Text("Facteurs").font(.headline)
                    ForEach(session.factors, id: \.id) { factor in
                        HStack {
                            Image(systemName: factor.type.sfSymbol)
                            Text(factor.type.displayName)
                            Spacer()
                            if factor.isDailyRoutineEntry {
                                Text("Prise quotidienne")
                                    .font(.caption)
                                    .foregroundStyle(SleepTheme.textSecondary)
                            } else if !factor.unit.isEmpty, factor.value > 0 {
                                Text("\(Int(factor.value)) \(factor.unit)")
                                    .foregroundStyle(SleepTheme.textSecondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if session.nightTemperature != nil {
                    Text("Météo")
                        .font(.headline)
                    if let t = session.nightTemperature {
                        Text(String(format: "Temp. %.1f °C", t))
                    }
                    if let h = session.humidity {
                        Text(String(format: "Humidité %.0f %%", h))
                    }
                }

                if soundEventCount > 0 {
                    NavigationLink { SoundLibraryView(session: session) } label: {
                        Label("\(soundEventCount) sons de la nuit (bêta)", systemImage: "waveform")
                    }
                }

                dreamsSection
            }
            .padding()
        }
        .background(SleepTheme.background.ignoresSafeArea())
        .navigationTitle(session.kind.displayName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    if session.isManuallyEntered {
                        NavigationLink {
                            ManualSleepEntryView(sessionToEdit: session)
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .confirmationDialog(
            "Supprimer cette nuit ?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Supprimer", role: .destructive) {
                SleepSessionDeletion.delete(session, in: modelContext)
                dismiss()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Phases, ronflements IA, sons et facteurs de cette nuit seront supprimés.")
        }
        .sheet(isPresented: $showDreamEditor) {
            DreamEditorView(session: session)
        }
        .task(id: session.id) {
            await loadHeavySessionData()
        }
    }

    @MainActor
    private func loadHeavySessionData() async {
        let sessionId = session.id
        var snoreDescriptor = FetchDescriptor<SnoreEvent>(
            predicate: #Predicate<SnoreEvent> { $0.session?.id == sessionId },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        snoreDescriptor.fetchLimit = 12_000
        snoreEvents = (try? modelContext.fetch(snoreDescriptor)) ?? []

        let soundDescriptor = FetchDescriptor<SoundEvent>(
            predicate: #Predicate<SoundEvent> { $0.session?.id == sessionId }
        )
        soundEventCount = (try? modelContext.fetchCount(soundDescriptor)) ?? 0
    }

    private var dreamsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rêves").font(.headline)
            if linkedDreams.isEmpty {
                Button {
                    showDreamEditor = true
                } label: {
                    Label("Ajouter le rêve de cette nuit", systemImage: "plus.circle")
                }
            } else {
                ForEach(linkedDreams, id: \.id) { dream in
                    NavigationLink {
                        DreamDetailView(dream: dream)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dream.preview).font(.subheadline.bold())
                            if let e = dream.primaryEmotion {
                                Text(e.displayName)
                                    .font(.caption)
                                    .foregroundStyle(SleepTheme.textSecondary)
                            }
                        }
                    }
                }
                Button("Ajouter un autre rêve") { showDreamEditor = true }
                    .font(.caption)
            }
        }
    }
}
