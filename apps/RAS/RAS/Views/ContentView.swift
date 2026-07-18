import SwiftData
import SwiftUI

struct ContentView: View {

    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SafeSession.startTime, order: .reverse) private var sessions: [SafeSession]
    @ObservedObject private var dispatcher = AlertDispatcher.shared

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Accueil", systemImage: "flame.fill") }

            HistoryView()
                .tabItem { Label("Historique", systemImage: "clock.arrow.circlepath") }

            SettingsView()
                .tabItem { Label("Réglages", systemImage: "gearshape.fill") }
        }
        .sheet(isPresented: $appState.showCheckIn) {
            if let session = resolveSession() {
                CheckInView(session: session, cycle: appState.pendingCycle)
            }
        }
        .sheet(isPresented: $appState.showAlertFlow) {
            if let session = resolveSession() {
                AlertFlowView(session: session)
            }
        }
        .sheet(item: $dispatcher.pendingSMSCompose) { request in
            MessageComposeView(
                recipients: request.recipients,
                body: request.body
            ) { result in
                dispatcher.pendingSMSCompose = nil
                switch result {
                case .sent:
                    dispatcher.dispatchLog.append("✅ SMS envoyé")
                case .cancelled:
                    dispatcher.dispatchLog.append("⚠️ Envoi annulé")
                case .failed:
                    dispatcher.dispatchLog.append("❌ Échec envoi SMS")
                @unknown default:
                    break
                }
            }
        }
        .onChange(of: appState.pendingAutoAlertUserInfo) { _, userInfo in
            guard let userInfo else { return }
            Task {
                _ = await AlertAutoTrigger.dispatchIfNeeded(
                    userInfo: userInfo,
                    modelContext: modelContext
                )
                appState.pendingAutoAlertUserInfo = nil
            }
        }
    }

    private func resolveSession() -> SafeSession? {
        if let id = appState.pendingCheckInSessionId {
            return sessions.first { $0.id == id }
        }
        return sessions.first(where: \.isActive)
    }
}

struct AlertFlowView: View {
    let session: SafeSession
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = CheckInViewModel()
    @ObservedObject private var dispatcher = AlertDispatcher.shared
    @Query private var configs: [AlertConfig]
    @State private var didAutoStart = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.safeRed)

                Text("Alerte en cours")
                    .font(.title2.bold())

                Text(
                    "RAS prépare l'envoi à tes contacts. Sur iPhone, Apple impose un appui sur Envoyer — impossible d'envoyer totalement seul sans serveur."
                )
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

                if dispatcher.isDispatching {
                    ProgressView("Préparation des messages…")
                }

                ForEach(dispatcher.dispatchLog, id: \.self) { line in
                    Text(line)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button("Annuler — Je vais bien") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle(session.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .task {
                guard !didAutoStart else { return }
                didAutoStart = true
                if let config = configs.first(where: { $0.id == session.alertConfigId }) {
                    await vm.triggerAlert(session: session, config: config)
                    try? modelContext.save()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .modelContainer(for: [SafeSession.self, AlertConfig.self, Contact.self], inMemory: true)
}
