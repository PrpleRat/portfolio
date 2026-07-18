import SwiftUI

struct JourneyCard: View {
    let journey: Journey

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(DurationFormatter.format(date: journey.departureTime))
                    .font(.headline)
                Spacer()
                Text(DurationFormatter.format(seconds: journey.duration))
                    .font(.headline)
                Text(DurationFormatter.format(date: journey.arrivalTime))
                    .font(.headline)
            }

            modeTimeline

            HStack(spacing: 8) {
                Text("\(journey.transfers) corresp.")
                Text("·")
                Text("🌱 \(Int(journey.co2EmissionsGrams))g")
                if let fare = journey.fare, fare.found {
                    Text("· ~\(String(format: "%.2f", fare.total))€")
                }
                Spacer()
                if journey.hasDisruptions {
                    Text("⚠️ Perturbation")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private var modeTimeline: some View {
        GeometryReader { geo in
            let transportSections = journey.sections.filter {
                $0.type == .publicTransport || ($0.type == .streetNetwork && $0.mode != .walk)
            }
            let total = max(transportSections.map(\.duration).reduce(0, +), 1)
            HStack(spacing: 2) {
                ForEach(transportSections) { section in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(TransportStyle.color(for: section.mode))
                        .frame(width: max(geo.size.width * CGFloat(section.duration) / CGFloat(total), 24))
                }
            }
        }
        .frame(height: 28)
        .overlay(alignment: .leading) {
            HStack(spacing: 4) {
                ForEach(journey.transportModes.prefix(4), id: \.self) { mode in
                    TransportBadge(mode: mode, compact: true)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}
