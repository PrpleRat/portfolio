import SwiftData
import SwiftUI

struct HomeView: View {

    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm = HomeViewModel()
    @State private var showSetup = false
    @State private var showCheckIn = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    switch vm.state {
                    case .noSession:
                        emptyState
                    case .active(let remaining):
                        if let session = vm.activeSession {
                            activeContent(session: session, remaining: remaining)
                        }
                    case .pendingCheckIn:
                        if let session = vm.activeSession {
                            pendingContent(session: session)
                        }
                    case .alertTriggered:
                        if let session = vm.activeSession {
                            alertContent(session: session)
                        }
                    }

                    if !vm.recentSessions.isEmpty {
                        recentSection
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    BrandHeader(compact: true)
                }
            }
            .onAppear { vm.refresh(context: modelContext) }
            .sheet(isPresented: $showSetup) {
                SetupView(onComplete: {
                    showSetup = false
                    vm.refresh(context: modelContext)
                })
            }
            .sheet(isPresented: $showCheckIn) {
                if let session = vm.activeSession {
                    CheckInView(session: session, cycle: max(1, session.checkIns.count + 1))
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            BrandHeader()

            Image(systemName: "flame.fill")
                .font(.system(size: 72))
                .foregroundStyle(.safeOrange)
                .symbolEffect(.pulse)

            Text("Aucune session active")
                .font(.title2.bold())

            Text("Lance RAS avant de partir en randonnée, en voiture ou en zone isolée.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Démarrer une session") {
                showSetup = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.top, 40)
    }

    private func activeContent(session: SafeSession, remaining: TimeInterval) -> some View {
        VStack(spacing: 20) {
            SessionStatusBanner(session: session, state: vm.state)

            TimerRingView(
                timeRemaining: remaining,
                totalInterval: TimeInterval(session.intervalMinutes * 60)
            )

            if let deadline = session.nextDeadline {
                Text("Prochain check-in à \(deadline.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
            }

            if let config = vm.linkedConfig, !config.contacts.isEmpty {
                let names = config.contacts.prefix(2).map(\.firstName).joined(separator: ", ")
                let extra = max(0, config.contacts.count - 2)
                Text("Contacts : \(names)\(extra > 0 ? " (+\(extra))" : "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("✋ Vérifier maintenant") {
                showCheckIn = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.safeGreen)

            sessionControls(session: session)
        }
    }

    private func pendingContent(session: SafeSession) -> some View {
        VStack(spacing: 16) {
            SessionStatusBanner(session: session, state: .pendingCheckIn(cycle: 1))
            Text("Vérification requise maintenant")
                .font(.title3.bold())
                .foregroundStyle(.safeRed)
            Button("Répondre maintenant") { showCheckIn = true }
                .buttonStyle(.borderedProminent)
                .tint(.safeRed)
            sessionControls(session: session)
        }
    }

    private func alertContent(session: SafeSession) -> some View {
        VStack(spacing: 16) {
            SessionStatusBanner(session: session, state: .alertTriggered)
            Text("Une alerte a été déclenchée ou est imminente.")
                .foregroundStyle(.safeRed)
            Button("Ouvrir la vérification") { showCheckIn = true }
                .buttonStyle(.borderedProminent)
            sessionControls(session: session)
        }
    }

    private func sessionControls(session: SafeSession) -> some View {
        HStack {
            Button("Modifier") { showSetup = true }
            Spacer()
            Button("Arrêter", role: .destructive) {
                Task { await vm.endSession(context: modelContext) }
            }
        }
        .font(.subheadline)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessions récentes")
                .font(.headline)
            ForEach(vm.recentSessions, id: \.id) { session in
                SessionRowView(session: session)
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: SafeSession.self, inMemory: true)
}
