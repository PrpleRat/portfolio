import SwiftUI
import UIKit

struct DeliveryChecklistView: View {
    @Binding var checklist: DeliveryChecklist

    var body: some View {
        VStack(alignment: .leading, spacing: BeatDealSpacing.md) {
            HStack {
                Text("Checklist de livraison")
                    .font(BeatDealTypography.headline)
                    .foregroundStyle(BeatDealColors.text)
                Spacer()
                Text("\(checklist.completedCount)/\(DeliveryChecklist.items.count)")
                    .font(BeatDealTypography.caption)
                    .foregroundStyle(checklist.isComplete ? BeatDealColors.success : BeatDealColors.textSecondary)
            }

            ForEach(Array(DeliveryChecklist.items.enumerated()), id: \.offset) { _, item in
                Toggle(isOn: binding(for: item.keyPath)) {
                    Text(item.label)
                        .font(BeatDealTypography.body)
                        .foregroundStyle(BeatDealColors.text)
                }
                .tint(BeatDealColors.accent)
            }

            if checklist.isComplete {
                Label("Livraison complète", systemImage: "checkmark.seal.fill")
                    .font(BeatDealTypography.caption)
                    .foregroundStyle(BeatDealColors.success)
            }
        }
        .beatDealCard()
    }

    private func binding(for keyPath: WritableKeyPath<DeliveryChecklist, Bool>) -> Binding<Bool> {
        Binding(
            get: { checklist[keyPath: keyPath] },
            set: { checklist[keyPath: keyPath] = $0 }
        )
    }
}

struct DMKitView: View {
    let message: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: BeatDealSpacing.md) {
            HStack {
                Text("DM Kit")
                    .font(BeatDealTypography.headline)
                    .foregroundStyle(BeatDealColors.text)
                Spacer()
                Text("Instagram · iMessage")
                    .font(BeatDealTypography.caption)
                    .foregroundStyle(BeatDealColors.textSecondary)
            }

            Text(message)
                .font(BeatDealTypography.body)
                .foregroundStyle(BeatDealColors.text)
                .textSelection(.enabled)
                .padding(BeatDealSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(BeatDealColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Button {
                UIPasteboard.general.string = message
                copied = true
            } label: {
                Label(copied ? "Copié !" : "Copier le message", systemImage: copied ? "checkmark" : "doc.on.doc")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .beatDealCard()
    }
}

struct CoProducerEditorView: View {
    @Binding var enabled: Bool
    @Binding var coProducer: CoProducer

    var body: some View {
        VStack(alignment: .leading, spacing: BeatDealSpacing.sm) {
            Toggle(isOn: $enabled) {
                Text("Mode co-prod")
                    .font(BeatDealTypography.headline)
                    .foregroundStyle(BeatDealColors.text)
            }
            .tint(BeatDealColors.accent)

            if enabled {
                BeatDealTextField(title: "Nom du co-producteur", text: $coProducer.name, required: true)
                BeatDealTextField(title: "Alias (ex : Prod. by X)", text: $coProducer.alias)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Part du co-producteur : \(coProducer.sharePercent) %")
                        .font(BeatDealTypography.caption)
                        .foregroundStyle(BeatDealColors.textSecondary)
                    Slider(
                        value: Binding(
                            get: { Double(coProducer.sharePercent) },
                            set: { coProducer.sharePercent = Int($0) }
                        ),
                        in: 1...99,
                        step: 1
                    )
                    .tint(BeatDealColors.accent)
                    Text("Toi : \(coProducer.mainProducerSharePercent) % · Co-prod : \(coProducer.sharePercent) %")
                        .font(BeatDealTypography.caption)
                        .foregroundStyle(BeatDealColors.accentLight)
                }
            }
        }
        .beatDealCard()
    }
}
