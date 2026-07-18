import Foundation
import UIKit

enum BeatBillLink {

    /// Ouvre BeatBill avec une facture pré-remplie (`beatbill://invoice?...`).
    @MainActor
    @discardableResult
    static func openInvoice(
        clientName: String,
        clientEmail: String = "",
        project: String,
        amount: Int? = nil,
        licenseLabel: String? = nil,
        dealRef: String? = nil,
        note: String? = nil
    ) -> Bool {
        var components = URLComponents()
        components.scheme = "beatbill"
        components.host = "invoice"
        var items: [URLQueryItem] = [
            URLQueryItem(name: "client", value: clientName),
            URLQueryItem(name: "project", value: project),
        ]
        if !clientEmail.isEmpty {
            items.append(URLQueryItem(name: "email", value: clientEmail))
        }
        if let amount {
            items.append(URLQueryItem(name: "amount", value: String(amount)))
        }
        if let licenseLabel, !licenseLabel.isEmpty {
            items.append(URLQueryItem(name: "license", value: licenseLabel))
        }
        if let dealRef, !dealRef.isEmpty {
            items.append(URLQueryItem(name: "dealRef", value: dealRef))
        }
        if let note, !note.isEmpty {
            items.append(URLQueryItem(name: "note", value: note))
        }
        components.queryItems = items

        guard let url = components.url else { return false }

        guard let beatBillURL = URL(string: "beatbill://") else { return false }
        guard UIApplication.shared.canOpenURL(beatBillURL) else { return false }

        UIApplication.shared.open(url)
        return true
    }

    @MainActor
    static func openInvoice(from contract: Contract) -> Bool {
        openInvoice(
            clientName: contract.artistName,
            clientEmail: contract.artistEmail,
            project: contract.displayBeatTitle,
            amount: contract.price,
            licenseLabel: contract.licenseType.title,
            dealRef: contract.reference,
            note: "Contrat BeatDeal \(contract.reference)"
        )
    }

    @MainActor
    static func openInvoice(from split: SplitSheet) -> Bool {
        let client = split.artist ?? split.collaborators.first?.name ?? ""
        guard !client.isEmpty else { return false }
        let email = split.collaborators.first(where: { $0.name == split.artist })?.email
            ?? split.collaborators.first?.email
            ?? ""
        return openInvoice(
            clientName: client,
            clientEmail: email,
            project: split.title,
            amount: split.agreedPrice,
            dealRef: split.ref,
            note: "Split \(split.ref)"
        )
    }
}
