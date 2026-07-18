import SwiftUI

/// Hub réglages calibrage (optionnel) — lien vers l’assistant complet.
struct MotionCalibrationView: View {
    var body: some View {
        Form {
            Section {
                Text("Le calibrage adapte la détection des phases à ton téléphone et à l’endroit où tu le poses. Optionnel : le tracking fonctionne aussi sans.")
                    .font(.subheadline)
                    .foregroundStyle(SleepTheme.textSecondary)
            }

            Section("État") {
                LabeledContent("Calibré", value: SleepCalibrationManager.shared.isCalibrated ? "Oui" : "Non")
                LabeledContent("Position", value: SleepCalibrationManager.shared.phonePosition.displayName)
                if SleepCalibrationManager.shared.isCalibrated {
                    LabeledContent("Seuil actuel", value: String(format: "%.4f", SleepCalibrationManager.shared.effectiveMovementThreshold))
                    LabeledContent("Multiplicateur", value: String(format: "%.2f", SleepCalibrationManager.shared.movementThresholdMultiplier))
                    LabeledContent("Nuits suivies", value: "\(SleepCalibrationManager.shared.calibrationNightCount)")
                }
            }

            Section {
                NavigationLink {
                    CalibrationSetupView()
                } label: {
                    Label(
                        SleepCalibrationManager.shared.isCalibrated ? "Refaire le calibrage" : "Lancer le calibrage",
                        systemImage: "gyroscope"
                    )
                }
            }

            if SleepCalibrationManager.shared.isCalibrated {
                Section {
                    Button("Réinitialiser le calibrage", role: .destructive) {
                        SleepCalibrationManager.shared.resetCalibration()
                    }
                }
            }

            Section {
                Text("Pendant 14 nuits, un court questionnaire matinal (« Difficile / Normal / Reposé ») affine le seuil. Tu peux le passer en glissant vers le bas.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(SleepTheme.background.ignoresSafeArea())
        .navigationTitle("Calibrage capteur")
        .navigationBarTitleDisplayMode(.inline)
    }
}
