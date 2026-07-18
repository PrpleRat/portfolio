import SwiftUI

struct TemplatesView: View {
    @ObservedObject private var storage = TemplateStorage.shared
    @State private var editingTemplate: LicenseTemplate?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BeatDealSpacing.md) {
                    Text("Personnalise les conditions par défaut de chaque type de licence.")
                        .font(BeatDealTypography.body)
                        .foregroundStyle(BeatDealColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(storage.templates) { template in
                        templateCard(template)
                    }
                }
                .padding(BeatDealSpacing.md)
            }
            .background(BeatDealColors.background.ignoresSafeArea())
            .navigationTitle("Mes modèles")
            .sheet(item: $editingTemplate) { template in
                TemplateEditorView(template: template) { updated in
                    storage.update(updated)
                }
            }
        }
    }

    private func templateCard(_ template: LicenseTemplate) -> some View {
        Button {
            editingTemplate = template
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: BeatDealSpacing.xs) {
                    Text(template.licenseType.title)
                        .font(BeatDealTypography.headline)
                        .foregroundStyle(BeatDealColors.text)
                    Text("\(template.defaultPrice) € · \(formatStreams(template.maxStreams)) streams")
                        .font(BeatDealTypography.caption)
                        .foregroundStyle(BeatDealColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(BeatDealColors.textSecondary)
            }
            .beatDealCard()
        }
        .buttonStyle(.plain)
    }

    private func formatStreams(_ count: Int) -> String {
        if count == Int.max { return "∞" }
        return count.formatted()
    }
}

struct TemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State var template: LicenseTemplate
    var onSave: (LicenseTemplate) -> Void

    @State private var priceText: String = ""
    @State private var streamsText: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BeatDealSpacing.md) {
                    BeatDealTextField(title: "Prix par défaut (€)", text: $priceText, keyboard: .numberPad)
                    BeatDealTextField(title: "Streams max", text: $streamsText, keyboard: .numberPad)

                    RightsToggleSection(rights: $template.defaultRights)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clause additionnelle par défaut")
                            .font(BeatDealTypography.caption)
                            .foregroundStyle(BeatDealColors.textSecondary)
                        TextField("Clause…", text: $template.defaultClause, axis: .vertical)
                            .lineLimit(2...5)
                            .padding(12)
                            .background(BeatDealColors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(BeatDealColors.separator, lineWidth: 1)
                            )
                            .foregroundStyle(BeatDealColors.text)
                    }
                }
                .padding(BeatDealSpacing.md)
            }
            .background(BeatDealColors.background.ignoresSafeArea())
            .navigationTitle(template.licenseType.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        if let price = Int(priceText) { template.defaultPrice = price }
                        if let streams = Int(streamsText) { template.maxStreams = streams }
                        onSave(template)
                        dismiss()
                    }
                }
            }
            .onAppear {
                priceText = String(template.defaultPrice)
                streamsText = template.maxStreams == Int.max ? "999999999" : String(template.maxStreams)
            }
        }
    }
}

#Preview {
    TemplatesView()
        .preferredColorScheme(.dark)
}
