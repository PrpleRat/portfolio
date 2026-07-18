import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Application") {
                    NavigationLink("À propos") { AboutView() }
                    Link("API SNCF (trains)", destination: URL(string: "https://numerique.sncf.com/startup/api/")!)
                    Link("HeiGIT / ORS (routes)", destination: URL(string: "https://account.heigit.org/manage/key")!)
                }
                Section("Clés API") {
                    HStack {
                        Image(systemName: APIKeysValidator.isConfigured ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(APIKeysValidator.isConfigured ? .green : .orange)
                        Text(APIKeysValidator.configurationHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Réglages")
        }
    }
}
