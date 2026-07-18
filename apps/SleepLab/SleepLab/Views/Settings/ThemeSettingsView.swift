import SwiftUI

/// Choix du thème sur un écran dédié — évite de remonter le formulaire Réglages.
struct ThemeSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            ThemePickerView()
                .padding()
        }
        .background(SleepTheme.background.ignoresSafeArea())
        .navigationTitle("Thème")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: themeManager.revision) { _, _ in }
    }
}
