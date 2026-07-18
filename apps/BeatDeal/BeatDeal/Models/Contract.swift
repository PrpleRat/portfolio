import Foundation

struct ProducerProfile: Codable, Equatable {
    var producerName: String = ""
    var producerAlias: String = ""
    var email: String = ""
    var siret: String = ""
    var country: String = "France"
    var currency: Currency = .eur
    var paymentLinkURL: String = ""
    var dmCallToAction: String = "Dispo pour t'envoyer le contrat dès paiement reçu 🔥"
}

struct Contract: Codable, Identifiable, Equatable {
    var id: String
    var createdAt: Date
    var licenseType: LicenseType
    var artistName: String
    var artistEmail: String
    var beatTitle: String
    var bpm: Int?
    var musicalKey: String?
    var keyMode: String?
    var producerName: String
    var producerAlias: String
    var producerEmail: String
    var producerCountry: String
    var price: Int
    var currency: Currency
    var paymentMethod: PaymentMethod
    var paymentReference: String
    var rights: ContractRights
    var maxStreams: Int
    var additionalClauses: String
    var pdfFileName: String?
    var streamsReported: Int?
    var expiresAt: Date?
    var catalogBeatId: String?
    var catalogPackId: String?
    var packTitle: String?
    var packBeatItems: [LicensedBeatItem]?
    var coProducerName: String?
    var coProducerAlias: String?
    var coProducerSharePercent: Int?
    var deliveryChecklist: DeliveryChecklist?

    var reference: String { "BEAT-\(id.prefix(8).uppercased())" }

    var tonaliteLabel: String? {
        guard let musicalKey, let keyMode else { return nil }
        return "\(musicalKey) \(keyMode)"
    }

    var licenseBadge: String { licenseType.title }
}

struct ContractDraft: Equatable {
    var contractId: String?
    var contractCreatedAt: Date?
    var step: Int = 1
    var licenseType: LicenseType?
    var artistName: String = ""
    var artistEmail: String = ""
    var beatTitle: String = ""
    var bpm: String = ""
    var selectedKey: MusicalKey?
    var selectedMode: KeyMode?
    var producerName: String = ""
    var producerAlias: String = ""
    var producerEmail: String = ""
    var producerCountry: String = "France"
    var price: String = ""
    var currency: Currency = .eur
    var paymentMethod: PaymentMethod = .paypal
    var paymentReference: String = ""
    var rights: ContractRights = LicenseType.mp3Lease.defaultRights
    var maxStreams: Int = LicenseType.mp3Lease.defaultMaxStreams
    var additionalClauses: String = ""
    var catalogBeatId: String?
    var catalogPackId: String?
    var packTitle: String?
    var packBeatItems: [LicensedBeatItem]?
    var coProducer: CoProducer = CoProducer()
    var enableCoProducer: Bool = false

    mutating func applyContract(_ contract: Contract) {
        contractId = contract.id
        contractCreatedAt = contract.createdAt
        step = 1
        licenseType = contract.licenseType
        artistName = contract.artistName
        artistEmail = contract.artistEmail
        beatTitle = contract.beatTitle
        bpm = contract.bpm.map(String.init) ?? ""
        if let key = contract.musicalKey {
            selectedKey = MusicalKey.allCases.first { $0.label == key }
        }
        if let mode = contract.keyMode {
            selectedMode = KeyMode.allCases.first { $0.rawValue == mode }
        }
        producerName = contract.producerName
        producerAlias = contract.producerAlias
        producerEmail = contract.producerEmail
        producerCountry = contract.producerCountry
        price = String(contract.price)
        currency = contract.currency
        paymentMethod = contract.paymentMethod
        paymentReference = contract.paymentReference
        rights = contract.rights
        maxStreams = contract.maxStreams
        additionalClauses = contract.additionalClauses
        catalogBeatId = contract.catalogBeatId
        catalogPackId = contract.catalogPackId
        packTitle = contract.packTitle
        packBeatItems = contract.packBeatItems
        if let coName = contract.coProducerName, !coName.isEmpty {
            enableCoProducer = true
            coProducer.name = coName
            coProducer.alias = contract.coProducerAlias ?? ""
            coProducer.sharePercent = contract.coProducerSharePercent ?? 50
        }
    }

    @MainActor
    mutating func applyUpgrade(from contract: Contract, to license: LicenseType, template: LicenseTemplate, catalog: BeatCatalogStorage) {
        applyContract(contract)
        contractId = nil
        contractCreatedAt = nil
        licenseType = license
        applyTemplate(template)
        if let beatId = contract.catalogBeatId, let beat = catalog.beat(id: beatId) {
            applyCatalogBeat(beat, licenseType: license)
        } else if let packId = contract.catalogPackId, let pack = catalog.pack(id: packId) {
            let beats = catalog.beats(for: pack)
            applyCatalogPack(pack, beats: beats, licenseType: license)
        }
        let upgradeNote = "Upgrade depuis \(contract.licenseType.title) (ref \(contract.reference))."
        if additionalClauses.isEmpty {
            additionalClauses = upgradeNote
        } else if !additionalClauses.contains(contract.reference) {
            additionalClauses += "\n\n\(upgradeNote)"
        }
        step = 2
    }

