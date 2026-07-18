import SwiftUI

/// Assistant calibrage en 3 étapes (optionnel, depuis les réglages).
struct CalibrationSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var step = 1
    @State private var sampler = AwakeMotionSampler()
    @State private var measureRemaining: TimeInterval = 120
    @State private var measuredBaseline: Double?
    @State private var measureError: String?

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case 1: positionStep
                case 2: awakeMeasureStep
                default: confirmationStep
                }
            }
            .padding()
            .background(SleepTheme.background.ignoresSafeArea())
            .navigationTitle("Calibrage capteur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onDisappear {
                sampler.stop()
            }
        }
    }

    // MARK: - Étape 1

    private var positionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Où poses-tu ton iPhone la nuit ?")
                .font(.title2.bold())
            Text("Le seuil de détection s’adapte à la position — tout reste sur l’appareil.")
                .font(.subheadline)
                .foregroundStyle(SleepTheme.textSecondary)

            ForEach(PhonePosition.allCases, id: \.self) { position in
                Button {
                    SleepCalibrationManager.shared.phonePosition = position
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: position.sfSymbol)
                            .font(.title2)
                            .foregroundStyle(SleepTheme.accent)
                            .frame(width: 36)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(position.displayName)
                                .font(.headline)
                                .foregroundStyle(SleepTheme.textPrimary)
                            Text(position.shortDescription)
                                .font(.caption)
                                .foregroundStyle(SleepTheme.textSecondary)
                        }
                        Spacer(minLength: 0)
                        if SleepCalibrationManager.shared.phonePosition == position {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(SleepTheme.accent)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SleepTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.fullAreaTap)
            }

            Spacer(minLength: 0)

            Button("Continuer") { step = 2 }
                .buttonStyle(.borderedProminent)
                .tint(SleepTheme.accent)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
    }

    // MARK: - Étape 2

    private var awakeMeasureStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Mesure éveillé")
                .font(.title2.bold())
            Text("Pose le téléphone comme la nuit, reste éveillé 2 minutes sans le bouger. L’accéléromètre démarre dès que tu appuies sur le bouton ci-dessous.")
                .font(.subheadline)
                .foregroundStyle(SleepTheme.textSecondary)

            if sampler.isRunning {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Mesure en cours… \(formatRemaining(measureRemaining)) restantes")
                        .font(.headline.monospacedDigit())
                    Text("\(sampler.sampleCount) échantillons")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(SleepTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let baseline = measuredBaseline {
                Label(
                    "Variance de référence : \(String(format: "%.4f", baseline))",
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundStyle(.green)
            }

            if let measureError {
                Text(measureError)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Spacer(minLength: 0)

            if measuredBaseline != nil {
                Button("Continuer") { step = 3 }
                    .buttonStyle(.borderedProminent)
                    .tint(SleepTheme.accent)
                    .frame(maxWidth: .infinity)
            } else if !sampler.isRunning {
                Button("Démarrer la mesure éveillé (2 min)") {
                    startAwakeMeasurement()
                }
                .buttonStyle(.borderedProminent)
                .tint(SleepTheme.accent)
                .frame(maxWidth: .infinity)
            }

            if sampler.isRunning {
                Button("Annuler la mesure", role: .cancel) {
                    sampler.stop()
                    measureError = nil
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Étape 3

    private var confirmationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("C’est prêt")
                .font(.title2.bold())

            summaryRow("Position", SleepCalibrationManager.shared.phonePosition.displayName)
            if let baseline = measuredBaseline ?? (SleepCalibrationManager.shared.isCalibrated ? SleepCalibrationManager.shared.awakeVarianceBaseline : nil) {
                summaryRow("Référence éveillé", String(format: "%.4f", baseline))
            }
            summaryRow("Seuil actuel", String(format: "%.4f", SleepCalibrationManager.shared.effectiveMovementThreshold))
            summaryRow("Multiplicateur", String(format: "%.2f", SleepCalibrationManager.shared.movementThresholdMultiplier))

            Text("Après chaque nuit (14 premières fois), tu pourras dire si le réveil était difficile, normal ou reposé — l’app ajustera le seuil.")
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)

            Spacer(minLength: 0)

            Button("Terminer") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(SleepTheme.accent)
            .frame(maxWidth: .infinity)
        }
    }

    private func summaryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(SleepTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
        .padding(.vertical, 4)
    }

    private func startAwakeMeasurement() {
        measureError = nil
        measuredBaseline = nil

        guard sampler.isAccelerometerAvailable else {
            measureError = "Accéléromètre indisponible sur cet appareil."
            return
        }

        sampler.start { remaining in
            measureRemaining = remaining
        } onComplete: { baseline in
            guard let baseline else {
                measureError = "Mesure trop courte ou capteur indisponible. Garde le téléphone immobile et réessaie."
                return
            }
            measuredBaseline = baseline
            SleepCalibrationManager.shared.completeAwakeMeasurement(baseline: baseline)
        }
    }

    private func formatRemaining(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}
