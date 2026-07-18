import SwiftUI

struct RecetteDetailView: View {
    let item: RecetteScoree
    let scores: [ScoreResult]

    @State private var portionsVoulues: Int
    @State private var ajouteConfirmation = false

    init(item: RecetteScoree, scores: [ScoreResult]) {
        self.item = item
        self.scores = scores
        _portionsVoulues = State(initialValue: max(1, item.recette.portions))
    }

    private var liste: ListeCourses {
        ListeCoursesEngine.genererListe(
            depuis: scores,
            symptomesDetectes: scores.flatMap(\.symptomesDetectes)
        )
    }

    private var ingredientsDansListe: Set<String> {
        Set(liste.supermarche.map { AlimentNormalizer.normaliser($0.nom) })
    }

    private var ingredientsAjustes: [String] {
        RecettePortionsScaler.ingredientsAjustes(
            item.recette.ingredientsComplets,
            portionsBase: item.recette.portions,
            portionsVoulues: portionsVoulues
        )
    }

    private var portionsModifiees: Bool {
        portionsVoulues != item.recette.portions
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                portionsSection
                carencesSection
                ingredientsSection
                etapesSection
                conseilSection

                Button {
                    ajouterAListe()
                } label: {
                    Label("Ajouter les ingrédients à ma liste", systemImage: "cart.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(CarenceColors.primary)
            }
            .padding(20)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle(item.recette.titre)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Ajouté à la liste", isPresented: $ajouteConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Les ingrédients manquants ont été ajoutés à votre liste supermarché (\(portionsVoulues) portion\(portionsVoulues > 1 ? "s" : "")).")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(item.recette.emoji)
                .font(.system(size: 56))
            Text(item.recette.titre)
                .font(.title2.bold())
                .foregroundStyle(CarenceColors.textPrimary)
                .multilineTextAlignment(.center)
            Text("⏱ \(item.recette.temps)  •  ⭐ \(item.recette.difficulte)")
                .font(.subheadline)
                .foregroundStyle(CarenceColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var portionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nombre de portions")
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)

            HStack(spacing: 16) {
                Button {
                    if portionsVoulues > 1 { portionsVoulues -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(portionsVoulues > 1 ? CarenceColors.primary : CarenceColors.border)
                }
                .disabled(portionsVoulues <= 1)
                .accessibilityLabel("Moins une portion")

                VStack(spacing: 2) {
                    Text("\(portionsVoulues)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(CarenceColors.primary)
                    Text(portionsVoulues > 1 ? "personnes" : "personne")
                        .font(.caption)
                        .foregroundStyle(CarenceColors.textSecondary)
                }
                .frame(minWidth: 80)

                Button {
                    if portionsVoulues < 24 { portionsVoulues += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(portionsVoulues < 24 ? CarenceColors.primary : CarenceColors.border)
                }
                .disabled(portionsVoulues >= 24)
                .accessibilityLabel("Plus une portion")
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                ForEach(portionsRapides, id: \.self) { n in
                    Button {
                        portionsVoulues = n
                    } label: {
                        Text("\(n)")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(portionsVoulues == n ? CarenceColors.primary : CarenceColors.surface)
                            .foregroundStyle(portionsVoulues == n ? .white : CarenceColors.textPrimary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(CarenceColors.border, lineWidth: portionsVoulues == n ? 0 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)

            if portionsModifiees {
                Text("Recette de base pour \(item.recette.portions) portion\(item.recette.portions > 1 ? "s" : "") — quantités recalculées automatiquement.")
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
            } else {
                Text("Recette prévue pour \(item.recette.portions) portion\(item.recette.portions > 1 ? "s" : "").")
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
            }
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var portionsRapides: [Int] {
        let base = item.recette.portions
        var valeurs = Set([1, 2, 3, 4, 6, base])
        return Array(valeurs).filter { $0 >= 1 && $0 <= 24 }.sorted()
    }

    private var carencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Couvre vos carences")
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)
            let carences = item.carencesMatchees.isEmpty ? item.recette.carencesCouvertes : item.carencesMatchees
            Text("Cette recette couvre \(carences.count) carence\(carences.count > 1 ? "s" : "").")
                .font(.caption)
                .foregroundStyle(CarenceColors.textSecondary)
            FlowLayout(spacing: 6) {
                ForEach(carences, id: \.self) { id in
                    Text(RecettesEngine.carenceNom(for: id))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(CarenceColors.primary.opacity(0.15))
                        .foregroundStyle(CarenceColors.primary)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Ingrédients")
                    .font(.headline)
                    .foregroundStyle(CarenceColors.textPrimary)
                Spacer()
                if portionsModifiees {
                    Text("×\(ratioText)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(CarenceColors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CarenceColors.primary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            ForEach(Array(ingredientsAjustes.enumerated()), id: \.offset) { _, ingredient in
                let dansListe = ingredientDansListe(ingredient)
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: dansListe ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(dansListe ? CarenceColors.primary : CarenceColors.textSecondary)
                        .font(.caption)
                    Text(ingredient)
                        .font(.subheadline)
                        .foregroundStyle(dansListe ? CarenceColors.primary : CarenceColors.textPrimary)
                }
            }
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var ratioText: String {
        RecettePortionsScaler.formaterQuantite(
            Double(portionsVoulues) / Double(max(1, item.recette.portions))
        )
    }

    private var etapesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Préparation")
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)
            ForEach(Array(item.recette.etapes.enumerated()), id: \.offset) { index, etape in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(CarenceColors.primary)
                        .clipShape(Circle())
                    Text(etape)
                        .font(.subheadline)
                        .foregroundStyle(CarenceColors.textPrimary)
                }
            }
        }
    }

    private var conseilSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("💡")
            Text(item.recette.conseilNutrition)
                .font(.subheadline)
                .foregroundStyle(CarenceColors.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CarenceColors.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func ingredientDansListe(_ ingredient: String) -> Bool {
        let cle = AlimentNormalizer.normaliser(ingredient)
        if ingredientsDansListe.contains(cle) { return true }
        return item.ingredientsMatches.contains { cle.contains($0) || $0.contains(cle) }
    }

    private func ajouterAListe() {
        let manquants = ingredientsAjustes.filter { !ingredientDansListe($0) }
        ListeCoursesStorage.ajouterIngredientsRecette(manquants, carencesLiees: item.carencesMatchees)
        ajouteConfirmation = true
    }
}
