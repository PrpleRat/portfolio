import Foundation
import UIKit

enum PDFGenerator {

    static func generatePDF(for contract: Contract) throws -> URL {
        let html = ContractHTMLBuilder.buildHTML(for: contract)
        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let printableRect = pageRect.insetBy(dx: 40, dy: 48)
        renderer.setValue(NSValue(cgRect: pageRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
        for pageIndex in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: pageIndex, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()

        let fileName = "BeatDeal-\(contract.reference).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try (pdfData as Data).write(to: url, options: .atomic)
        return url
    }
}

enum ContractHTMLBuilder {

    static func buildHTML(for contract: Contract) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "fr_FR")
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        let dateStr = dateFormatter.string(from: contract.createdAt)

        let rightsHTML = ContractRights.allLabels.map { item in
            let granted = contract.rights[keyPath: item.keyPath]
            let mark = granted ? "✓" : "✗"
            let style = granted ? "granted" : "denied"
            return "<li class=\"\(style)\">\(mark) \(escape(item.label))</li>"
        }.joined()

        let streamsLabel: String
        if contract.licenseType.isExclusive {
            streamsLabel = "Illimités"
        } else {
            streamsLabel = "\(contract.maxStreams.formatted()) streams maximum"
        }

        let paymentRef = contract.paymentReference.isEmpty ? "—" : escape(contract.paymentReference)
        let clauses = contract.additionalClauses.isEmpty ? "Aucune" : escape(contract.additionalClauses)

        return """
        <!DOCTYPE html>
        <html lang="fr">
        <head>
          <meta charset="utf-8">
          <style>
            body {
              font-family: Georgia, 'Times New Roman', serif;
              color: #111;
              font-size: 11pt;
              line-height: 1.5;
            }
            h1 {
              text-align: center;
              font-size: 16pt;
              letter-spacing: 0.04em;
              margin-bottom: 8px;
            }
            hr {
              border: none;
              border-top: 1px solid #ccc;
              margin: 16px 0;
            }
            h2 {
              font-size: 11pt;
              text-transform: uppercase;
              letter-spacing: 0.06em;
              margin: 0 0 8px;
            }
            p, li { margin: 4px 0; }
            ul { padding-left: 18px; }
            table { width: 100%; border-collapse: collapse; margin: 8px 0; font-size: 10pt; }
            th, td { border: 1px solid #ddd; padding: 6px 8px; text-align: left; }
            th { background: #f5f5f5; }
            .granted { color: #111; }
            .denied { color: #888; }
            .footer {
              margin-top: 24px;
              font-size: 9pt;
              color: #666;
              text-align: center;
            }
            .signatures { margin-top: 24px; }
            .sign-line { margin: 18px 0; }
          </style>
        </head>
        <body>
          <h1>CONTRAT DE LICENCE DE BEAT</h1>
          <hr>

          <h2>Parties</h2>
          \(producersHTML(for: contract))

          <p><strong>Artiste (Licencié) :</strong><br>
          Nom : \(escape(contract.artistName))<br>
          Email : \(escape(contract.artistEmail))</p>

          <hr>

          <h2>Objet du contrat</h2>
          \(beatsObjectHTML(for: contract, dateStr: dateStr))

          <hr>

          <h2>Conditions financières</h2>
          <p>
            Prix de la licence : \(contract.price) \(escape(contract.currency.rawValue))<br>
            Mode de paiement : \(escape(contract.paymentMethod.rawValue))<br>
            Référence paiement : \(paymentRef)
          </p>

          <hr>

          <h2>Droits accordés</h2>
          <ul>\(rightsHTML)</ul>

          <hr>

          <h2>Limites d'utilisation</h2>
          <ul>
            <li>Streams autorisés : \(escape(streamsLabel))</li>
            <li>Distribution : \(escape(contract.licenseType.distributionLabel))</li>
            <li>Formats fournis : \(escape(contract.licenseType.formats))</li>
            <li>Durée de la licence : perpétuelle</li>
          </ul>

          <hr>

          <h2>Crédits obligatoires</h2>
          <p>
            L'Artiste s'engage à créditer le(s) Producteur(s) comme suit sur toutes les publications :<br>
            "<strong>\(escape(contract.creditLine))</strong>"
          </p>
          \(splitSheetNote(for: contract))

          <hr>

          <h2>Clauses additionnelles</h2>
          <p>\(clauses)</p>

          <hr>

          <h2>Signatures</h2>
          <div class="signatures">
            \(signaturesHTML(for: contract))
          </div>

          <hr>
          <p class="footer">
            Contrat généré via BeatDeal · beatdeal.app<br>
            Référence : \(escape(contract.reference))
          </p>
        </body>
        </html>
        """
    }

