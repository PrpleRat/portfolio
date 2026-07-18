import SwiftData
import SwiftUI

/// Racine de l’onglet Cycle (barre du bas).
struct CycleTabRootView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first {
                    CycleDashboardView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                NavigationLink {
                                    CycleProfileSettingsView(profile: profile)
                                } label: {
                                    Image(systemName: "gearshape")
                                }
                                .accessibilityLabel("Réglages du cycle")
                            }
                        }
                } else {
                    ProgressView("Chargement…")
                }
            }
            .background(SleepTheme.background.ignoresSafeArea())
        }
    }
}
