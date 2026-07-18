import Combine
import Foundation
import SwiftData

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [FavoriteJourney] = []

    func reload(from context: ModelContext) {
        let descriptor = FetchDescriptor<FavoriteJourney>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        favorites = (try? context.fetch(descriptor)) ?? []
    }

    func add(_ journey: Journey, origin: Place, destination: Place, context: ModelContext) {
        let name = "\(origin.name) → \(destination.name)"
        let favorite = FavoriteJourney(name: name, origin: origin, destination: destination)
        context.insert(favorite)
        try? context.save()
        reload(from: context)

        WidgetBridge.saveFavorite(WidgetBridge.FavoriteSnapshot(
            originName: origin.name,
            destinationName: destination.name,
            nextDepartureLabel: DurationFormatter.format(date: journey.departureTime),
            durationLabel: DurationFormatter.format(seconds: journey.duration)
        ))
    }

    func delete(_ favorite: FavoriteJourney, context: ModelContext) {
        context.delete(favorite)
        try? context.save()
        reload(from: context)
    }
}
