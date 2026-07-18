import SwiftUI

/// Feedback matin compact (14 premières nuits) — ajuste le multiplicateur de seuil.
struct MorningFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(SleepTheme.textSecondary.opacity(0.35))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            Text("Comment tu t’es réveillé ?")
                .font(.headline)

            Text("Aide le capteur à mieux détecter tes phases (\(SleepCalibrationManager.shared.calibrationNightCount + 1)/14).")
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                feedbackButton(.rough)
                feedbackButton(.normal)
                feedbackButton(.rested)
            }

            Button("Passer") {
                finish()
            }
            .font(.subheadline)
            .foregroundStyle(SleepTheme.textSecondary)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(SleepTheme.background)
    }

    private func feedbackButton(_ quality: WakeQuality) -> some View {
        Button {
            SleepCalibrationManager.shared.recordFeedback(quality)
            finish()
        } label: {
            Text(quality.displayName)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(SleepTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.fullAreaTap)
        .frame(maxWidth: .infinity)
    }

    private func finish() {
        dismiss()
        onContinue()
    }
}
