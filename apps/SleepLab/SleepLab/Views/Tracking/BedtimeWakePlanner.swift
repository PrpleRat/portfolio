import SwiftData
import SwiftUI

/// Choix coucher + réveil et suggestions de lever (écran « avant de dormir »).
struct BedtimeWakePlanner: View {
    @Binding var alarmEnabled: Bool
    @Binding var plannedBedtime: Date
    @Binding var selectedWakeTime: Date
    @Binding var windowMinutes: Int

    let profile: UserProfile?
    let suggestions: [WakeTimeAdvisor.Suggestion]

    private let windowOptions = [10, 20, 30]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Réveil intelligent", isOn: $alarmEnabled)
                .tint(SleepTheme.accent)

            if alarmEnabled {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Je me couche vers", systemImage: "moon.fill")
                        .font(.subheadline.bold())
                    DatePicker(
                        "Coucher",
                        selection: $plannedBedtime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)

                    Text("Conseils de lever")
                        .font(.subheadline.bold())
                    Text("Alignés sur tes cycles de sommeil (~90 min) et ton objectif (\(String(format: "%.1f", profile?.targetSleepDuration ?? 8)) h).")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.textSecondary)

                    if suggestions.isEmpty {
                        Text("Choisis un réveil au moins 1 h 30 après le coucher.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(suggestions) { suggestion in
                                    suggestionChip(suggestion)
                                }
                            }
                        }
                    }

                    Label("Je me lève à", systemImage: "alarm.fill")
                        .font(.subheadline.bold())
                    DatePicker(
                        "Réveil",
                        selection: $selectedWakeTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .datePickerStyle(.wheel)

                    Text(WakeTimeAdvisor.sleepDurationText(from: plannedBedtime, to: selectedWakeTime))
                        .font(.caption)
                        .foregroundStyle(SleepTheme.accent)

                    HStack(spacing: 8) {
                        Text("Fenêtre")
                            .font(.caption)
                        ForEach(windowOptions, id: \.self) { minutes in
                            Button {
                                windowMinutes = minutes
                            } label: {
                                Text("\(minutes) min")
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        windowMinutes == minutes
                                            ? SleepTheme.accent.opacity(0.35)
                                            : SleepTheme.card
                                    )
                                    .clipShape(Capsule())
                                    .contentShape(Capsule())
                            }
                            .buttonStyle(.capsuleTap)
                        }
                    }
                    Text("Le réveil peut sonner jusqu’à \(windowMinutes) min avant l’heure, en phase légère.")
                        .font(.caption2)
                        .foregroundStyle(SleepTheme.textSecondary)
                }
            }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func suggestionChip(_ suggestion: WakeTimeAdvisor.Suggestion) -> some View {
        let isSelected = abs(selectedWakeTime.timeIntervalSince(suggestion.wakeTime)) < 60
        return Button {
            selectedWakeTime = suggestion.wakeTime
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                if suggestion.isRecommended {
                    Text("Conseillé")
                        .font(.caption2.bold())
                        .foregroundStyle(SleepTheme.accent)
                }
                Text(suggestion.label)
                    .font(.subheadline.bold())
                Text(suggestion.detail)
                    .font(.caption2)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? SleepTheme.accent.opacity(0.3) : SleepTheme.background)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? SleepTheme.accent : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.fullAreaTap)
        .foregroundStyle(SleepTheme.textPrimary)
    }
}
