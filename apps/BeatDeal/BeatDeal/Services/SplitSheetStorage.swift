import Foundation

@MainActor
final class SplitSheetStorage: ObservableObject {
    static let shared = SplitSheetStorage()

    @Published private(set) var splits: [SplitSheet] = []

    private init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.storageKeySplits) else {
            splits = []
            return
        }
        do {
            splits = try JSONDecoder().decode([SplitSheet].self, from: data)
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            splits = []
        }
    }

    func save(_ split: SplitSheet) {
        if let index = splits.firstIndex(where: { $0.id == split.id }) {
            splits[index] = split
        } else {
            splits.insert(split, at: 0)
        }
        persist()
    }

    func delete(_ split: SplitSheet) {
        splits.removeAll { $0.id == split.id }
        persist()
    }

    func recent(limit: Int = 5) -> [SplitSheet] {
        Array(splits.prefix(limit))
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(splits)
            UserDefaults.standard.set(data, forKey: AppConstants.storageKeySplits)
        } catch {
            // silent
        }
    }
}
