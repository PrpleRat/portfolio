import SwiftUI

struct StepProgressView: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        VStack(alignment: .leading, spacing: BeatDealSpacing.sm) {
            Text("Étape \(currentStep)/\(totalSteps)")
                .font(BeatDealTypography.caption)
                .foregroundStyle(BeatDealColors.textSecondary)

            ProgressView(value: Double(currentStep), total: Double(totalSteps))
                .tint(BeatDealColors.accent)
        }
    }
}

#Preview {
    StepProgressView(currentStep: 2, totalSteps: 3)
        .padding()
        .background(BeatDealColors.background)
        .preferredColorScheme(.dark)
}
