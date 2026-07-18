import SwiftUI

struct ContextesMedicauxView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @EnvironmentObject private var tabRouter: AppTabRouter

    var body: some View {
        VStack(spacing: 0) {
            QuestionnaireProgressBar(currentStep: .contextes)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Contexte médical")
                        .font(.title2.bold())

                    Text("Certaines conditions peuvent confondre les symptômes ou aggraver les carences.")
                        .font(.subheadline)
                        .foregroundStyle(CarenceColors.textSecondary)

                    Button {
                        vm.selectAucunContexte()
                    } label: {
                        HStack {
                            Image(systemName: vm.aucunContexte ? "checkmark.circle.fill" : "circle")
                            Text("Aucun de ces contextes")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(vm.aucunContexte ? CarenceColors.primary.opacity(0.12) : CarenceColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(vm.aucunContexte ? CarenceColors.primary : CarenceColors.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(CarenceColors.textPrimary)
                    .accessibilityLabel("Aucun contexte médical")

                    ForEach(vm.database.contextesMedicaux) { contexte in
                        ContexteCard(
                            contexte: contexte,
                            isSelected: vm.contextesSelectionnes.contains(contexte.id)
                        ) {
                            vm.toggleContexte(contexte.id)
                        }
                    }
                }
                .padding(20)
            }

            bottomBar
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Contextes")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                vm.analyser()
                tabRouter.openBilanSummary()
                NavigationHelpers.popToRoot()
            } label: {
                Text("Voir mon bilan")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(CarenceColors.primary)
            .padding()
            .accessibilityLabel("Analyser et voir mon bilan")
        }
        .background(CarenceColors.surface)
    }
}

struct ContexteCard: View {
    let contexte: ContexteMedical
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Text(contexte.emoji)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(contexte.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CarenceColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(contexte.description)
                        .font(.caption)
                        .foregroundStyle(CarenceColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? CarenceColors.primary : CarenceColors.textSecondary)
            }
            .padding(14)
            .background(isSelected ? CarenceColors.primary.opacity(0.08) : CarenceColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? CarenceColors.primary : CarenceColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(contexte.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    NavigationStack {
        ContextesMedicauxView()
            .environmentObject(QuestionnaireViewModel())
            .environmentObject(AppTabRouter())
    }
}
