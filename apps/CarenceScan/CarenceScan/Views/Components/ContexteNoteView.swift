import SwiftUI

struct ContexteNoteView: View {
    let icon: String
    let note: NoteContexte
    let background: Color

    @State private var isExpanded = false

    private var hasDetails: Bool {
        note.explication != nil || !note.sources.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                guard hasDetails else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .top, spacing: 6) {
                    Text(icon)
                        .font(.caption2)
                    Text(note.message)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CarenceColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if hasDetails {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CarenceColors.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(note.message)
            .accessibilityHint(hasDetails ? (isExpanded ? "Réduire les détails" : "Afficher les détails") : "")

            if isExpanded, hasDetails {
                VStack(alignment: .leading, spacing: 8) {
                    if let explication = note.explication {
                        Text(explication)
                            .font(.caption2)
                            .foregroundStyle(CarenceColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !note.sources.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sources")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(CarenceColors.textSecondary)
                            ForEach(note.sources) { source in
                                if let url = URL(string: source.url) {
                                    Link(destination: url) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "link")
                                                .font(.caption2)
                                            Text(source.label)
                                                .font(.caption2)
                                                .underline()
                                        }
                                        .foregroundStyle(CarenceColors.primary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
