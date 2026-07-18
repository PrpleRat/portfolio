import SwiftUI

struct ActionCategoryBadge: View {
    let categorie: ActionCategory

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: categorie.icon)
                .font(.caption2)
            Text(categorie.label)
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(categorie.color)
        .background(categorie.background)
        .clipShape(Capsule())
    }
}

struct EtapeMaintenantRow: View {
    let etape: EtapeMaintenant

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(etape.id)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(etape.categorie.color)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 6) {
                ActionCategoryBadge(categorie: etape.categorie)
                Text(etape.titre)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CarenceColors.textPrimary)
                Text(etape.detail)
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(etape.categorie.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(etape.categorie.color.opacity(0.25), lineWidth: 1)
        )
    }
}
