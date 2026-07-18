import SwiftData
import SwiftUI

/// Réglages du cycle (durée, calendrier) — dans l’onglet Cycle, pas dans Réglages généraux.
struct CycleProfileSettingsView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        Form {
            Section {
                Text("Ces valeurs affinent les prévisions. Le plus fiable reste de marquer tes jours de règles dans le calendrier.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }

            Section("Calendrier") {
                NavigationLink {
                    CyclePeriodCalendarView()
                } label: {
                    Label("Jours de règles", systemImage: "calendar")
                }
            }

            Section("Paramètres") {
                Stepper(
                    "Durée des règles : \(profile.effectivePeriodLength) j",
                    value: Binding(
                        get: { profile.effectivePeriodLength },
                        set: { profile.effectivePeriodLength = $0 }
                    ),
                    in: 2...10
                )
                Stepper(
                    "Durée du cycle : \(profile.averageCycleLength) j",
                    value: $profile.averageCycleLength,
                    in: 21...45
                )
                DatePicker(
                    "Début des dernières règles",
                    selection: Binding(
                        get: { profile.lastPeriodStart ?? Date() },
                        set: { profile.lastPeriodStart = Calendar.current.startOfDay(for: $0) }
                    ),
                    displayedComponents: .date
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(SleepTheme.background.ignoresSafeArea())
        .navigationTitle("Réglages du cycle")
        .navigationBarTitleDisplayMode(.inline)
    }
}
