import SwiftUI

/// Catalogue caféine, alcool, substances… réutilisable (journal + fiche nuit).
struct FactorCatalogSections: View {
    @Binding var stimulantTime: Date
    /// Si true, toutes les entrées utilisent `stimulantTime` (journal calendrier). Sinon alcool/repas = maintenant.
    var anchorAllEntriesToSharedTime: Bool = true
    let isSelected: (FactorType, Double) -> Bool
    let onToggle: (FactorType, Double, Date, String?) -> Void

    private func logTime(for pick: PreSleepFactorCatalog.QuickPick) -> Date {
        if anchorAllEntriesToSharedTime || pick.usesSharedTime {
            return stimulantTime
        }
        return Date()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            catalogSection("Caféine & stimulants", icon: "cup.and.saucer.fill", picks: PreSleepFactorCatalog.caffeine)
            catalogSection("Nicotine", icon: "smoke.fill", picks: PreSleepFactorCatalog.nicotine)
            catalogSection("Alcool", icon: "wineglass.fill", picks: PreSleepFactorCatalog.alcohol)
            catalogSection("Substances", icon: "leaf.fill", picks: PreSleepFactorCatalog.substances)
            catalogSection("Compléments", icon: "pills.fill", picks: PreSleepFactorCatalog.supplements)
            catalogSection("Alimentation", icon: "fork.knife", picks: PreSleepFactorCatalog.food)
            catalogSection("Activité & hygiène", icon: "figure.run", picks: PreSleepFactorCatalog.activity)
            catalogSection("Environnement", icon: "house.fill", picks: PreSleepFactorCatalog.environment)
            catalogSection("Médical", icon: "cross.case.fill", picks: PreSleepFactorCatalog.medical)
        }
    }

    private func catalogSection(_ title: String, icon: String, picks: [PreSleepFactorCatalog.QuickPick]) -> some View {
        factorSection(title: title, icon: icon) {
            FlowLayout(spacing: 8) {
                ForEach(picks) { pick in
                    factorToggleButton(
                        pick.label,
                        pick.type,
                        pick.value,
                        at: logTime(for: pick)
                    )
                }
            }
            if title.contains("Caféine") {
                DatePicker(
                    "Heure de prise",
                    selection: $stimulantTime,
                    displayedComponents: anchorAllEntriesToSharedTime ? [.hourAndMinute] : [.date, .hourAndMinute]
                )
                .font(.caption)
            }
        }
    }

    private func factorSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            content()
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func factorToggleButton(
        _ title: String,
        _ type: FactorType,
        _ value: Double,
        at: Date = Date()
    ) -> some View {
        let selected = isSelected(type, value)
        return Button {
            onToggle(type, value, at, nil)
        } label: {
            HStack(spacing: 6) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                }
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? SleepTheme.accent.opacity(0.35) : SleepTheme.card.opacity(0.6))
            .foregroundStyle(SleepTheme.textPrimary)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(selected ? SleepTheme.accent : Color.clear, lineWidth: 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.capsuleTap)
    }
}
