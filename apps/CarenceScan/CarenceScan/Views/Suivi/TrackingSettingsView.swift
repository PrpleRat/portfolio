import SwiftUI

struct TrackingSettingsView: View {
    @EnvironmentObject private var tracker: SymptomTrackerViewModel

    @State private var reminderDate = Date()

    var body: some View {
        Form {
            Section {
                Toggle("Rappel quotidien", isOn: Binding(
                    get: { tracker.settings.notificationsEnabled },
                    set: { newValue in
                        Task { await tracker.updateNotificationsEnabled(newValue) }
                    }
                ))
                if tracker.settings.notificationsEnabled {
                    DatePicker(
                        "Heure du rappel",
                        selection: $reminderDate,
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: reminderDate) { _, newValue in
                        let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                        Task {
                            await tracker.updateReminderTime(
                                hour: parts.hour ?? 20,
                                minute: parts.minute ?? 0
                            )
                        }
                    }
                }
            } footer: {
                Text(AppConstants.notificationPermissionMessage)
            }

            Section {
                Text("Le bilan complet est fait une seule fois. Ensuite, le check-in quotidien (oui/non) permet d'estimer si chaque symptôme est fréquent, occasionnel ou résolu après \(SymptomFrequencyEngine.resolutionDays) jours.")
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
            }

            Section("Symptômes suivis") {
                if tracker.trackedSymptomeIds.isEmpty {
                    Text("Les symptômes de votre dernier bilan seront suivis automatiquement.")
                        .font(.caption)
                        .foregroundStyle(CarenceColors.textSecondary)
                } else {
                    ForEach(tracker.trackedSymptomeIds, id: \.self) { id in
                        HStack {
                            Text(CarenceDatabase.symptomeLabel(for: id))
                                .font(.subheadline)
                            Spacer()
                            if let freq = tracker.journalFrequence(for: id) {
                                Text(freq.label)
                                    .font(.caption2)
                                    .foregroundStyle(CarenceColors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Rappels")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            var components = DateComponents()
            components.hour = tracker.settings.reminderHour
            components.minute = tracker.settings.reminderMinute
            reminderDate = Calendar.current.date(from: components) ?? Date()
        }
    }
}
