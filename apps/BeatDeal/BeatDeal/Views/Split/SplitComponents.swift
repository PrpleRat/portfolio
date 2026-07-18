import SwiftUI
import UIKit

struct SplitTotalIndicator: View {
    let label: String
    let total: Int
    let target: Int

    private var isValid: Bool { total == target }
    private var remaining: Int { target - total }

    var body: some View {
        VStack(alignment: .leading, spacing: BeatDealSpacing.xs) {
            HStack {
                Text(label)
                    .font(BeatDealTypography.body)
                    .foregroundStyle(BeatDealColors.text)
                Spacer()
                Text("\(total)% / \(target)%")
                    .font(BeatDealTypography.caption)
                    .foregroundStyle(isValid ? BeatDealColors.success : BeatDealColors.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(BeatDealColors.separator)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isValid ? BeatDealColors.success : BeatDealColors.accent)
                        .frame(width: geo.size.width * CGFloat(min(total, target)) / CGFloat(target))
                }
            }
            .frame(height: 8)
            if !isValid {
                Text(remaining > 0 ? "Il manque \(remaining)%" : "Dépassement de \(-remaining)%")
                    .font(BeatDealTypography.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(BeatDealSpacing.md)
        .beatDealCard()
    }
}

struct SplitGenrePicker: View {
    @Binding var genre: String
    @Binding var subgenre: String

    private var subgenres: [String] {
        SplitConstants.genreCatalog.first { $0.genre == genre }?.subgenres ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BeatDealSpacing.sm) {
            Text("Genre")
                .font(BeatDealTypography.caption)
                .foregroundStyle(BeatDealColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BeatDealSpacing.sm) {
                    ForEach(SplitConstants.genreCatalog.map(\.genre), id: \.self) { g in
                        genreChip(g)
                    }
                }
            }

            if !genre.isEmpty, !subgenres.isEmpty {
                Text("Sous-genre")
                    .font(BeatDealTypography.caption)
                    .foregroundStyle(BeatDealColors.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: BeatDealSpacing.sm) {
                        ForEach(subgenres, id: \.self) { s in
                            subgenreChip(s)
                        }
                    }
                }
            }
        }
    }

    private func genreChip(_ g: String) -> some View {
        Button(g) {
            if genre == g {
                genre = ""
                subgenre = ""
            } else {
                genre = g
                subgenre = ""
            }
        }
        .font(BeatDealTypography.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(genre == g ? BeatDealColors.accent : BeatDealColors.card)
        .foregroundStyle(BeatDealColors.text)
        .clipShape(Capsule())
    }

    private func subgenreChip(_ s: String) -> some View {
        Button(s) {
            subgenre = subgenre == s ? "" : s
        }
        .font(BeatDealTypography.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(subgenre == s ? BeatDealColors.accent : BeatDealColors.card)
        .foregroundStyle(BeatDealColors.text)
        .clipShape(Capsule())
    }
}

struct SplitMultiRolePicker: View {
    @Binding var roles: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: BeatDealSpacing.xs) {
            HStack(spacing: BeatDealSpacing.xs) {
                Text("Rôles")
                    .font(BeatDealTypography.caption)
                    .foregroundStyle(BeatDealColors.textSecondary)
                BeatDealInfoTip(title: SplitConstants.Help.roles.title, text: SplitConstants.Help.roles.text)
            }

            FlowLayout(spacing: BeatDealSpacing.sm) {
                ForEach(SplitConstants.sacemRoles, id: \.self) { role in
                    roleChip(role)
                }
            }
        }
    }

    private func roleChip(_ role: String) -> some View {
        let selected = roles.contains(role)
        return Button(role) {
            if selected {
                roles.removeAll { $0 == role }
            } else {
                roles.append(role)
            }
            if roles.isEmpty {
                roles = [SplitConstants.defaultRole]
            }
        }
        .font(BeatDealTypography.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(selected ? BeatDealColors.accent : BeatDealColors.card)
        .foregroundStyle(BeatDealColors.text)
        .clipShape(Capsule())
    }
}

