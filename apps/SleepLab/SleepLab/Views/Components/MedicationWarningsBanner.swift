import SwiftUI

struct MedicationWarningsBanner: View {
    let warnings: [MedicationInteractionEngine.InteractionWarning]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(warnings) { warning in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(warning.severity == .attention ? .orange : .yellow)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(warning.title)
                            .font(.subheadline.bold())
                        Text(warning.message)
                            .font(.caption)
                            .foregroundStyle(SleepTheme.textSecondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
