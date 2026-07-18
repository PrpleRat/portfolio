import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("TrajOc")
                    .font(.largeTitle.bold())
                Text("Planificateur d'itinéraires multimodal pour l'Occitanie.")
                    .foregroundStyle(.secondary)

                Group {
                    Text("Données")
                        .font(.headline)
                    Text("• Navitia.io — transports en commun\n• OpenRouteService — voiture, vélo, marche\n• OpenStreetMap Nominatim — adresses\n• JCDecaux — vélos en libre-service")
                        .font(.subheadline)
                }

                Group {
                    Text("Licences")
                        .font(.headline)
                    Text("Données © contributeurs OpenStreetMap (ODbL). APIs soumises à leurs conditions d'utilisation respectives.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
        }
        .navigationTitle("À propos")
        .navigationBarTitleDisplayMode(.inline)
    }
}
