import SwiftData
import SwiftUI

/// Saisie ou modification d’une nuit / sieste manuelle.
struct ManualSleepEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    /// Si présent : mode édition.
    var sessionToEdit: SleepSession?

    @StateObject private var healthKit = HealthKitService()

    @State private var kind: SleepSessionKind = .night
    @State private var startTime = Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date()
    @State private var endTime = Date()
    @State private var score: Int = 70
    @State private var syncToHealth = false
    @State private var errorMessage: String?
    @State private var isSaving = false

    private var isEditing: Bool { sessionToEdit != nil }

    private var theoreticalPreview: TheoreticalSleepArchitecture? {
        guard endTime > startTime else { return nil }
        return SleepPhaseTheoreticalEstimate.estimate(duration: endTime.timeIntervalSince(startTime))
    }

    var body: some View {
        Form {
            if isEditing {
                Section {
                    Text("Modification d’une nuit saisie à la main. Les nuits enregistrées par le capteur ne sont pas modifiables ici.")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.textSecondary)
                }
            }

            Section("Type") {
                Picker("Enregistrement", selection: $kind) {
                    Text(SleepSessionKind.night.displayName).tag(SleepSessionKind.night)
                    Text(SleepSessionKind.nap.displayName).tag(SleepSessionKind.nap)
                }
                .pickerStyle(.segmented)
            }

            Section("Horaires") {
                DatePicker("Coucher / début", selection: $startTime)
                DatePicker("Réveil / fin", selection: $endTime)
                if endTime <= startTime {
                    Text("L’heure de fin doit être après le début.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section("Score") {
                Stepper("Score global : \(score)", value: $score, in: 0...100, step: 5)
            }

            if let preview = theoreticalPreview {
                Section {
                    TheoreticalPhaseEstimateCard(architecture: preview, compact: true)
                } header: {
                    Text("Phases possibles (indicatif)")
                } footer: {
                    Text("Basé uniquement sur la durée saisie — modèle théorique, pas une mesure.")
                }
            }

            if !isEditing {
                Section("App Santé") {
                    Toggle("Exporter vers Santé", isOn: $syncToHealth)
                }
            } else {
                Section("App Santé") {
                    Button("Ré-exporter vers Santé") {
                        Task {
                            guard let session = sessionToEdit else { return }
                            await healthKit.exportSessionToHealth(session)
                        }
                    }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red).font(.caption)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(SleepTheme.background.ignoresSafeArea())
        .navigationTitle(isEditing ? "Modifier la nuit" : "Nuit manuelle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Enregistrer") { save() }
                    .disabled(isSaving || endTime <= startTime)
            }
        }
        .onAppear(perform: loadFromSession)
    }

    private func loadFromSession() {
        guard let session = sessionToEdit else { return }
        kind = session.kind
        startTime = session.startTime
        endTime = session.endTime ?? Date()
        score = session.overallScore
    }

    private func save() {
        guard endTime > startTime else {
            errorMessage = "Vérifie les horaires."
            return
        }
        let duration = endTime.timeIntervalSince(startTime)
        if kind == .night, duration < 2 * 3600 {
            errorMessage = "Une nuit fait au moins 2 h."
            return
        }
        if kind == .nap, duration > 3 * 3600 {
            errorMessage = "Une sieste dépasse rarement 3 h."
            return
        }

        isSaving = true
        let session: SleepSession
        if let existing = sessionToEdit {
            session = existing
            session.phases.forEach { modelContext.delete($0) }
            session.phases.removeAll()
        } else {
            session = SleepSession(startTime: startTime, kind: kind)
            session.isManuallyEntered = true
            modelContext.insert(session)
        }

        session.kind = kind
        session.startTime = startTime
        session.endTime = endTime
        session.totalDuration = duration
        session.overallScore = score
        session.efficiencyScore = min(100, Int((duration / (duration + 1800)) * 100))
        session.isManuallyEntered = true

        let phase = SleepPhase(
            startTime: startTime,
            endTime: endTime,
            phaseType: .light,
            movementScore: 0
        )
        phase.session = session
        session.phases.append(phase)
        modelContext.insert(phase)

        SleepScoreCalculator.apply(to: session, profile: profiles.first)

        Task {
            if syncToHealth || isEditing {
                await healthKit.exportSessionToHealth(session)
            }
            await MainActor.run {
                try? modelContext.save()
                isSaving = false
                dismiss()
            }
        }
    }

}
