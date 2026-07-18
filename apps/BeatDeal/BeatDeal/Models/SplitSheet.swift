import Foundation

enum SplitSheetType: String, Codable, CaseIterable, Identifiable {
    case masterOnly = "master_only"
    case masterAndPublishing = "master_and_publishing"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .masterOnly: return "Master uniquement"
        case .masterAndPublishing: return "Master + Publishing"
        }
    }
}

struct SplitCollaborator: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var roles: [String]
    var masterShare: Int
    var publishingShare: Int
    var sacem: String?
    var email: String?
    var signed: Bool

    var roleLabel: String {
        roles.isEmpty ? "—" : roles.joined(separator: " · ")
    }

    enum CodingKeys: String, CodingKey {
        case id, name, role, roles, masterShare, publishingShare, sacem, email, signed
    }

    init(
        id: String,
        name: String,
        roles: [String],
        masterShare: Int,
        publishingShare: Int,
        sacem: String?,
        email: String?,
        signed: Bool
    ) {
        self.id = id
        self.name = name
        self.roles = roles
        self.masterShare = masterShare
        self.publishingShare = publishingShare
        self.sacem = sacem
        self.email = email
        self.signed = signed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        if let decodedRoles = try container.decodeIfPresent([String].self, forKey: .roles), !decodedRoles.isEmpty {
            roles = decodedRoles
        } else if let legacyRole = try container.decodeIfPresent(String.self, forKey: .role), !legacyRole.isEmpty {
            roles = [legacyRole]
        } else {
            roles = [SplitConstants.defaultRole]
        }
        masterShare = try container.decode(Int.self, forKey: .masterShare)
        publishingShare = try container.decode(Int.self, forKey: .publishingShare)
        sacem = try container.decodeIfPresent(String.self, forKey: .sacem)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        signed = try container.decodeIfPresent(Bool.self, forKey: .signed) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(roles, forKey: .roles)
        try container.encode(masterShare, forKey: .masterShare)
        try container.encode(publishingShare, forKey: .publishingShare)
        try container.encodeIfPresent(sacem, forKey: .sacem)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encode(signed, forKey: .signed)
    }

    static func empty(id: String = UUID().uuidString) -> SplitCollaborator {
        SplitCollaborator(
            id: id,
            name: "",
            roles: [SplitConstants.defaultRole],
            masterShare: 0,
            publishingShare: 0,
            sacem: nil,
            email: nil,
            signed: false
        )
    }
}

struct SplitSheet: Codable, Identifiable, Equatable {
    var id: String
    var ref: String
    var title: String
    var artist: String?
    var genre: String?
    var subgenre: String?
    var isrc: String?
    var createdAt: Date
    var splitType: SplitSheetType
    var collaborators: [SplitCollaborator]
    var clauses: [String]
    var notes: String?
    var agreedPrice: Int?
    var status: String

    var genreLabel: String? {
        switch (genre, subgenre) {
        case let (g?, s?) where !g.isEmpty && !s.isEmpty && s != "—":
            return "\(g) · \(s)"
        case let (g?, _) where !g.isEmpty:
            return g
        default:
            return nil
        }
    }

    var totalMaster: Int {
        collaborators.reduce(0) { $0 + $1.masterShare }
    }

    var totalPublishing: Int {
        collaborators.reduce(0) { $0 + $1.publishingShare }
    }

    var isValid: Bool {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard collaborators.contains(where: { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }) else { return false }
        guard totalMaster == 100 else { return false }
        if splitType == .masterAndPublishing {
            return totalPublishing == 100
        }
        return true
    }

    static func generateRef() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let code = (0..<6).map { _ in chars.randomElement()! }
        return "SPLIT-\(String(code))"
    }
}

struct SplitSheetDraft: Equatable {
    var sheetId: String?
    var sheetRef: String?
    var title: String = ""
    var artist: String = ""
    var genre: String = ""
    var subgenre: String = ""
    var isrc: String = ""
    var createdAt: Date = Date()
    var splitType: SplitSheetType = .masterAndPublishing
    var collaborators: [SplitCollaborator] = [SplitCollaborator.empty()]
    var clauses: [String] = [
        "Ce split s'applique à toutes les versions du morceau",
        "En cas de sample non clearé, ce split est suspendu",
    ]
    var notes: String = ""
    var agreedPrice: String = ""
    var status: String = "pending"

    var isEditing: Bool { sheetId != nil }

    mutating func applyProfile(_ profile: ProducerProfile) {
        guard let first = collaborators.indices.first else { return }
        if collaborators[first].name.isEmpty {
            collaborators[first].name = profile.producerAlias.isEmpty ? profile.producerName : profile.producerAlias
            collaborators[first].email = profile.email
        }
    }

    mutating func applyImport(_ importData: SplitPadImport) {
        title = importData.title
        if let a = importData.artist, !a.isEmpty {
            artist = a
        }
        if let coName = importData.coProducerName, let share = importData.coProducerSharePercent {
            if collaborators.count < 2 {
                collaborators.append(SplitCollaborator.empty())
            }
            collaborators[1].name = coName
            collaborators[1].roles = ["Co-producteur"]
            collaborators[1].masterShare = share
        }
    }

    mutating func applySheet(_ sheet: SplitSheet) {
        sheetId = sheet.id
        sheetRef = sheet.ref
        title = sheet.title
        artist = sheet.artist ?? ""
        genre = sheet.genre ?? ""
        subgenre = sheet.subgenre ?? ""
        isrc = sheet.isrc ?? ""
        createdAt = sheet.createdAt
        splitType = sheet.splitType
        collaborators = sheet.collaborators
        clauses = sheet.clauses
        notes = sheet.notes ?? ""
        if let price = sheet.agreedPrice {
            agreedPrice = String(price)
        }
        status = sheet.status
    }

    func buildSheet() -> SplitSheet? {
        let valid = collaborators.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty, !valid.isEmpty else { return nil }

        return SplitSheet(
            id: sheetId ?? UUID().uuidString,
            ref: sheetRef ?? SplitSheet.generateRef(),
            title: title.trimmingCharacters(in: .whitespaces),
            artist: artist.isEmpty ? nil : artist,
            genre: genre.isEmpty ? nil : genre,
            subgenre: subgenre.isEmpty || subgenre == "—" ? nil : subgenre,
            isrc: isrc.isEmpty ? nil : isrc,
            createdAt: createdAt,
            splitType: splitType,
            collaborators: valid,
            clauses: clauses,
            notes: notes.isEmpty ? nil : notes,
            agreedPrice: Int(agreedPrice.trimmingCharacters(in: .whitespaces)),
            status: status
        )
    }
}
