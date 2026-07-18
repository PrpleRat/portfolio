import SwiftUI

struct SellFromCatalogContext: Identifiable {
    let id = UUID()
    let beat: CatalogBeat?
    let pack: BeatPack?
}

struct SellFromCatalogSheet: View {
    let context: SellFromCatalogContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var templateStorage = TemplateStorage.shared
    @State private var selectedLicense: LicenseType = .wavLease
    @State private var showContract = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: BeatDealSpacing.md) {
                Text("Type de licence")
                    .font(BeatDealTypography.headline)
                    .foregroundStyle(BeatDealColors.text)

                ForEach(LicenseType.allCases) { type in
                    let price = displayPrice(for: type)
                    Button {
                        selectedLicense = type
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.title)
                                    .font(BeatDealTypography.body)
                                    .foregroundStyle(BeatDealColors.text)
                                Text("\(price) €")
                                    .font(BeatDealTypography.caption)
                                    .foregroundStyle(BeatDealColors.textSecondary)
                            }
                            Spacer()
                            if selectedLicense == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(BeatDealColors.accent)
                            }
                        }
                        .beatDealCard(selected: selectedLicense == type)
                    }
                    .buttonStyle(.plain)
                }

                Button("Créer le contrat") { showContract = true }
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding(BeatDealSpacing.md)
            .background(BeatDealColors.background.ignoresSafeArea())
            .navigationTitle(sellTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .sheet(isPresented: $showContract) {
                NewContractView(
                    prefillBeat: context.beat,
                    prefillPack: context.pack,
                    prefillLicense: selectedLicense
                )
            }
        }
    }

    private var sellTitle: String {
        context.beat?.title ?? context.pack?.title ?? "Vendre"
    }

    private func displayPrice(for type: LicenseType) -> Int {
        if let beat = context.beat {
            return beat.prices.price(for: type)
        }
        if let pack = context.pack {
            return pack.prices.price(for: type)
        }
        return templateStorage.template(for: type).defaultPrice
    }
}
