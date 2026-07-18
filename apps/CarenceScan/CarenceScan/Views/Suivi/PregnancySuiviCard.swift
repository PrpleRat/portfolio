import SwiftUI

struct PregnancySuiviCard: View {
    let profil: ProfilUtilisateur
    let scores: [ScoreResult]

    private var isEnceinte: Bool { profil.situationHormonale == .enceinte }
    private var isAllaitante: Bool { profil.situationHormonale == .allaitante }

    private var carencesPrioritaires: [ScoreResult] {
        let ids: Set<String> = isEnceinte
            ? ["vitamine_b9", "fer", "iode", "vitamine_d", "omega3", "magnesium", "zinc"]
            : ["iode", "vitamine_b12", "vitamine_d", "omega3", "fer"]
        return scores.filter { ids.contains($0.carenceId) && $0.niveau != .possible }
            .sorted { $0.niveau.sortOrder > $1.niveau.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(isEnceinte ? "🤱" : "🤱")
                    .font(.title2)
                Text(isEnceinte ? "Mode grossesse" : "Mode allaitement")
                    .font(.headline)
                    .foregroundStyle(CarenceColors.textPrimary)
            }

            Text(isEnceinte
                 ? "Suivi adapté : besoins nutritionnels accrus. Toute supplémentation doit être validée par votre sage-femme ou médecin."
                 : "Suivi adapté : vos besoins en iode, B12 et vitamine D sont augmentés pendant l'allaitement.")
                .font(.caption)
                .foregroundStyle(CarenceColors.textSecondary)

            AlerteBanner(
                message: isEnceinte
                    ? "Ne prenez jamais de fer, B9 ou iode sans avis médical pendant la grossesse."
                    : "La carence maternelle en B12 ou iode impacte directement le nourrisson.",
                style: .alert
            )

            if carencesPrioritaires.isEmpty {
                Text("Aucune carence prioritaire détectée au bilan — continuez le suivi quotidien.")
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
            } else {
                Text("Carences à surveiller en priorité")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CarenceColors.warning)
                ForEach(carencesPrioritaires.prefix(4)) { score in
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
        }
        .padding(14)
        .background(CarenceColors.warningBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(CarenceColors.warning.opacity(0.4), lineWidth: 1)
        )
    }
}
