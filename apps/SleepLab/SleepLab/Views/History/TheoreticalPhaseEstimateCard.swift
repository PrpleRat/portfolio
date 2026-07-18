import SwiftUI

/// Carte « phases possibles » pour une nuit manuelle (sans capteur).
struct TheoreticalPhaseEstimateCard: View {
    let architecture: TheoreticalSleepArchitecture
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 14) {
            Label {
                Text(
                    compact
                        ? "Estimation théorique — pas de mesure réelle."
                        : "Ces phases sont une hypothèse basée sur la durée saisie et un modèle de cycles d’environ 90 minutes. Ce n’est pas un EEG : aucun capteur n’a enregistré cette nuit."
                )
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(SleepTheme.textSecondary)
            } icon: {
                Image(systemName: "lightbulb.max")
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 4) {
                phaseBar(minutes: architecture.deepMinutes, color: SleepTheme.phaseDeep)
                phaseBar(minutes: architecture.lightMinutes, color: SleepTheme.phaseLight)
                phaseBar(minutes: architecture.remMinutes, color: SleepTheme.phaseREM)
            }
            .frame(height: compact ? 6 : 10)
            .clipShape(Capsule())

            HStack(spacing: 12) {
                phaseStat("Profond", architecture.deepMinutes, percent: architecture.deepPercent)
                phaseStat("Léger", architecture.lightMinutes, percent: architecture.lightPercent)
                phaseStat("REM", architecture.remMinutes, percent: architecture.remPercent)
            }

            if !compact {
                Text("Utilise cette carte comme repère, pas comme diagnostic médical.")
                    .font(.caption2)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
        .padding(compact ? 10 : 14)
        .background(SleepTheme.card.opacity(0.95))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.orange.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func phaseBar(minutes: Int, color: Color) -> some View {
        Rectangle()
            .fill(color.opacity(0.85))
            .frame(maxWidth: .infinity)
            .layoutPriority(Double(max(1, minutes)))
    }

    private func phaseStat(_ title: String, _ minutes: Int, percent: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(SleepTheme.textSecondary)
            Text("~\(minutes) min")
                .font(.caption.bold())
            Text(String(format: "~%.0f %%", percent))
                .font(.caption2)
                .foregroundStyle(SleepTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
