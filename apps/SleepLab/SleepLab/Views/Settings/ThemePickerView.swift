import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choisis une ambiance — le changement est immédiat.")
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(AppTheme.allCases) { theme in
                    ThemeOptionCard(
                        theme: theme,
                        isSelected: themeManager.appTheme == theme
                    ) {
                        themeManager.setTheme(theme, systemColorScheme: colorScheme)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ThemeOptionCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                ThemeSwatchPreview(palette: theme.palette(for: .dark))
                    .frame(height: 36)

                Text(theme.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SleepTheme.textPrimary)
                    .lineLimit(1)

                Text(theme.subtitle)
                    .font(.caption2)
                    .foregroundStyle(SleepTheme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if isSelected {
                    Label("Actif", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(SleepTheme.accent)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? SleepTheme.accent.opacity(0.15) : SleepTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? SleepTheme.accent : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct ThemeSwatchPreview: View {
    let palette: ThemePalette

    var body: some View {
        HStack(spacing: 0) {
            Rectangle().fill(palette.background)
            Rectangle().fill(palette.card)
            Rectangle().fill(palette.accent)
            Rectangle().fill(palette.textPrimary.opacity(0.85))
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
