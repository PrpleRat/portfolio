import SwiftUI

struct SynergieView: View {
    let synergie: SynergieNutriment

    private var isSynergie: Bool { synergie.type == .synergie }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(isSynergie ? "✨" : "⚠️")
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(isSynergie ? "Synergie détectée" : "Antagonisme à éviter")
                    .font(.caption.bold())
                    .foregroundStyle(isSynergie ? CarenceColors.primary : .orange)

                Text(synergie.message)
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)

                Text("💡 \(synergie.conseilPratique)")
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textPrimary)
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CarenceColors.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSynergie ? CarenceColors.primary.opacity(0.07) : Color.orange.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
