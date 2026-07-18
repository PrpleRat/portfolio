import SwiftUI

struct HorairesView: View {
    let scores: [ScoreResult]

    private var carencesActives: Set<String> {
        Set(NutritionDataLoader.carencesActivesIds(from: scores))
    }

    private var horaires: [HorairePrise] {
        NutritionDataLoader.horairesPourCarences(carencesActives)
    }

    private var creneaux: [CreneauHoraire] {
        NutritionDataLoader.creneauxJournaliers(pour: horaires)
    }

    private var avertissements: [String] {
        NutritionDataLoader.avertissementsAntagonismes(carencesActives: carencesActives)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Votre plan de prise quotidien")
                        .font(.title2.bold())
                        .foregroundStyle(CarenceColors.textPrimary)
                    Text("Optimisé pour maximiser l'absorption de chaque complément")
                        .font(.subheadline)
                        .foregroundStyle(CarenceColors.textSecondary)
                }

                if horaires.isEmpty {
                    Text("Aucun complément horaire recommandé pour vos carences actuelles.")
                        .foregroundStyle(CarenceColors.textSecondary)
                } else {
                    ForEach(creneaux) { creneau in
                        creneauCard(creneau)
                    }
                }

                if !avertissements.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Avertissements")
                            .font(.headline)
                            .foregroundStyle(CarenceColors.alert)
                        ForEach(avertissements, id: \.self) { msg in
                            Text("⚠️ \(msg)")
                                .font(.caption)
                                .foregroundStyle(CarenceColors.alert)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(CarenceColors.warningBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                Text(AppConstants.disclaimerPrincipal)
                    .font(.caption2)
                    .foregroundStyle(CarenceColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Plan de prise")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func creneauCard(_ creneau: CreneauHoraire) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(creneau.emoji) \(creneau.titre)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CarenceColors.textPrimary)

            ForEach(creneau.items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text("💊 \(NutritionDataLoader.labelComplement(item.complementId))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CarenceColors.textPrimary)
                    Text("Avec : \(item.avec)")
                        .font(.caption)
                        .foregroundStyle(CarenceColors.textSecondary)
                    Text("Éviter : \(item.eviter)")
                        .font(.caption2)
                        .foregroundStyle(CarenceColors.textSecondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CarenceColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(12)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
