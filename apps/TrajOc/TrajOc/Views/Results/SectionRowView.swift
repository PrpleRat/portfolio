import SwiftUI

struct SectionRowView: View {
    let section: JourneySection
    @State private var showInstructions = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Circle()
                    .fill(TransportStyle.color(for: section.mode))
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 2)
            }

            VStack(alignment: .leading, spacing: 6) {
                if let dep = section.departureTime {
                    Text(DurationFormatter.format(date: dep))
                        .font(.caption.weight(.semibold))
                }
                Text(section.from.name)
                    .font(.subheadline.weight(.medium))

                if let line = section.line {
                    HStack {
                        TransportBadge(mode: section.mode, label: line.code)
                        Text("\(line.network) · \(line.direction ?? "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if section.type == .waiting {
                    Text("⏱ \(DurationFormatter.format(seconds: section.duration)) d'attente")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Label(section.mode.displayName, systemImage: section.mode.sfSymbol)
                        .font(.caption)
                }

                if !section.turnInstructions.isEmpty {
                    DisclosureGroup("Instructions", isExpanded: $showInstructions) {
                        ForEach(section.turnInstructions, id: \.self) { step in
                            Text("• \(step)")
                                .font(.caption2)
                        }
                    }
                }

                if let boarding = section.boardingPosition {
                    Text(boarding)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if !section.disruptions.isEmpty {
                    Text("⚠️ Perturbation")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
