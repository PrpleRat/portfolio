import SwiftData
import SwiftUI

/// Popup d’ajout : 3 dernières substances en haut, puis catalogue complet.
struct AddFactorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let day: Date
    let recentPicks: [RecentSubstancePick]
    let onSaved: () -> Void

    @State private var entryTime: Date

    init(day: Date, recentPicks: [RecentSubstancePick], onSaved: @escaping () -> Void) {
        self.day = FactorJournalHelpers.startOfDay(day)
        self.recentPicks = recentPicks
        self.onSaved = onSaved
        _entryTime = State(initialValue: FactorJournalHelpers.timestamp(on: day, preservingTimeFrom: Date()))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !recentPicks.isEmpty {
                        recentSection
                    }
                    Text("Catalogue")
                        .font(.headline)
                    FactorCatalogSections(
                        stimulantTime: $entryTime,
                        isSelected: { _, _ in false },
                        onToggle: { type, value, at, notes in
                            log(type: type, value: value, at: at, notes: notes)
                        }
                    )
                    MedicalDisclaimer()
                }
                .padding()
            }
            .background(SleepTheme.background.ignoresSafeArea())
            .navigationTitle("Ajouter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .safeAreaInset(edge: .top) {
                timePickerBar
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear { syncEntryTimeToSelectedDay() }
        .onChange(of: day) { _, _ in syncEntryTimeToSelectedDay() }
        .onChange(of: entryTime) { _, newValue in
            let fixed = FactorJournalHelpers.timestamp(on: day, preservingTimeFrom: newValue)
            if abs(fixed.timeIntervalSince(newValue)) > 1 {
                entryTime = fixed
            }
        }
    }

    private func syncEntryTimeToSelectedDay() {
        entryTime = FactorJournalHelpers.timestamp(on: day, preservingTimeFrom: entryTime)
    }

    private var timePickerBar: some View {
        VStack(spacing: 8) {
            Text(day.formatted(date: .complete, time: .omitted))
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
            DatePicker("Heure", selection: $entryTime, displayedComponents: [.hourAndMinute])
                .labelsHidden()
        }
        .padding()
        .background(SleepTheme.card)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Récemment pris")
                .font(.headline)
            ForEach(recentPicks) { pick in
                Button {
                    log(type: pick.type, value: pick.value, at: entryTime, notes: nil)
                } label: {
                    HStack {
                        Image(systemName: pick.type.sfSymbol)
                            .foregroundStyle(SleepTheme.accent)
                        Text(pick.displayLabel)
                            .foregroundStyle(SleepTheme.textPrimary)
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(SleepTheme.accent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SleepTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .contentShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.fullAreaTap)
            }
        }
    }

    private func log(type: FactorType, value: Double, at: Date, notes: String?) {
        let consumedAt = FactorJournalHelpers.timestamp(on: day, preservingTimeFrom: at)
        let factor = SleepFactor(type: type, value: value, consumedAt: consumedAt, notes: notes)
        modelContext.insert(factor)
        try? modelContext.save()
        onSaved()
        dismiss()
    }
}
