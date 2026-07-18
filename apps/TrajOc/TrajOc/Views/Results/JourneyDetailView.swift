import MapKit
import SwiftUI

struct JourneyDetailView: View {
    let journey: Journey
    @State private var selectedSection: JourneySection?
    @State private var showFullMap = false
    @Environment(\.modelContext) private var modelContext
    @StateObject private var favoritesVM = FavoritesViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TrajOcMapView(journey: journey, selectedSection: $selectedSection)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Button("Agrandir la carte") { showFullMap = true }

                summaryBlock

                if journey.hasDisruptions {
                    DisruptionBanner(message: "Perturbation possible sur cet itinéraire")
                }

                ForEach(journey.sections) { section in
                    SectionRowView(section: section)
                }

                actionButtons
            }
            .padding()
        }
        .navigationTitle("Détail")
        .sheet(isPresented: $showFullMap) {
            TrajOcMapView(journey: journey, selectedSection: $selectedSection)
                .ignoresSafeArea()
        }
    }

    private var summaryBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(DurationFormatter.format(date: journey.departureTime)) → \(DurationFormatter.format(date: journey.arrivalTime))")
                .font(.title3.bold())
            Text("\(DurationFormatter.format(seconds: journey.duration)) · \(journey.transfers) corresp. · 🌱 \(Int(journey.co2EmissionsGrams))g CO₂")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var actionButtons: some View {
        HStack {
            Button {
                if let first = journey.sections.first, let last = journey.sections.last {
                    favoritesVM.add(journey, origin: first.from, destination: last.to, context: modelContext)
                }
            } label: {
                Label("Favori", systemImage: "star")
            }
            ShareLink(item: shareText)
            Button("Plans") { openInMaps() }
        }
        .buttonStyle(.bordered)
    }

    private var shareText: String {
        "\(DurationFormatter.format(date: journey.departureTime)) → \(DurationFormatter.format(date: journey.arrivalTime)) via TrajOc"
    }

    private func openInMaps() {
        guard let last = journey.sections.last else { return }
        let item = MKMapItem(placemark: MKPlacemark(coordinate: last.to.clCoordinate))
        item.name = last.to.name
        item.openInMaps()
    }
}
