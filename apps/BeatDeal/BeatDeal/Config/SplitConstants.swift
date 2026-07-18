import Foundation

enum SplitConstants {

    static let defaultRole = "Producteur"

    /// Rôles alignés sur le bulletin SACEM + usages session rap.
    static let sacemRoles: [String] = [
        "Compositeur",
        "Auteur (paroles)",
        "Auteur-compositeur",
        "Arrangeur",
        "Adaptateur",
        "Éditeur musical",
        "Producteur",
        "Co-producteur",
        "Parolier",
        "Artiste",
        "Topliner",
        "Ingénieur son",
    ]

    static let genreCatalog: [(genre: String, subgenres: [String])] = [
        ("Rap FR", ["Trap", "Drill", "Boom bap", "Cloud", "Mélodique", "Jersey", "Afro trap", "Autre"]),
        ("Trap", ["Dark", "Melodic", "Plug", "Detroit", "Phonk", "Autre"]),
        ("Drill", ["UK", "NY", "Chicago", "FR", "Autre"]),
        ("Afro", ["Afrobeat", "Amapiano", "Afro trap", "Dancehall", "Autre"]),
        ("R&B", ["Trap soul", "Neo soul", "Alternative", "Slow jam", "Autre"]),
        ("Pop", ["Electro pop", "Urban pop", "Hyperpop", "Dance pop", "Autre"]),
        ("House", ["Deep", "Tech", "Afro house", "Latin", "Autre"]),
        ("Electronic", ["Ambient", "D&B", "Dubstep", "Lo-fi", "Autre"]),
        ("Rock / Alt", ["Indie", "Punk", "Metal", "Autre"]),
        ("Autre", ["—"]),
    ]

    struct RoleRecommendation {
        let master: Int
        let publishing: Int
    }

    static let roleRecommendations: [String: RoleRecommendation] = [
        "Producteur": .init(master: 50, publishing: 50),
        "Co-producteur": .init(master: 25, publishing: 25),
        "Compositeur": .init(master: 30, publishing: 50),
        "Auteur (paroles)": .init(master: 0, publishing: 50),
        "Auteur-compositeur": .init(master: 50, publishing: 66),
        "Parolier": .init(master: 0, publishing: 50),
        "Artiste": .init(master: 50, publishing: 0),
        "Arrangeur": .init(master: 10, publishing: 15),
        "Adaptateur": .init(master: 5, publishing: 10),
        "Éditeur musical": .init(master: 0, publishing: 25),
        "Topliner": .init(master: 20, publishing: 30),
        "Ingénieur son": .init(master: 5, publishing: 0),
    ]

    static func recommendedShares(for roles: [String]) -> RoleRecommendation {
        let recs = roles.compactMap { roleRecommendations[$0] }
        guard !recs.isEmpty else { return .init(master: 0, publishing: 0) }
        let master = recs.map(\.master).reduce(0, +) / recs.count
        let publishing = recs.map(\.publishing).reduce(0, +) / recs.count
        return .init(master: master, publishing: publishing)
    }

    enum Help {
        static let splitType = (
            title: "Type de split",
            text: """
            Master uniquement : tu répartis seulement les droits sur l'enregistrement (le fichier audio). C'est le cas le plus courant en session rap.

            Master + Publishing : tu répartis aussi les droits d'auteur — composition (beat, mélodie) et paroles. À utiliser quand chacun est crédité comme compositeur ou parolier auprès de la SACEM.
            """
        )

        static let masterShare = (
            title: "Part Master (%)",
            text: """
            Pourcentage de propriété sur l'enregistrement sonore fini — le fichier audio du morceau.

            Exemple : 50 % master = tu possèdes la moitié de l'enregistrement. En rap, c'est souvent le producteur et l'artiste qui se partagent le master.
            """
        )

        static let publishingShare = (
            title: "Part Publishing (%)",
            text: """
            Pourcentage sur les droits d'auteur : composition (instrumental, mélodie) et paroles.

            Géré séparément du master via ta PRO (SACEM en France). Un beatmaker peut avoir 30 % publishing et 50 % master, par exemple.
            """
        )

        static let sacem = (
            title: "SACEM / PRO",
            text: """
            Numéro d'adhérent SACEM (ou code IPI/CAE international) de la personne.

            Tu le trouves sur ta carte d'adhérent SACEM ou dans ton espace createurs-editeurs.sacem.fr. Si la personne n'est pas affiliée, laisse vide ou indique « Non affilié ».
            """
        )

        static let roles = (
            title: "Rôles SACEM",
            text: """
            Coche un ou plusieurs rôles comme sur le bulletin de déclaration SACEM : Compositeur, Auteur (paroles), Arrangeur, Adaptateur, Éditeur musical, etc.

            En session, un beatmaker est souvent « Compositeur » + « Producteur ». Un rappeur peut être « Auteur (paroles) » + « Artiste ».
            """
        )
    }
}
