import SwiftUI

struct SettingsView: View {

    @State private var notificationsEnabled = false

    var body: some View {
        NavigationStack {
            List {
                Section("Permissions") {
                    Button("Activer les notifications") {
                        Task {
                            notificationsEnabled = await NotificationScheduler.shared.requestPermission()
                        }
                    }
                    Button("Autoriser la localisation") {
                        Task { await LocationService.shared.requestPermission() }
                    }
                }

                Section("Sécurité") {
                    NavigationLink("À propos & limites") {
                        AboutView()
                    }
                }

                Section {
                    Text("RAS — Fusée de détresse")
                        .font(.subheadline)
                    Text("Zéro serveur · Données locales · Open source")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Réglages")
        }
    }
}
