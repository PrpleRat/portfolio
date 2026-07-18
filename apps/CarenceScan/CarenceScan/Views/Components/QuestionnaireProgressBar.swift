import SwiftUI

struct QuestionnaireProgressBar: View {
    let currentStep: QuestionnaireStep

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Étape \(currentStep.rawValue)/\(QuestionnaireStep.totalEtapes)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CarenceColors.textSecondary)
                Spacer()
                Text(currentStep.label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CarenceColors.primary)
            }
            ProgressView(value: Double(currentStep.rawValue), total: Double(QuestionnaireStep.totalEtapes))
                .tint(CarenceColors.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(CarenceColors.surface)
        .accessibilityLabel("Étape \(currentStep.rawValue) sur \(QuestionnaireStep.totalEtapes), \(currentStep.label)")
    }
}
