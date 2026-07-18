import SwiftUI

struct QuestionnaireView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var expandedCategories: Set<String> = Set(SymptomCategory.questionnaireOrder.map(\.rawValue))
    @State private var showMedicaments = false

    private var progress: Double {
        min(1, Double(vm.selectedSymptomCount) / 8)
    }

    var body: some View {
        VStack(spacing: 0) {
            QuestionnaireProgressBar(currentStep: .symptomes)

            ProgressView(value: progress)
                .tint(CarenceColors.primary)
                .padding(.horizontal)
                .padding(.top, 4)
                .accessibilityLabel("Progression des symptômes sélectionnés")

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(vm.selectedSymptomCount) symptôme\(vm.selectedSymptomCount > 1 ? "s" : "") sélectionné\(vm.selectedSymptomCount > 1 ? "s" : "")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CarenceColors.primary)
                        .padding(.horizontal)

                    ForEach(SymptomCategory.questionnaireOrder) { category in
                        categorySection(category)
                    }

                    Button("Tout désélectionner") {
                        vm.deselectAllSymptomes()
                    }
                    .font(.footnote)
                    .foregroundStyle(CarenceColors.textSecondary)
                    .padding(.horizontal)
                    .accessibilityLabel("Tout désélectionner")
                }
                .padding(.vertical)
            }

            bottomBar
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Symptômes")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showMedicaments) {
            MedicamentsView()
        }
    }

    @ViewBuilder
    private func categorySection(_ category: SymptomCategory) -> some View {
        let symptomes = vm.symptomes(for: category)
        if !symptomes.isEmpty {
            DisclosureGroup(
                isExpanded: Binding(
                    get: { expandedCategories.contains(category.rawValue) },
                    set: { expanded in
                        if expanded {
                            expandedCategories.insert(category.rawValue)
                        } else {
                            expandedCategories.remove(category.rawValue)
                        }
                    }
                )
            ) {
                LazyVStack(spacing: 8) {
                    ForEach(symptomes) { symptome in
                        SymptomeCard(
                            label: symptome.label,
                            isSelected: vm.isSymptomeSelected(symptome.id),
                            frequence: vm.frequence(for: symptome.id),
                            onToggle: { vm.toggleSymptome(symptome.id) },
                            onFrequenceChange: { vm.setFrequence(symptomeId: symptome.id, frequence: $0) }
                        )
                    }
                }
                .padding(.top, 8)
            } label: {
                Text("\(category.emoji) \(category.title)")
                    .font(.headline)
                    .foregroundStyle(CarenceColors.textPrimary)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(CarenceColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                showMedicaments = true
            } label: {
                Text("Continuer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(CarenceColors.primary)
            .disabled(vm.selectedSymptomCount == 0)
            .padding()
            .accessibilityLabel("Continuer vers les médicaments")
        }
        .background(CarenceColors.surface)
    }
}

#Preview {
    NavigationStack {
        QuestionnaireView()
            .environmentObject(QuestionnaireViewModel())
    }
}