    mutating func applyProfile(_ profile: ProducerProfile) {
        producerName = profile.producerName
        producerAlias = profile.producerAlias
        producerEmail = profile.email
        producerCountry = profile.country
        currency = profile.currency
    }

    mutating func applyTemplate(_ template: LicenseTemplate) {
        price = String(template.defaultPrice)
        rights = template.defaultRights
        maxStreams = template.maxStreams
        if additionalClauses.isEmpty {
            additionalClauses = template.defaultClause
        }
    }

    mutating func applyCatalogBeat(_ beat: CatalogBeat, licenseType: LicenseType?) {
        catalogBeatId = beat.id
        catalogPackId = nil
        packTitle = nil
        packBeatItems = nil
        beatTitle = beat.title
        if let bpm = beat.bpm { self.bpm = String(bpm) }
        if let key = beat.musicalKey, let mode = beat.keyMode {
            selectedKey = MusicalKey.allCases.first { $0.label == key }
            selectedMode = KeyMode.allCases.first { $0.rawValue == mode }
        }
        if let licenseType {
            price = String(beat.prices.price(for: licenseType))
        }
        if let co = beat.coProducer, co.isValid {
            enableCoProducer = true
            coProducer = co
        }
    }

    mutating func applyCatalogPack(_ pack: BeatPack, beats: [CatalogBeat], licenseType: LicenseType?) {
        catalogPackId = pack.id
        catalogBeatId = nil
        packTitle = pack.title
        beatTitle = pack.title
        packBeatItems = beats.map { LicensedBeatItem.from($0) }
        bpm = ""
        selectedKey = nil
        selectedMode = nil
        if let licenseType {
            price = String(pack.prices.price(for: licenseType))
        }
    }

    func buildContract(id: String? = nil) -> Contract? {
        guard let licenseType else { return nil }
        guard let priceInt = Int(price.trimmingCharacters(in: .whitespaces)) else { return nil }

        return Contract(
            id: id ?? contractId ?? UUID().uuidString,
            createdAt: contractCreatedAt ?? Date(),
            licenseType: licenseType,
            artistName: artistName.trimmingCharacters(in: .whitespaces),
            artistEmail: artistEmail.trimmingCharacters(in: .whitespaces),
            beatTitle: beatTitle.trimmingCharacters(in: .whitespaces),
            bpm: Int(bpm.trimmingCharacters(in: .whitespaces)),
            musicalKey: selectedKey?.label,
            keyMode: selectedMode?.rawValue,
            producerName: producerName.trimmingCharacters(in: .whitespaces),
            producerAlias: producerAlias.trimmingCharacters(in: .whitespaces),
            producerEmail: producerEmail.trimmingCharacters(in: .whitespaces),
            producerCountry: producerCountry.trimmingCharacters(in: .whitespaces),
            price: priceInt,
            currency: currency,
            paymentMethod: paymentMethod,
            paymentReference: paymentReference.trimmingCharacters(in: .whitespaces),
            rights: rights,
            maxStreams: maxStreams,
            additionalClauses: additionalClauses.trimmingCharacters(in: .whitespacesAndNewlines),
            pdfFileName: nil,
            streamsReported: 0,
            expiresAt: Contract.defaultExpiresAt(from: Date(), licenseType: licenseType),
            catalogBeatId: catalogBeatId,
            catalogPackId: catalogPackId,
            packTitle: packTitle,
            packBeatItems: packBeatItems,
            coProducerName: enableCoProducer ? coProducer.name.trimmingCharacters(in: .whitespaces) : nil,
            coProducerAlias: enableCoProducer ? coProducer.alias.trimmingCharacters(in: .whitespaces) : nil,
            coProducerSharePercent: enableCoProducer ? coProducer.sharePercent : nil,
            deliveryChecklist: DeliveryChecklist()
        )
    }

    var canProceedStep1: Bool { licenseType != nil }

    var canProceedStep2: Bool {
        let hasBeatInfo = !beatTitle.trimmingCharacters(in: .whitespaces).isEmpty
            || !(packBeatItems?.isEmpty ?? true)
        return !artistName.trimmingCharacters(in: .whitespaces).isEmpty
            && !artistEmail.trimmingCharacters(in: .whitespaces).isEmpty
            && artistEmail.contains("@")
            && hasBeatInfo
            && !producerName.trimmingCharacters(in: .whitespaces).isEmpty
            && !producerEmail.trimmingCharacters(in: .whitespaces).isEmpty
            && Int(price.trimmingCharacters(in: .whitespaces)) != nil
            && coProducerIsValid
    }

    private var coProducerIsValid: Bool {
        if !enableCoProducer { return true }
        return coProducer.isValid
    }
}
