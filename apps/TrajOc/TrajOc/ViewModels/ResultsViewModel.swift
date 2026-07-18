import Combine
import Foundation

@MainActor
final class ResultsViewModel: ObservableObject {
    @Published var journeys: [Journey]
    @Published var selectedJourney: Journey?
    @Published var disruptions: [Disruption] = []

    private let navitia = NavitiaService.shared

    init(journeys: [Journey]) {
        self.journeys = journeys
    }

    func loadDisruptions() {
        Task {
            disruptions = (try? await navitia.disruptions()) ?? []
            applyDisruptionFlags()
        }
    }

    private func applyDisruptionFlags() {
        let activeIds = Set(disruptions.filter { $0.status == .active }.flatMap(\.affectedLines))
        journeys = journeys.map { journey in
            var copy = journey
            copy.hasDisruptions = journey.sections.contains { section in
                section.line.map { activeIds.contains($0.id) } ?? false
            }
            return copy
        }
    }

    func shareText(for journey: Journey) -> String {
        let dep = DurationFormatter.format(date: journey.departureTime)
        let arr = DurationFormatter.format(date: journey.arrivalTime)
        let duration = DurationFormatter.format(seconds: journey.duration)
        return "TrajOc — \(dep) → \(arr) (\(duration)), \(journey.transfers) corresp."
    }
}