    private static func producersHTML(for contract: Contract) -> String {
        if contract.hasCoProducer {
            let coShare = contract.coProducerSharePercent ?? 50
            let mainShare = 100 - coShare
            let coName = contract.coProducerName ?? ""
            let coAlias = contract.coProducerAlias?.isEmpty == false ? contract.coProducerAlias! : coName
            return """
            <p><strong>Producteur principal (Concédant) — \(mainShare) % :</strong><br>
            Nom : \(escape(contract.producerName))<br>
            Alias : \(escape(contract.producerAlias))<br>
            Email : \(escape(contract.producerEmail))<br>
            Pays : \(escape(contract.producerCountry))</p>

            <p><strong>Co-producteur (Concédant) — \(coShare) % :</strong><br>
            Nom : \(escape(coName))<br>
            Alias : \(escape(coAlias))</p>
            """
        }

        return """
        <p><strong>Producteur (Concédant) :</strong><br>
        Nom : \(escape(contract.producerName))<br>
        Alias : \(escape(contract.producerAlias))<br>
        Email : \(escape(contract.producerEmail))<br>
        Pays : \(escape(contract.producerCountry))</p>
        """
    }

    private static func beatsObjectHTML(for contract: Contract, dateStr: String) -> String {
        if let items = contract.packBeatItems, items.count > 1 {
            let rows = items.map { item -> String in
                let bpm = item.bpm.map { "\($0)" } ?? "—"
                let key = item.tonaliteLabel.map(escape) ?? "—"
                return "<tr><td>\(escape(item.title))</td><td>\(bpm)</td><td>\(key)</td></tr>"
            }.joined()
            return """
            <p>
              Pack licencié : "<strong>\(escape(contract.displayBeatTitle))</strong>"<br>
              Type de licence : \(escape(contract.licenseType.title))<br>
              Date du contrat : \(escape(dateStr))<br>
              Référence : \(escape(contract.reference))
            </p>
            <table>
              <thead><tr><th>Beat</th><th>BPM</th><th>Tonalité</th></tr></thead>
              <tbody>\(rows)</tbody>
            </table>
            <p><em>Chaque beat du pack bénéficie des mêmes droits et limites définis ci-dessous.</em></p>
            """
        }

        let bpmLine: String
        if let bpm = contract.bpm {
            bpmLine = "BPM : \(bpm)"
        } else {
            bpmLine = "BPM : —"
        }

        let keyLine: String
        if let tonalite = contract.tonaliteLabel {
            keyLine = "Tonalité : \(escape(tonalite))"
        } else {
            keyLine = "Tonalité : —"
        }

        return """
        <p>
          Beat licencié : "\(escape(contract.beatTitle))"<br>
          \(escape(bpmLine)) | \(keyLine)<br>
          Type de licence : \(escape(contract.licenseType.title))<br>
          Date du contrat : \(escape(dateStr))<br>
          Référence : \(escape(contract.reference))
        </p>
        """
    }

    private static func splitSheetNote(for contract: Contract) -> String {
        guard contract.hasCoProducer else { return "" }
        return """
        <p><em>Répartition des royalties conforme au split sheet convenu entre les producteurs (\(escape(contract.creditLine))).</em></p>
        """
    }

    private static func signaturesHTML(for contract: Contract) -> String {
        if contract.hasCoProducer {
            let coName = contract.coProducerName ?? "Co-producteur"
            return """
            <p class="sign-line">Producteur principal : _______________________ &nbsp;&nbsp; Date : __________</p>
            <p class="sign-line">Co-producteur (\(escape(coName))) : _______________________ &nbsp;&nbsp; Date : __________</p>
            <p class="sign-line">Artiste : &nbsp;&nbsp;_______________________ &nbsp;&nbsp; Date : __________</p>
            """
        }
        return """
        <p class="sign-line">Producteur : _______________________ &nbsp;&nbsp; Date : __________</p>
        <p class="sign-line">Artiste : &nbsp;&nbsp;_______________________ &nbsp;&nbsp; Date : __________</p>
        """
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
