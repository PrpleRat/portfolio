import SwiftUI

struct CarenceCard: View {
    let score: ScoreResult
    let carence: Carence
    var actionCategory: ActionCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let actionCategory {
                ActionCategoryBadge(categorie: actionCategory)
            }

            HStack {
                Text(carence.nom)
                    .font(.headline)
                    .foregroundStyle(CarenceColors.textPrimary)
                Spacer()
                Text(score.niveau.label)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(score.niveau.color.opacity(0.15))
                    .foregroundStyle(score.niveau.color)
                    .clipShape(Capsule())
            }

            ProbabilityBar(level: score.niveau, score: score.score)

            if !score.symptomesDetectes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Symptômes correspondants")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CarenceColors.textSecondary)
                    ForEach(score.symptomesDetectes.prefix(4), id: \.self) { id in
                        Label(CarenceDatabase.symptomeLabel(for: id), systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(CarenceColors.primary)
                    }
                }
            }

            if !score.notesContexte.isEmpty {
                contexteNotesSection
            }

            if !score.alertesProfil.isEmpty {
                ForEach(Array(Set(score.alertesProfil)).sorted(), id: \.self) { alerte in
                    AlerteBanner(message: alerte, style: .warning)
                }
            }

            Text("Aliments à privilégier : \(carence.alimentsCles.prefix(4).joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(CarenceColors.textSecondary)

            NavigationLink {
                CarenceDetailView(carenceId: carence.id)
            } label: {
                Text("Voir les détails & compléments")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(CarenceColors.primary)
            .accessibilityLabel("Voir les détails pour \(carence.nom)")
        }
        .padding(16)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(CarenceColors.border, lineWidth: 1)
        )
    }

    private var contexteNotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(score.notesContexte.groupedByContexte) { groupe in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(groupe.emoji)
                        Text(groupe.label)
                            .font(.caption.bold())
                            .foregroundStyle(CarenceColors.textPrimary)
                    }

                    ForEach(groupe.notesConfusion, id: \.id) { note in
                        ContexteNoteView(
                            icon: "⚠️",
                            note: note,
                            background: CarenceColors.warning.opacity(0.12)
                        )
                    }

                    ForEach(groupe.notesAggravation, id: \.id) { note in
                        ContexteNoteView(
                            icon: "↗️",
                            note: note,
                            background: CarenceColors.primary.opacity(0.12)
                        )
                    }
                }
            }
        }
    }
}
