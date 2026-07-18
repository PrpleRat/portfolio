import SwiftUI

struct LicenseTrackerView: View {
    @ObservedObject private var storage = ContractStorage.shared
    @ObservedObject private var alertService = LicenseAlertService.shared
    @State private var selectedContract: Contract?

    private var trackedContracts: [Contract] {
        storage.contracts.filter { !$0.licenseType.isExclusive }
    }

    private var alertContracts: [Contract] {
        trackedContracts.filter(\.needsLicenseAlert)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BeatDealSpacing.md) {
                    if !alertService.authorizationGranted {
                        notificationBanner
                    }

                    if !alertContracts.isEmpty {
                        alertSection
                    }

                    if trackedContracts.isEmpty {
                        emptyState
                    } else {
                        ForEach(trackedContracts) { contract in
                            LicenseTrackerRow(contract: contract) {
                                selectedContract = contract
                            }
                        }
                    }
                }
                .padding(BeatDealSpacing.md)
            }
            .background(BeatDealColors.background.ignoresSafeArea())
            .navigationTitle("Licences")
            .sheet(item: $selectedContract) { contract in
                LicenseDetailView(contract: contract)
            }
            .task {
                await alertService.requestAuthorizationIfNeeded()
                await alertService.refreshAlerts(for: storage.contracts)
            }
        }
    }

    private var notificationBanner: some View {
        VStack(alignment: .leading, spacing: BeatDealSpacing.sm) {
            Text("Active les notifications pour être alerté quand une licence approche de sa limite.")
                .font(BeatDealTypography.caption)
                .foregroundStyle(BeatDealColors.textSecondary)
            Button("Activer les alertes") {
                Task { await alertService.requestAuthorizationIfNeeded() }
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .beatDealCard()
    }

    private var alertSection: some View {
        VStack(alignment: .leading, spacing: BeatDealSpacing.sm) {
            Label("\(alertContracts.count) licence\(alertContracts.count > 1 ? "s" : "") à surveiller", systemImage: "bell.badge.fill")
                .font(BeatDealTypography.headline)
                .foregroundStyle(BeatDealColors.accentLight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: BeatDealSpacing.md) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(BeatDealColors.accent.opacity(0.6))
            Text("Les leases non-exclusifs apparaîtront ici")
                .font(BeatDealTypography.body)
                .foregroundStyle(BeatDealColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BeatDealSpacing.xl)
        .beatDealCard()
    }
}

struct LicenseTrackerRow: View {
    let contract: Contract
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: BeatDealSpacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contract.beatTitle)
                            .font(BeatDealTypography.headline)
                            .foregroundStyle(BeatDealColors.text)
                        Text(contract.artistName)
                            .font(BeatDealTypography.caption)
                            .foregroundStyle(BeatDealColors.textSecondary)
                    }
                    Spacer()
                    if contract.needsLicenseAlert {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }

                Text(contract.licenseType.title)
                    .font(BeatDealTypography.badge)
                    .foregroundStyle(contract.licenseType.badgeColor)

                if let ratio = contract.streamUsageRatio {
                    ProgressView(value: min(ratio, 1.0))
                        .tint(ratio >= AppConstants.streamAlertThreshold ? .orange : BeatDealColors.accent)
                    Text(contract.licenseStatusLabel)
                        .font(BeatDealTypography.caption)
                        .foregroundStyle(BeatDealColors.textSecondary)
                } else if contract.expiresAt != nil {
                    Text(contract.licenseStatusLabel)
                        .font(BeatDealTypography.caption)
                        .foregroundStyle(BeatDealColors.textSecondary)
                }

                if let upgrade = contract.suggestedUpgradeLicense, contract.needsLicenseAlert {
                    Text("Upgrade suggéré : \(upgrade.title)")
                        .font(BeatDealTypography.caption)
                        .foregroundStyle(BeatDealColors.success)
                }
            }
            .beatDealCard(selected: contract.needsLicenseAlert)
        }
        .buttonStyle(.plain)
    }
}

struct LicenseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storage = ContractStorage.shared
    @State var contract: Contract
    @State private var streamsText = ""
    @State private var showContractKit = false
    @State private var showDeleteConfirm = false
    @State private var showUpgradeContract = false
    @State private var beatBillMissing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BeatDealSpacing.md) {
                    BeatDealTextField(title: "Streams actuels (estimation)", text: $streamsText, keyboard: .numberPad)

                    if let ratio = contract.streamUsageRatio {
                        ProgressView(value: min(ratio, 1.0))
                            .tint(ratio >= AppConstants.streamAlertThreshold ? .orange : BeatDealColors.accent)
                        Text("\(Int(ratio * 100)) % de la limite (\(contract.maxStreams.formatted()) max)")
                            .font(BeatDealTypography.caption)
                            .foregroundStyle(BeatDealColors.textSecondary)
                    }

                    if let expiresAt = contract.expiresAt {
                        Text("Expiration : \(formattedDate(expiresAt))")
                            .font(BeatDealTypography.body)
                            .foregroundStyle(BeatDealColors.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let upgrade = contract.suggestedUpgradeLicense {
                        VStack(alignment: .leading, spacing: BeatDealSpacing.sm) {
                            Text("Opportunité de vente")
                                .font(BeatDealTypography.caption)
                                .foregroundStyle(BeatDealColors.textSecondary)
                            Text("Propose un upgrade \(upgrade.title) à \(contract.artistName) pour « \(contract.beatTitle) ».")
                                .font(BeatDealTypography.body)
                                .foregroundStyle(BeatDealColors.text)
                            Button("Créer contrat \(upgrade.title)") { showUpgradeContract = true }
                                .buttonStyle(PrimaryButtonStyle())
                        }
                        .beatDealCard()
                    }

                    Button("Facturer avec BeatBill") {
                        if !BeatBillLink.openInvoice(from: contract) {
                            beatBillMissing = true
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button("DM Kit, PDF & livraison") { showContractKit = true }
                        .buttonStyle(SecondaryButtonStyle())

                    Button("Enregistrer") { save() }
                        .buttonStyle(PrimaryButtonStyle())

                    Button("Supprimer le contrat", role: .destructive) {
                        showDeleteConfirm = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(BeatDealSpacing.md)
            }
            .background(BeatDealColors.background.ignoresSafeArea())
            .navigationTitle(contract.beatTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .confirmationDialog(
                "Supprimer ce contrat ?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Supprimer", role: .destructive) {
                    storage.delete(contract)
                    dismiss()
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("« \(contract.beatTitle) » sera définitivement supprimé.")
            }
            .onAppear {
                streamsText = String(contract.streamsUsed)
            }
            .sheet(isPresented: $showContractKit) {
                ContractDetailView(contract: contract)
            }
            .sheet(isPresented: $showUpgradeContract) {
                NewContractView(upgradeFromContract: contract)
            }
            .alert("BeatBill introuvable", isPresented: $beatBillMissing) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Installe BeatBill pour facturer depuis cette licence.")
            }
        }
    }

    private func save() {
        contract.streamsReported = Int(streamsText.trimmingCharacters(in: .whitespaces)) ?? 0
        storage.save(contract)
        dismiss()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    LicenseTrackerView()
        .preferredColorScheme(.dark)
}
