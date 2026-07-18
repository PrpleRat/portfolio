import SwiftUI

struct MedicamentsView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @State private var showContextes = false

    var body: some View {
        VStack(spacing: 0) {
            QuestionnaireProgressBar(currentStep: .medicaments)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Prenez-vous des médicaments ?")
                        .font(.title2.bold())
                        .foregroundStyle(CarenceColors.textPrimary)

                    Text("Certains médicaments créent des carences — nous en tenons compte")
                        .font(.subheadline)
                        .foregroundStyle(CarenceColors.textSecondary)

                    Button {
                        vm.selectAucunMedicament()
                    } label: {
                        HStack {
                            Image(systemName: vm.aucunMedicament ? "checkmark.circle.fill" : "circle")
                            Text("Aucun médicament")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(vm.aucunMedicament ? CarenceColors.primary.opacity(0.12) : CarenceColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(vm.aucunMedicament ? CarenceColors.primary : CarenceColors.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(CarenceColors.textPrimary)
                    .accessibilityLabel("Aucun médicament")

                    FlowLayout(spacing: 10) {
                        ForEach(vm.database.medicamentsDepleteurs) { medicament in
                            MedicamentChip(
                                label: medicament.label,
                                isSelected: vm.medicamentsSelectionnes.contains(medicament.id)
                            ) {
                                vm.toggleMedicament(medicament.id)
                            }
                        }
                    }

                    if !vm.medicamentsSelectionnes.isEmpty {
                        AlerteBanner(
                            message: AppConstants.alerteMedicaments,
                            style: .warning
                        )
                    }
                }
                .padding(20)
            }

            bottomBar
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Médicaments")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showContextes) {
            ContextesMedicauxView()
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                showContextes = true
            } label: {
                Text("Continuer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(CarenceColors.primary)
            .padding()
            .accessibilityLabel("Continuer vers les contextes médicaux")
        }
        .background(CarenceColors.surface)
    }
}

struct MedicamentChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? CarenceColors.primary.opacity(0.15) : CarenceColors.surface)
                .foregroundStyle(isSelected ? CarenceColors.primary : CarenceColors.textPrimary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? CarenceColors.primary : CarenceColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Disposition en flux pour les chips médicaments.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}

#Preview {
    NavigationStack {
        MedicamentsView()
            .environmentObject(QuestionnaireViewModel())
    }
}
