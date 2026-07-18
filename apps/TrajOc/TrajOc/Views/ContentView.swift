import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Itinéraire", systemImage: "arrow.triangle.swap")
                }

            NearbyView()
                .tabItem {
                    Label("À proximité", systemImage: "location.circle.fill")
                }

            FavoritesView()
                .tabItem {
                    Label("Favoris", systemImage: "star.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Réglages", systemImage: "gearshape.fill")
                }
        }
        .tint(TransportStyle.occitanieRed())
    }
}

#Preview {
    ContentView()
}
