import SwiftUI

/// Guide rapide pour les nouveaux utilisateurs (accueil épuré).
struct HomeQuickGuideCard: View {
    @AppStorage("homeQuickGuideDismissed") private var dismissed = false

    var body: some View {
        if !dismissed {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Premiers pas")
                        .font(.headline)
                    Spacer()
                    Button {
                        withAnimation { dismissed = true }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(SleepTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                guideRow("1", "Lancer une nuit", "Le gros bouton en haut. iPhone sur le matelas, écran vers le bas.")
                guideRow("2", "Journal (optionnel)", "Café, alcool, stress… même dans la journée — relié à la nuit automatiquement.")
                guideRow("3", "Lendemain", "Score + dette + énergie. Tape les repères pour comprendre chaque courbe.")
                guideRow("4", "Détails si besoin", "« Voir analyses détaillées » : récupération, cycle, caféine personnelle.")
            }
            .padding()
            .background(SleepTheme.accent.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func guideRow(_ number: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption.bold())
                .frame(width: 22, height: 22)
                .background(SleepTheme.accent.opacity(0.3))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
    }
}
