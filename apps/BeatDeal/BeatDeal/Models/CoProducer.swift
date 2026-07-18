import Foundation

struct CoProducer: Codable, Equatable {
    var name: String = ""
    var alias: String = ""
    var sharePercent: Int = 50

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && sharePercent > 0
            && sharePercent < 100
    }

    var mainProducerSharePercent: Int {
        max(0, 100 - sharePercent)
    }
}

struct LicensedBeatItem: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var bpm: Int?
    var musicalKey: String?
    var keyMode: String?

    var tonaliteLabel: String? {
        guard let musicalKey, let keyMode else { return nil }
        return "\(musicalKey) \(keyMode)"
    }

    static func from(_ beat: CatalogBeat) -> LicensedBeatItem {
        LicensedBeatItem(
            id: beat.id,
            title: beat.title,
            bpm: beat.bpm,
            musicalKey: beat.musicalKey,
            keyMode: beat.keyMode
        )
    }
}

struct DeliveryChecklist: Codable, Equatable {
    var pdfSent: Bool = false
    var wavSent: Bool = false
    var tagIncluded: Bool = false
    var paymentReceived: Bool = false
    var contractSignedReturned: Bool = false

    static let items: [(keyPath: WritableKeyPath<DeliveryChecklist, Bool>, label: String)] = [
        (\.pdfSent, "Contrat PDF envoyé"),
        (\.wavSent, "Beat WAV envoyé (WeTransfer / Google Drive)"),
        (\.tagIncluded, "Beat tag inclus"),
        (\.paymentReceived, "Paiement reçu"),
        (\.contractSignedReturned, "Contrat signé retourné")
    ]

    var completedCount: Int {
        Self.items.filter { self[keyPath: $0.keyPath] }.count
    }

    var isComplete: Bool {
        completedCount == Self.items.count
    }
}

extension Contract {

    var hasCoProducer: Bool {
        coProducerName.map { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? false
    }

    var isPackContract: Bool {
        !(packBeatItems?.isEmpty ?? true) && (packBeatItems?.count ?? 0) > 1
    }

    var displayBeatTitle: String {
        if isPackContract, let packTitle, !packTitle.isEmpty {
            return packTitle
        }
        return beatTitle
    }

    var creditLine: String {
        if hasCoProducer {
            let coAlias = coProducerAlias?.isEmpty == false ? coProducerAlias! : coProducerName ?? ""
            let mainShare = coProducerSharePercent.map { 100 - $0 } ?? 50
            let coShare = coProducerSharePercent ?? 50
            return "\(producerAlias) & \(coAlias) (\(mainShare)% / \(coShare)%)"
        }
        return producerAlias
    }
}
