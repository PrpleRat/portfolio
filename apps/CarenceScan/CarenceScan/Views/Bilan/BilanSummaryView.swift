import SwiftUI

struct BilanSummaryView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @EnvironmentObject private var tabRouter: AppTabRouter
    var onVoirDetail: () -> Void = {}

    private var resume: BilanResume {
        BilanSummaryEngine.generer(
            scores: vm.scores,
            regles: vm.reglesDetectees,
            medicaments: vm.medicamentsSelectionnes
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerBlock
                pointsClesBlock
                etMaintenantBlock
                actionsBlock
            }
            .padding(20)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Résumé")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    GlossaireView()
                } label: {
                    Image(systemName: "book.closed")
                }
                .accessibilityLabel("Glossaire")
            }
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Votre bilan en résumé", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(CarenceColors.primary)

            Text(resume.phrasePrincipale)
                .font(.title3.bold())
                .foregroundStyle(CarenceColors.textPrimary)

            if let priorite = resume.prioriteGlobale {
                HStack(spacing: 8) {
                    Text("Priorité :")
                        .font(.subheadline)
                        .foregroundStyle(CarenceColors.textSecondary)
                    ActionCategoryBadge(categorie: priorite)
                }
            }

            if let date = vm.savedPayload?.date ?? ResultsStorage.load()?.date {
                Text("Bilan du \(date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(CarenceColors.border, lineWidth: 1)
        )
    }

    private var pointsClesBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("À retenir")
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)

            ForEach(Array(resume.pointsCles.enumerated()), id: \.offset) { index, point in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(CarenceColors.primary)
                        .clipShape(Circle())
                    Text(point)
                        .font(.subheadline)
                        .foregroundStyle(CarenceColors.textPrimary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var etMaintenantBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Et maintenant ?")
                .font(.title3.bold())
                .foregroundStyle(CarenceColors.textPrimary)

            Text("Parcours recommandé selon votre bilan — de l'urgence médicale à l'alimentation.")
                .font(.caption)
                .foregroundStyle(CarenceColors.textSecondary)

            ForEach(resume.etapesMaintenant) { etape in
                EtapeMaintenantRow(etape: etape)
            }
        }
    }

    private var actionsBlock: some View {
        VStack(spacing: 12) {
            Button(action: onVoirDetail) {
                Label("Voir le bilan détaillé", systemImage: "list.clipboard")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(CarenceColors.primary)

            if ResultsStorage.hasSavedResults {
                NavigationLink {
                    EvolutiveBilanView()
                } label: {
                    Label("Bilan évolutif (suivi 14j)", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(CarenceColors.primary)
            }

            HStack(spacing: 12) {
                Button {
                    tabRouter.openCourses(section: .liste)
                } label: {
                    Label("Liste de courses", systemImage: "cart.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(CarenceColors.primary)

                Button {
                    tabRouter.openRecettes()
                } label: {
                    Label("Recettes pour moi", systemImage: "fork.knife")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(CarenceColors.primary)
            }

            if let payload = vm.savedPayload ?? ResultsStorage.load() {
                DoctorExportButton(payload: payload)
            }

            Text(AppConstants.disclaimerPrincipal)
                .font(.caption2)
                .foregroundStyle(CarenceColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }
}
