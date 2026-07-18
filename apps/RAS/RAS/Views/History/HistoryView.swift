import SwiftData
import SwiftUI

struct HistoryView: View {

    @Query(sort: \SafeSession.startTime, order: .reverse) private var sessions: [SafeSession]
    @State private var selectedSession: SafeSession?

    private var completed: [SafeSession] {
        sessions.filter { !$0.isActive }
    }

    var body: some View {
        NavigationStack {
            Group {
                if completed.isEmpty {
                    ContentUnavailableView(
                        "Aucun historique",
                        systemImage: "clock",
                        description: Text("Tes sessions terminées apparaîtront ici.")
                    )
                } else {
                    List(completed, id: \.id) { session in
                        Button {
                            selectedSession = session
                        } label: {
                            SessionRowView(session: session)
                        }
                    }
                }
            }
            .navigationTitle("Historique")
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
        }
    }
}

struct SessionDetailView: View {
    let session: SafeSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Résumé") {
                    LabeledContent("Nom", value: session.name)
                    LabeledContent("Check-ins", value: "\(session.totalCheckIns)")
                    LabeledContent("Alerte", value: session.wasAlertTriggered ? "Oui" : "Non")
                }

                Section("Timeline") {
                    ForEach(session.checkIns.sorted(by: { $0.date > $1.date }), id: \.date) { record in
                        VStack(alignment: .leading) {
                            Text(record.date.formatted(date: .abbreviated, time: .shortened))
                            if let lat = record.latitude, let lon = record.longitude {
                                Text("GPS : \(String(format: "%.4f", lat)), \(String(format: "%.4f", lon))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(session.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

extension SafeSession: @retroactive Identifiable {}
