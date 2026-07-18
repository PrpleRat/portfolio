import SwiftUI

struct ResumeBannerView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    let onResume: (QuestionnaireStep) -> Void

    var body: some View {
        if let etape = vm.etapeReprise, vm.draftCourant != nil, etape != .resultats {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .foregroundStyle(CarenceColors.primary)
                    Text("Reprendre votre questionnaire")
                        .font(.headline)
                        .foregroundStyle(CarenceColors.textPrimary)
                }

                Text(QuestionnaireResume.messageReprise(pour: etape))
                    .font(.subheadline)
                    .foregroundStyle(CarenceColors.textSecondary)

                HStack {
                    Label("~\(QuestionnaireResume.minutesEstimees(restantesDepuis: etape)) min restantes", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(CarenceColors.textSecondary)
                    Spacer()
                    Button("Reprendre") {
                        vm.restoreDraftIfNeeded()
                        onResume(etape)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(CarenceColors.primary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CarenceColors.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(CarenceColors.primary.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
