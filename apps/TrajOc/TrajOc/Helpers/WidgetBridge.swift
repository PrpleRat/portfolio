import Foundation

/// Pont App Group pour le widget
enum WidgetBridge {
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppConstants.appGroupID)
    }

    struct FavoriteSnapshot: Codable {
        let originName: String
        let destinationName: String
        let nextDepartureLabel: String
        let durationLabel: String
    }

    static func saveFavorite(_ snapshot: FavoriteSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: AppConstants.widgetFavoriteKey)
    }

    static func loadFavorite() -> FavoriteSnapshot? {
        guard let data = defaults?.data(forKey: AppConstants.widgetFavoriteKey),
              let snapshot = try? JSONDecoder().decode(FavoriteSnapshot.self, from: data) else {
            return nil
        }
        return snapshot
    }
}