struct SplitShareControl: View {
    let label: String
    let infoTitle: String
    let infoText: String
    let recommended: Int?
    @Binding var value: Int

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: BeatDealSpacing.xs) {
            HStack {
                HStack(spacing: BeatDealSpacing.xs) {
                    Text(label)
                        .foregroundStyle(BeatDealColors.textSecondary)
                    BeatDealInfoTip(title: infoTitle, text: infoText)
                }
                Spacer()
                HStack(spacing: 4) {
                    TextField("0", text: $textValue)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 44)
                        .focused($isFocused)
                        .onChange(of: textValue) { _, newValue in
                            let digits = newValue.filter(\.isNumber)
                            if digits != newValue {
                                textValue = digits
                            }
                            if let n = Int(digits) {
                                let clamped = min(100, max(0, n))
                                if clamped != value {
                                    value = clamped
                                    haptic()
                                }
                                if digits != String(clamped) {
                                    textValue = String(clamped)
                                }
                            } else if digits.isEmpty {
                                value = 0
                            }
                        }
                    Text("%")
                        .foregroundStyle(BeatDealColors.accentLight)
                        .fontWeight(.bold)
                }
            }

            if let recommended, recommended > 0 {
                Text("Pourcentage recommandé pour ce rôle : \(recommended)%")
                    .font(BeatDealTypography.caption)
                    .foregroundStyle(BeatDealColors.accentLight)
            }

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { newVal in
                        let rounded = Int(newVal.rounded())
                        if rounded != value {
                            value = rounded
                            haptic()
                        }
                    }
                ),
                in: 0...100,
                step: 1
            )
            .tint(BeatDealColors.accent)
        }
        .onAppear { textValue = String(value) }
        .onChange(of: value) { _, newValue in
            if !isFocused {
                textValue = String(newValue)
            }
        }
    }

    private func haptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

struct SplitCollaboratorEditor: View {
    @Binding var collaborator: SplitCollaborator
    let splitType: SplitSheetType
    let canRemove: Bool
    let onRemove: () -> Void

    private var recommendation: SplitConstants.RoleRecommendation {
        SplitConstants.recommendedShares(for: collaborator.roles)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BeatDealSpacing.sm) {
            HStack {
                Text("Collaborateur")
                    .font(BeatDealTypography.headline)
                    .foregroundStyle(BeatDealColors.accentLight)
                Spacer()
                if canRemove {
                    Button(role: .destructive, action: onRemove) {
                        Image(systemName: "trash")
                    }
                }
            }

            BeatDealTextField(title: "Nom / alias", text: $collaborator.name, required: true)

            SplitMultiRolePicker(roles: $collaborator.roles)

            SplitShareControl(
                label: "Part Master",
                infoTitle: SplitConstants.Help.masterShare.title,
                infoText: SplitConstants.Help.masterShare.text,
                recommended: recommendation.master > 0 ? recommendation.master : nil,
                value: $collaborator.masterShare
            )

            if splitType == .masterAndPublishing {
                SplitShareControl(
                    label: "Part Publishing",
                    infoTitle: SplitConstants.Help.publishingShare.title,
                    infoText: SplitConstants.Help.publishingShare.text,
                    recommended: recommendation.publishing > 0 ? recommendation.publishing : nil,
                    value: $collaborator.publishingShare
                )
            }

            HStack(spacing: BeatDealSpacing.xs) {
                BeatDealTextField(title: "SACEM / PRO", text: Binding(
                    get: { collaborator.sacem ?? "" },
                    set: { collaborator.sacem = $0.isEmpty ? nil : $0 }
                ), keyboard: .numberPad)
                BeatDealInfoTip(title: SplitConstants.Help.sacem.title, text: SplitConstants.Help.sacem.text)
                    .padding(.top, 20)
            }

            BeatDealTextField(title: "Email", text: Binding(
                get: { collaborator.email ?? "" },
                set: { collaborator.email = $0.isEmpty ? nil : $0 }
            ), keyboard: .emailAddress)

            Toggle(isOn: $collaborator.signed) {
                Text("A signé le split")
                    .font(BeatDealTypography.body)
                    .foregroundStyle(BeatDealColors.text)
            }
            .tint(BeatDealColors.accent)
        }
        .beatDealCard()
    }
}

/// Disposition en lignes pour les chips de rôles.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}
