import Foundation
import UIKit

struct BeatDealBackup: Codable {
    var version: Int = 1
    var exportedAt: Date = Date()
    var contracts: [Contract]
    var splits: [SplitSheet]
    var profile: ProducerProfile
    var templates: [LicenseTemplate]
    var beats: [CatalogBeat]
    var packs: [BeatPack]
}

@MainActor
enum BeatDealExportService {

    static func makeBackup() -> BeatDealBackup {
        BeatDealBackup(
            contracts: ContractStorage.shared.contracts,
            splits: SplitSheetStorage.shared.splits,
            profile: ProfileStorage.shared.profile,
            templates: TemplateStorage.shared.templates,
            beats: BeatCatalogStorage.shared.beats,
            packs: BeatCatalogStorage.shared.packs
        )
    }

    static func exportJSON() throws -> URL {
        let backup = makeBackup()
        let data = try JSONEncoder().encode(backup)
        let formatter = ISO8601DateFormatter()
        let stamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("BeatDeal-backup-\(stamp).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    static func importJSON(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let backup = try JSONDecoder().decode(BeatDealBackup.self, from: data)

        for contract in backup.contracts {
            ContractStorage.shared.save(contract)
        }
        for split in backup.splits {
            SplitSheetStorage.shared.save(split)
        }
        ProfileStorage.shared.profile = backup.profile
        ProfileStorage.shared.save()
        for template in backup.templates {
            TemplateStorage.shared.update(template)
        }
        for beat in backup.beats {
            BeatCatalogStorage.shared.save(beat)
        }
        for pack in backup.packs {
            BeatCatalogStorage.shared.save(pack)
        }
    }
}
