import Foundation

@MainActor
final class BeatCatalogStorage: ObservableObject {
    static let shared = BeatCatalogStorage()

    @Published private(set) var beats: [CatalogBeat] = []
    @Published private(set) var packs: [BeatPack] = []

    private init() {
        load()
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: AppConstants.storageKeyCatalog),
           let decoded = try? JSONDecoder().decode([CatalogBeat].self, from: data) {
            beats = decoded.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        } else {
            beats = []
        }

        if let data = UserDefaults.standard.data(forKey: AppConstants.storageKeyPacks),
           let decoded = try? JSONDecoder().decode([BeatPack].self, from: data) {
            packs = decoded.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        } else {
            packs = []
        }
    }

    func save(_ beat: CatalogBeat) {
        if let index = beats.firstIndex(where: { $0.id == beat.id }) {
            beats[index] = beat
        } else {
            beats.append(beat)
        }
        beats.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        persistBeats()
    }

    func delete(_ beat: CatalogBeat) {
        beats.removeAll { $0.id == beat.id }
        for index in packs.indices {
            packs[index].beatIds.removeAll { $0 == beat.id }
        }
        packs.removeAll { $0.beatIds.isEmpty }
        persistBeats()
        persistPacks()
    }

    func save(_ pack: BeatPack) {
        if let index = packs.firstIndex(where: { $0.id == pack.id }) {
            packs[index] = pack
        } else {
            packs.append(pack)
        }
        packs.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        persistPacks()
    }

    func delete(_ pack: BeatPack) {
        packs.removeAll { $0.id == pack.id }
        persistPacks()
    }

    func beat(id: String?) -> CatalogBeat? {
        guard let id else { return nil }
        return beats.first { $0.id == id }
    }

    func pack(id: String?) -> BeatPack? {
        guard let id else { return nil }
        return packs.first { $0.id == id }
    }

    func beats(for pack: BeatPack) -> [CatalogBeat] {
        pack.beats(from: beats)
    }

    private func persistBeats() {
        do {
            let data = try JSONEncoder().encode(beats)
            UserDefaults.standard.set(data, forKey: AppConstants.storageKeyCatalog)
        } catch {}
    }

    private func persistPacks() {
        do {
            let data = try JSONEncoder().encode(packs)
            UserDefaults.standard.set(data, forKey: AppConstants.storageKeyPacks)
        } catch {}
    }
}
