import SwiftData
import SwiftUI

/// Démarrage sieste avec types recommandés et effets énergie / inertie.
struct NapStartView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @EnvironmentObject private var tracker: SleepTracker

    var onStart: () -> Void

    @State private var selectedKind: NapAdvisorEngine.NapKind = .recovery
    @State private var isStarting = false
    @State private var startError: String?

    private var plans: [NapAdvisorEngine.NapPlan] {
        NapAdvisorEngine.plans(now: Date(), chronotype: profiles.first?.chronotype ?? .neutral)
    }

    private var selectedPlan: NapAdvisorEngine.NapPlan {
        plans.first { $0.kind == selectedKind } ?? NapAdvisorEngine.plan(for: selectedKind)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerBlock
                    napTypePicker
                    planDetailCard
                    startButton
                }
                .padding()
            }
            .background(SleepTheme.background.ignoresSafeArea())
            .navigationTitle("Sieste")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
            .onAppear {
                tracker.configure(context: modelContext, profile: profiles.first, alarm: nil)
            }
            .alert("Impossible de démarrer", isPresented: Binding(
                get: { startError != nil },
                set: { if !$0 { startError = nil } }
            )) {
                Button("OK", role: .cancel) { startError = nil }
            } message: {
                Text(startError ?? "")
            }
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "sun.horizon.fill")
                .font(.largeTitle)
                .foregroundStyle(SleepTheme.accent)
            Text("Choisis ton type de sieste")
                .font(.title3.bold())
            Text("Chaque format a une durée et une fenêtre de réveil pour limiter l’inertie.")
                .font(.subheadline)
                .foregroundStyle(SleepTheme.textSecondary)
        }
    }

    private var napTypePicker: some View {
        VStack(spacing: 10) {
            ForEach(NapAdvisorEngine.NapKind.allCases) { kind in
                let plan = plans.first { $0.kind == kind }!
                Button {
                    selectedKind = kind
                } label: {
                    HStack {
                        Image(systemName: kind.icon)
                            .foregroundStyle(selectedKind == kind ? SleepTheme.accent : SleepTheme.textSecondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(kind.displayName)
                                .font(.subheadline.bold())
                            Text("\(kind.durationMinutes) min · réveil ~\(plan.recommendedWakeTime.formatted(date: .omitted, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(SleepTheme.textSecondary)
                        }
                        Spacer()
                        if selectedKind == kind {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(SleepTheme.accent)
                        }
                    }
                    .padding(12)
                    .background(selectedKind == kind ? SleepTheme.accent.opacity(0.15) : SleepTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var planDetailCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Effets estimés")
                .font(.headline)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Énergie")
                        .font(.caption2)
                        .foregroundStyle(SleepTheme.textSecondary)
                    Text(selectedPlan.energyGainLabel)
                        .font(.caption.bold())
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inertie (~\(selectedPlan.inertiaMinutes) min)")
                        .font(.caption2)
                        .foregroundStyle(SleepTheme.textSecondary)
                    Text(selectedPlan.inertiaRiskLabel)
                        .font(.caption.bold())
                }
            }
            Text(selectedPlan.tip)
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var startButton: some View {
        VStack(spacing: 8) {
            if !tracker.soundMonitor.checkBatteryAndWarn() {
                Label("Batterie < 20 % — le micro peut s'arrêter.", systemImage: "battery.25")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Button {
                startNap()
            } label: {
                Text(isStarting ? "Démarrage…" : "Démarrer \(selectedPlan.durationMinutes) min")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(SleepTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isStarting)
            Text("Pose l’iPhone près de toi. Arrête manuellement au réveil — pas de réveil intelligent en sieste.")
                .font(.caption2)
                .foregroundStyle(SleepTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func startNap() {
        isStarting = true
        startError = nil
        Task {
            let ok = await tracker.startNap()
            isStarting = false
            if ok, tracker.isTracking {
                onStart()
            } else {
                startError = tracker.lastStartError
                    ?? tracker.soundMonitor.lastStartError
                    ?? "Le tracking n’a pas pu démarrer."
            }
        }
    }
}
