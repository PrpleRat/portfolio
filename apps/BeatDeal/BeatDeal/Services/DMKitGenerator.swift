import Foundation

enum DMKitGenerator {

    static func generate(contract: Contract, profile: ProducerProfile) -> String {
        let beatLabel = contract.displayBeatTitle
        let priceLine = "\(contract.price) \(contract.currency.rawValue)"
        let paymentBlock = paymentSection(profile: profile, contract: contract)
        let cta = profile.dmCallToAction.trimmingCharacters(in: .whitespacesAndNewlines)

        var lines = [
            "Salut \(contract.artistName) 👋",
            "",
            "Voici la licence pour « \(beatLabel) » :",
            "• Type : \(contract.licenseType.title)",
            "• Prix : \(priceLine)",
        ]

        if contract.isPackContract, let items = contract.packBeatItems {
            lines.append("• Beats inclus :")
            for item in items {
                var detail = "  – \(item.title)"
                if let bpm = item.bpm { detail += " (\(bpm) BPM)" }
                lines.append(detail)
            }
        }

        lines.append("")
        lines.append(paymentBlock)
        lines.append("")
        lines.append(cta.isEmpty ? "Dispo pour t'envoyer le contrat dès paiement reçu 🔥" : cta)
        lines.append("")
        lines.append("— \(profile.producerAlias.isEmpty ? profile.producerName : profile.producerAlias)")

        return lines.joined(separator: "\n")
    }

    private static func paymentSection(profile: ProducerProfile, contract: Contract) -> String {
        let link = profile.paymentLinkURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !link.isEmpty {
            return "💳 Paiement (\(contract.paymentMethod.rawValue)) : \(link)"
        }
        return "💳 Mode de paiement : \(contract.paymentMethod.rawValue)"
    }
}
