import SwiftUI

struct SymptomEvolutionView: View {
    @EnvironmentObject private var tracker: SymptomTrackerViewModel

    private let lastDays = 14

    private var symptomeIds: [String] {
        let tracked = tracker.trackedSymptomeIds
        return tracked.isEmpty ? (ResultsStorage.load()?.symptomeSelections.map(\.symptomeId) ?? []) : tracked
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Fréquence de vos symptômes sur les \(lastDays) derniers jours. Après \(SymptomFrequencyEngine.resolutionDays) jours sans apparition, un symptôme est considéré comme résolu.")
                    .font(.subheadline)
                    .foregroundStyle(CarenceColors.textSecondary)

                if symptomeIds.isEmpty {
                    ContentUnavailableView(
                        "Pas encore de données",
                        systemImage: "chart.bar",
                        description: Text("Faites un bilan puis enregistrez vos symptômes chaque jour.")
                    )
                } else {
                    HStack(spacing: 16) {
                        legendDot(color: CarenceColors.alert, label: "Oui")
                        legendDot(color: CarenceColors.primary.opacity(0.35), label: "Non")
                        legendDot(color: CarenceColors.border, label: "Non renseigné")
                    }
                    .font(.caption2)
                    .padding(.bottom, 4)

                    ForEach(symptomeIds, id: \.self) { id in
                        evolutionChart(symptomeId: id)
                    }

                    bilanHistorySection
                }
            }
            .padding(20)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Évolution")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            tracker.reloadJournal()
        }
    }

    private func evolutionChart(symptomeId: String) -> some View {
        let entries = SymptomJournalStorage.entries(for: symptomeId, lastDays: lastDays)
        let entryByDay = Dictionary(uniqueKeysWithValues: entries.map {
            (Calendar.current.startOfDay(for: $0.date), $0.present)
        })
        let presentCount = entries.filter(\.present).count

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(CarenceDatabase.symptomeLabel(for: symptomeId))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CarenceColors.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(presentCount)/\(lastDays) j")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CarenceColors.primary)
                    if let freq = SymptomFrequencyEngine.frequence(symptomeId: symptomeId, windowDays: lastDays) {
                        Text("\(freq.emoji) \(freq.label)")
                            .font(.caption2)
                            .foregroundStyle(CarenceColors.textSecondary)
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(tracker.daysWithData(lastDays: lastDays), id: \.self) { day in
                        let present = entryByDay[day]
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(barColor(present: present))
                                .frame(width: 12, height: present == nil ? 8 : (present == true ? 40 : 14))
                            Text(day.formatted(.dateTime.day()))
                                .font(.system(size: 8))
                                .foregroundStyle(CarenceColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(12)
            .background(CarenceColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CarenceColors.border, lineWidth: 1)
            )
        }
    }

    private var bilanHistorySection: some View {
        let history = SymptomJournalStorage.loadBilanHistory()
        return Group {
            if !history.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Historique des bilans")
                        .font(.headline)
                        .foregroundStyle(CarenceColors.textPrimary)

                    ForEach(history.suffix(5).reversed(), id: \.date) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CarenceColors.textPrimary)
                            Text("\(entry.symptomeSelections.count) symptômes · \(entry.scores.count) carences détectées")
                                .font(.caption2)
                                .foregroundStyle(CarenceColors.textSecondary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(CarenceColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private func barColor(present: Bool?) -> Color {
        guard let present else { return CarenceColors.border }
        return present ? CarenceColors.alert : CarenceColors.primary.opacity(0.35)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundStyle(CarenceColors.textSecondary)
        }
    }
}
