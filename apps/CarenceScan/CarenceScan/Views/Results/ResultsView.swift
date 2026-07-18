import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @EnvironmentObject private var tracker: SymptomTrackerViewModel
    @EnvironmentObject private var tabRouter: AppTabRouter
    @Environment(\.dismiss) private var dismiss
    var onRestart: () -> Void = {}

    @State private var showListeCourses = false
    @State private var showRecettes = false
    @State private var showHoraires = false

    private var carencesActives: Set<String> {
        Set(NutritionDataLoader.carencesActivesIds(from: vm.scores))
    }

    private var synergiesDetectees: [SynergieNutriment] {
        NutritionDataLoader.synergiesDetectees(carencesActives: carencesActives)
    }

    private var payload: SavedResultsPayload? {
        vm.savedPayload
    }

    private var soinsLocaux: [SoinLocal] {
        CarenceDatabase.soinsLocaux(for: vm.symptomesSelectionnes)
    }

    private var bilans: [BilanSanguin] {
        guard let payload else { return [] }
        return CarenceDatabase.bilansSuggeres(scores: payload.scores, regles: vm.reglesDetectees)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                if let profil = vm.profil,
                   profil.situationHormonale == .enceinte || profil.situationHormonale == .allaitante {
                    grossesseBanner(profil: profil)
                }

                if let payload, !payload.conseilsContexte.isEmpty {
                    conseilsContexteSection(payload.conseilsContexte)
                }

                if !vm.reglesDetectees.isEmpty {
                    alertesSection
                }

                if vm.medicamentsSelectionnes.contains("sertraline")
                    || vm.scores.contains(where: { $0.carenceId == "tryptophane" }) {
                    AlerteBanner(message: AppConstants.alerte5HTP, style: .alert)
                }

                if vm.scores.contains(where: { $0.carenceId == "fer" }) {
                    AlerteBanner(message: AppConstants.alerteFer, style: .alert)
                }

                if vm.scores.isEmpty {
                    emptyState
                } else {
                    carencesSection
                    if !synergiesDetectees.isEmpty {
                        synergiesSection
                    }
                    planPriseButton
                    coursesRecettesButtons
                }

                if !soinsLocaux.isEmpty {
                    soinsSection
                }

                if !bilans.isEmpty {
                    bilansSection
                }

                if let payload {
                    ExportButton(payload: payload)
                    DoctorExportButton(payload: payload)
                }

                NavigationLink {
                    GlossaireView()
                } label: {
                    Label("Glossaire médical", systemImage: "book.closed")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(CarenceColors.primary)

                Button("Refaire le test") {
                    onRestart()
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
                .tint(CarenceColors.primary)
                .accessibilityLabel("Refaire le test")

                Text(AppConstants.disclaimerPrincipal)
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Résultats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    NavigationHelpers.popToRoot()
                } label: {
                    Label("Accueil", systemImage: "house.fill")
                }
                .accessibilityLabel("Retour à l'accueil")
            }
        }
        .navigationDestination(isPresented: $showListeCourses) {
            ListeCoursesView(
                scores: vm.scores,
                symptomesDetectes: Array(vm.symptomesSelectionnes)
            )
        }
        .navigationDestination(isPresented: $showRecettes) {
            RecettesView(scores: vm.scores)
        }
        .navigationDestination(isPresented: $showHoraires) {
            HorairesView(scores: vm.scores)
        }
    }

    private var synergiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Interactions importantes")
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)

            ForEach(synergiesDetectees) { synergie in
                SynergieView(synergie: synergie)
            }
        }
    }

    private var planPriseButton: some View {
        Button {
            showHoraires = true
        } label: {
            Label("Plan de prise journalier", systemImage: "clock.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.bordered)
        .tint(CarenceColors.primary)
    }

    private var coursesRecettesButtons: some View {
        HStack(spacing: 12) {
            Button {
                showListeCourses = true
            } label: {
                Label("Ma liste de courses", systemImage: "cart.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(CarenceColors.primary)

            Button {
                showRecettes = true
            } label: {
                Label("Recettes pour moi", systemImage: "fork.knife")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(CarenceColors.primary)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Votre bilan personnalisé")
                .font(.title2.bold())
                .foregroundStyle(CarenceColors.textPrimary)

            if let date = payload?.date {
                Text(date, format: .dateTime.day().month().year().hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(CarenceColors.textSecondary)
            }
        }
    }

    private var alertesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Alertes détectées")
                .font(.headline)
                .foregroundStyle(CarenceColors.alert)

            ForEach(vm.reglesDetectees) { regle in
                AlerteBanner(message: regle.messageAlerte, style: .alert)
            }
        }
    }

    private var carencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Carences probables")
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)

            ForEach(vm.scores) { score in
                if let carence = CarenceDatabase.carence(for: score.carenceId) {
                    CarenceCard(
                        score: score,
                        carence: carence,
                        actionCategory: vm.categorieAction(pour: score.carenceId)
                    )
                }
            }
        }
    }

    private var soinsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Soins locaux recommandés")
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)

            ForEach(soinsLocaux) { soin in
                VStack(alignment: .leading, spacing: 4) {
                    Text(soin.nom)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CarenceColors.textPrimary)
                    Text(soin.utilisation)
                        .font(.caption)
                        .foregroundStyle(CarenceColors.textSecondary)
                    Text(soin.prix)
                        .font(.caption2)
                        .foregroundStyle(CarenceColors.primary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CarenceColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var bilansSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bilan sanguin suggéré")
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)

            ForEach(bilans) { bilan in
                VStack(alignment: .leading, spacing: 6) {
                    Text(bilan.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CarenceColors.textPrimary)
                    Text(bilan.indication)
                        .font(.caption)
                        .foregroundStyle(CarenceColors.textSecondary)
                    Text(bilan.analyses.joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(CarenceColors.primary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CarenceColors.warningBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func grossesseBanner(profil: ProfilUtilisateur) -> some View {
        let titre = profil.situationHormonale == .enceinte ? "🤱 Vous êtes enceinte" : "🤱 Vous allaitez"
        return AlerteBanner(
            message: """
            \(titre)
            Consultez votre sage-femme ou médecin avant toute supplémentation.
            Certaines carences identifiées sont critiques pour vous et votre bébé.
            """,
            style: .alert
        )
    }

    private func conseilsContexteSection(_ conseils: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Conseils selon votre contexte")
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)
            ForEach(Array(Set(conseils)).sorted(), id: \.self) { conseil in
                Text(conseil)
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CarenceColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(CarenceColors.textSecondary)
            Text("Aucune carence au-dessus du seuil avec ces symptômes.")
                .multilineTextAlignment(.center)
                .foregroundStyle(CarenceColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

#Preview {
    NavigationStack {
        ResultsView()
            .environmentObject(QuestionnaireViewModel())
            .environmentObject(SymptomTrackerViewModel.shared)
            .environmentObject(AppTabRouter())
            .environmentObject(JournalEngine.shared)
    }
}
