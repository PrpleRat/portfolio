import SwiftUI

struct SessionStatusBanner: View {
    let session: SafeSession
    let state: HomeViewModel.HomeState

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.safeCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var iconName: String {
        switch state {
        case .alertTriggered: return "exclamationmark.triangle.fill"
        case .pendingCheckIn: return "hand.raised.fill"
        default: return "checkmark.shield.fill"
        }
    }

    private var iconColor: Color {
        switch state {
        case .alertTriggered, .pendingCheckIn: return .safeRed
        default: return .safeGreen
        }
    }

    private var subtitle: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        let elapsed = formatter.localizedString(for: session.startTime, relativeTo: Date())
        switch state {
        case .alertTriggered: return "Alerte déclenchée · démarré \(elapsed)"
        case .pendingCheckIn: return "Vérification en attente"
        default: return "Démarré \(elapsed)"
        }
    }
}
