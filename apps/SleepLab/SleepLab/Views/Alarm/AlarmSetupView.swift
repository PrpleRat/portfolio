import SwiftData
import SwiftUI

struct AlarmSetupView: View {
    @Bindable var config: AlarmConfig
    @ObservedObject private var soundLibrary = AlarmSoundLibrary.shared
    @State private var previewingSound: AlarmSound?

    private let windowOptions = [5, 10, 20, 30]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Toggle("Réveil intelligent", isOn: $config.isEnabled)
                    .tint(SleepTheme.accent)

                Text("Tu peux aussi choisir ton heure de réveil chaque soir dans « Commencer la nuit », avec des conseils selon ton heure de coucher.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Heure par défaut (profil)")
                        .font(.headline)
                    DatePicker(
                        "Réveil",
                        selection: Binding(
                            get: { config.targetWakeTime },
                            set: { config.targetWakeTime = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .datePickerStyle(.wheel)
                }
                .padding()
                .background(SleepTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Fenêtre intelligente")
                        .font(.headline)
                    Text("Réveil dans la phase la plus légère \(config.windowMinutes) min avant l’heure.")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.textSecondary)

                    HStack(spacing: 8) {
                        ForEach(windowOptions, id: \.self) { minutes in
                            Button {
                                config.windowMinutes = minutes
                            } label: {
                                Text("\(minutes) min")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        config.windowMinutes == minutes
                                            ? SleepTheme.accent.opacity(0.35)
                                            : SleepTheme.card
                                    )
                                    .foregroundStyle(SleepTheme.textPrimary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .background(SleepTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Son du réveil")
                        .font(.headline)
                    Text("Tape pour préécouter. Le fichier est aussi utilisé pour la notification de secours.")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.textSecondary)

                    ForEach(AlarmSound.allCases) { sound in
                        AlarmSoundRow(
                            sound: sound,
                            isSelected: soundLibrary.selectedSound == sound,
                            isPreviewing: previewingSound == sound && soundLibrary.isPreviewPlaying
                        ) {
                            soundLibrary.select(sound)
                            config.sound = sound
                        } onPreview: {
                            if previewingSound == sound && soundLibrary.isPreviewPlaying {
                                soundLibrary.stopPreview()
                                previewingSound = nil
                            } else {
                                previewingSound = sound
                                soundLibrary.preview(sound)
                            }
                        }
                    }
                }
                .padding()
                .background(SleepTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Toggle("Volume progressif (60 s)", isOn: $config.progressiveVolume)
                    .tint(SleepTheme.accent)
                    .padding()
                    .background(SleepTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Text("Si aucune phase légère n’est détectée, le réveil retentit à l’heure exacte (in-app + notification).")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
            .padding()
        }
        .background(SleepTheme.background.ignoresSafeArea())
        .navigationTitle("Réveil")
        .onDisappear {
            soundLibrary.stopPreview()
        }
    }
}

private struct AlarmSoundRow: View {
    let sound: AlarmSound
    let isSelected: Bool
    let isPreviewing: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack {
                    Image(systemName: sound.sfSymbol)
                        .foregroundStyle(SleepTheme.accent)
                        .frame(width: 28)
                    Text(sound.displayName)
                        .foregroundStyle(SleepTheme.textPrimary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(SleepTheme.accent)
                    }
                }
            }
            .buttonStyle(.plain)

            Button(action: onPreview) {
                Image(systemName: isPreviewing ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(SleepTheme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}
