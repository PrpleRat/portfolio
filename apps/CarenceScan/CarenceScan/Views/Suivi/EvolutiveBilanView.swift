import SwiftUI

struct EvolutiveBilanView: View {
    @EnvironmentObject private var tracker: SymptomTrackerViewModel

    private var result: EvolutiveBilanResult? {
        EvolutiveBilanEngine.calculerDepuisStockage(tracker: tracker)
    }

    var body: some View {
        ScrollView {
            if let result {
                VStack(alignment: .leading, spacing: 20) {
                    headerBlock(result)
                    referenceBlock(result)
                    if result.estPret {
                        evolutifBlock(result)
                        if !result.deltaCarences.isEmpty {
                            deltaBlock(result)
                        }
                        if !result.symptomesResolus.isEmpty {
                            resolusBlock(result)
                        }
                    } else {
                        enAttenteBlock(result)
                    }
                    TrackingExportButton()
                }
                .padding(20)
            } else {
                ContentUnavailableView(
                    "Pas de bilan de référence",
                    systemImage: "doc.text",
                    description: Text("Complétez d'abord le questionnaire complet.")
                )
            }
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Bilan évolutif")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func headerBlock(_ r: EvolutiveBilanResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Bilan évolutif", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)
                .foregroundStyle(CarenceColors.primary)
            Text("Le bilan de référence reste la base. Les fréquences du journal quotidien (14 j) ajustent les scores sans effacer votre questionnaire initial.")
                .font(.caption)
                .foregroundStyle(CarenceColors.textSecondary)
            Text("\(r.joursSuivi) jours de suivi · calculé le \(r.dateCalcul.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption2)
                .foregroundStyle(CarenceColors.textSecondary)
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func referenceBlock(_ r: EvolutiveBilanResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bilan de référence")
                .font(.headline)
            Text(r.baseline.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(CarenceColors.textSecondary)
            ForEach(r.baseline.scores.prefix(5)) { score in
                if let c = CarenceDatabase.carence(for: score.carenceId) {
                    HStack {
                        Text(c.nom)
                            .font(.subheadline)
                        Spacer()
                        Text(score.niveau.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(score.niveau.color)
                    }
                }
            }
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func evolutifBlock(_ r: EvolutiveBilanResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Carences recalculées")
                .font(.headline)
            ForEach(r.scoresEvolutifs.prefix(6)) { score in
                if let c = CarenceDatabase.carence(for: score.carenceId) {
                    let base = r.baseline.scores.first(where: { $0.carenceId == score.carenceId })
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.nom)
                                .font(.subheadline.weight(.semibold))
                            if let base, base.niveau != score.niveau {
                                Text("Réf. : \(base.niveau.label)")
                                    .font(.caption2)
                                    .foregroundStyle(CarenceColors.textSecondary)
                            }
                        }
                        Spacer()
                        Text(score.niveau.label)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(score.niveau.color.opacity(0.15))
                            .foregroundStyle(score.niveau.color)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(CarenceColors.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CarenceColors.primary.opacity(0.2), lineWidth: 1)
        )
    }

    private func deltaBlock(_ r: EvolutiveBilanResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Changements détectés")
                .font(.headline)
            ForEach(r.deltaCarences, id: \.carenceId) { delta in
                let nom = CarenceDatabase.carence(for: delta.carenceId)?.nom ?? delta.carenceId
                HStack {
                    Text(nom)
                        .font(.subheadline)
                    Spacer()
                    if let b = delta.baselineNiveau, let e = delta.evolueNiveau {
                        Text("\(b.label) → \(e.label)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CarenceColors.warning)
                    }
                }
            }
        }
        .padding(14)
        .background(CarenceColors.warningBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func resolusBlock(_ r: EvolutiveBilanResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Symptômes résolus (14j)")
                .font(.headline)
            ForEach(r.symptomesResolus, id: \.self) { id in
                Label(CarenceDatabase.symptomeLabel(for: id), systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(CarenceColors.primary)
            }
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func enAttenteBlock(_ r: EvolutiveBilanResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Données en cours")
                .font(.headline)
            Text("Continuez vos check-ins quotidiens (\(SymptomFrequencyEngine.minDaysForEstimate) j minimum) pour activer le recalcul des carences.")
                .font(.caption)
                .foregroundStyle(CarenceColors.textSecondary)
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
