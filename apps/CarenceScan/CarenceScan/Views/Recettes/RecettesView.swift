import SwiftUI

struct RecettesView: View {
    let scores: [ScoreResult]
    var showHomeButton: Bool = true
    var embedded: Bool = false

    @State private var mode: RecettesMode = .toutes
    @State private var filtreTemps: FiltreTemps = .tous
    @State private var filtreDifficulte: FiltreDifficulte = .tous

    private var recettes: [RecetteScoree] {
        switch mode {
        case .personnalisees:
            RecettesEngine.suggererRecettes(depuis: scores)
        case .toutes:
            RecettesEngine.listerToutesLesRecettes(depuis: scores)
        }
    }

    private var recettesFiltrees: [RecetteScoree] {
        recettes.filter { item in
            let tempsOk = filtreTemps.accepte(item.recette.temps)
            let diffOk = filtreDifficulte.accepte(item.recette.difficulte)
            return tempsOk && diffOk
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Mode recettes", selection: $mode) {
                    Text("Pour vous").tag(RecettesMode.personnalisees)
                    Text("Toutes (\(RecettesEngine.nombreRecettesDansBase))").tag(RecettesMode.toutes)
                }
                .pickerStyle(.segmented)

                enteteSection

                filtresSection

                if recettesFiltrees.isEmpty {
                    ContentUnavailableView(
                        mode == .personnalisees ? "Aucune recette personnalisée" : "Aucune recette",
                        systemImage: "fork.knife",
                        description: Text(mode == .personnalisees
                            ? "Affinez vos résultats ou consultez l'onglet « Toutes »."
                            : "Aucune recette ne correspond aux filtres sélectionnés.")
                    )
                    .padding(.vertical, 24)
                } else {
                    ForEach(recettesFiltrees) { item in
                        NavigationLink {
                            RecetteDetailView(item: item, scores: scores)
                        } label: {
                            recetteCard(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .modifier(RecettesNavigationChrome(showHomeButton: showHomeButton, embedded: embedded, mode: mode))
    }

    private var enteteSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch mode {
            case .personnalisees:
                Text("\(recettesFiltrees.count) recette\(recettesFiltrees.count > 1 ? "s" : "") pour vos carences")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CarenceColors.textPrimary)
                Text("Triées par pertinence pour votre bilan")
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
            case .toutes:
                Text("\(recettesFiltrees.count) / \(RecettesEngine.nombreRecettesDansBase) recettes du catalogue")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CarenceColors.textPrimary)
                Text("Toutes les recettes anti-carences — les vôtres en premier si bilan disponible")
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
            }
        }
    }

    private var filtresSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Durée")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CarenceColors.textSecondary)
            Picker("Durée", selection: $filtreTemps) {
                ForEach(FiltreTemps.allCases, id: \.self) { f in
                    Text(f.label).tag(f)
                }
            }
            .pickerStyle(.segmented)

            Text("Difficulté")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CarenceColors.textSecondary)
            Picker("Difficulté", selection: $filtreDifficulte) {
                ForEach(FiltreDifficulte.allCases, id: \.self) { f in
                    Text(f.label).tag(f)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func recetteCard(_ item: RecetteScoree) -> some View {
        let r = item.recette
        let carencesAffichees = mode == .toutes && item.carencesMatchees.isEmpty
            ? r.carencesCouvertes
            : item.carencesMatchees
        let carencesTitre = item.carencesMatchees.isEmpty && mode == .toutes
            ? "Carences couvertes :"
            : "Couvre vos carences en :"

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text(r.emoji)
                    .font(.largeTitle)
                VStack(alignment: .leading, spacing: 4) {
                    Text(r.titre)
                        .font(.headline)
                        .foregroundStyle(CarenceColors.textPrimary)
                    Text("⏱ \(r.temps)  •  👤 \(r.portions) portions  •  ⭐ \(r.difficulte)")
                        .font(.caption)
                        .foregroundStyle(CarenceColors.textSecondary)
                }
            }

            if !carencesAffichees.isEmpty {
                Text(carencesTitre)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CarenceColors.textSecondary)
                FlowLayout(spacing: 6) {
                    ForEach(carencesAffichees, id: \.self) { id in
                        Text(RecettesEngine.carenceNom(for: id))
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                item.carencesMatchees.contains(id)
                                    ? CarenceColors.primary.opacity(0.15)
                                    : CarenceColors.border.opacity(0.5)
                            )
                            .foregroundStyle(
                                item.carencesMatchees.contains(id)
                                    ? CarenceColors.primary
                                    : CarenceColors.textSecondary
                            )
                            .clipShape(Capsule())
                    }
                }
            }

            Text("Ingrédients clés : \(r.ingredientsCles.joined(separator: ", "))")
                .font(.caption2)
                .foregroundStyle(CarenceColors.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(CarenceColors.border, lineWidth: 1)
        )
    }
}

private enum RecettesMode: String, CaseIterable {
    case personnalisees
    case toutes
}

private struct RecettesNavigationChrome: ViewModifier {
    let showHomeButton: Bool
    let embedded: Bool
    let mode: RecettesMode

    func body(content: Content) -> some View {
        if embedded {
            content
        } else {
            content
                .navigationTitle(mode == .toutes ? "Toutes les recettes" : "Recettes pour vous")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if showHomeButton {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                NavigationHelpers.popToRoot()
                            } label: {
                                Label("Accueil", systemImage: "house.fill")
                            }
                            .accessibilityLabel("Retour à l'accueil")
                        }
                    }
                }
        }
    }
}

private enum FiltreTemps: String, CaseIterable {
    case tous, court, moyen

    var label: String {
        switch self {
        case .tous: return "Tous"
        case .court: return "< 15 min"
        case .moyen: return "< 30 min"
        }
    }

    func accepte(_ temps: String) -> Bool {
        guard let minutes = Int(temps.filter(\.isNumber)) else { return self == .tous }
        switch self {
        case .tous: return true
        case .court: return minutes < 15
        case .moyen: return minutes < 30
        }
    }
}

private enum FiltreDifficulte: String, CaseIterable {
    case tous, facile, moyen

    var label: String {
        switch self {
        case .tous: return "Tous"
        case .facile: return "Facile"
        case .moyen: return "Moyen"
        }
    }

    func accepte(_ difficulte: String) -> Bool {
        switch self {
        case .tous: return true
        case .facile: return difficulte.lowercased() == "facile"
        case .moyen: return difficulte.lowercased() == "moyen"
        }
    }
}
