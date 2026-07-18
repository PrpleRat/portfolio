import SwiftUI

struct SessionRowView: View {
    let session: SafeSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.name)
                    .font(.headline)
                Spacer()
                if session.wasAlertTriggered {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.safeOrange)
                }
            }

            Text(dateRange)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Label("\(session.totalCheckIns) check-ins", systemImage: "checkmark.circle")
                if session.wasAlertTriggered {
                    Text("· \(session.totalCheckIns > 0 ? "1 alerte" : "alerte")")
                        .foregroundStyle(.safeOrange)
                }
            }
            .font(.caption)

            Text("Durée : \(session.duration.formattedCountdown)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var dateRange: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale(identifier: "fr_FR")
        let end = session.endTime.map { f.string(from: $0) } ?? "en cours"
        return "\(f.string(from: session.startTime)) → \(end)"
    }
}
