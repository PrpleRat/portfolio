import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @ObservedObject private var navigationState = AppNavigationState.shared
    @ObservedObject private var contractStorage = ContractStorage.shared

    @State private var showSplitFromLink = false
    @State private var showContractFromLink = false
    @State private var splitImport: SplitPadImport?
    @State private var selectedContract: Contract?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Accueil", systemImage: "house.fill")
                }
                .tag(0)

            RevenueDashboardView()
                .tabItem {
                    Label("Revenus", systemImage: "eurosign.circle.fill")
                }
                .tag(1)

            CatalogView()
                .tabItem {
                    Label("Catalogue", systemImage: "music.note.list")
                }
                .tag(2)

            LicenseTrackerView()
                .tabItem {
                    Label("Licences", systemImage: "bell.badge.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Réglages", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(BeatDealColors.accent)
        .onChange(of: deepLinkRouter.pendingSplitImport?.id) { _, _ in
            guard deepLinkRouter.pendingSplitImport != nil else { return }
            deepLinkRouter.showImportChoice = true
        }
        .confirmationDialog(
            "Import SplitPad",
            isPresented: $deepLinkRouter.showImportChoice,
            titleVisibility: .visible
        ) {
            Button("Créer un split") {
                splitImport = deepLinkRouter.consumePendingImport()
                showSplitFromLink = true
            }
            Button("Créer un contrat") {
                splitImport = deepLinkRouter.consumePendingImport()
                showContractFromLink = true
            }
            Button("Annuler", role: .cancel) {
                _ = deepLinkRouter.consumePendingImport()
            }
        } message: {
            Text("Que veux-tu faire avec ces données ?")
        }
        .sheet(isPresented: $showSplitFromLink, onDismiss: { splitImport = nil }) {
            if let splitImport {
                NewSplitSheetView(splitImport: splitImport)
            }
        }
        .sheet(isPresented: $showContractFromLink, onDismiss: { splitImport = nil }) {
            if let splitImport {
                NewContractView(splitImport: splitImport)
            }
        }
        .sheet(item: $selectedContract) { contract in
            ContractDetailView(contract: contract)
        }
        .onChange(of: navigationState.contractIdToOpen) { _, contractId in
            guard let contractId,
                  let contract = contractStorage.contracts.first(where: { $0.id == contractId }) else { return }
            selectedTab = 3
            selectedContract = contract
            _ = navigationState.consumeContractToOpen()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DeepLinkRouter.shared)
        .preferredColorScheme(.dark)
}
