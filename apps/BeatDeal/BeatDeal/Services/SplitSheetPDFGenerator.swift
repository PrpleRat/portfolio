import Foundation
import UIKit

enum SplitSheetPDFGenerator {

    static func generatePDF(for split: SplitSheet) throws -> URL {
        let html = SplitSheetHTMLBuilder.buildHTML(for: split)
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

        let fileName = "\(split.ref).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try (pdfData as Data).write(to: url, options: .atomic)
        return url
    }
}

enum SplitSheetHTMLBuilder {

    static func buildHTML(for split: SplitSheet) -> String {
        let showPublishing = split.splitType == .masterAndPublishing
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "fr_FR")
        dateFormatter.dateStyle = .long

        let rows = split.collaborators.map { c in
            let pub = showPublishing ? "<td style=\"text-align:center\">\(c.publishingShare)%</td>" : ""
            return """
            <tr>
              <td>\(escape(c.name))</td>
              <td>\(escape(c.roleLabel))</td>
              <td style="text-align:center">\(c.masterShare)%</td>
              \(pub)
            </tr>
            """
        }.joined()

        let pubHeader = showPublishing ? "<th style=\"text-align:center\">Publishing</th>" : ""
        let pubTotal = showPublishing ? "<td style=\"text-align:center\">\(split.totalPublishing)%</td>" : ""

        let sacem = split.collaborators
            .compactMap { c -> String? in
                guard let n = c.sacem, !n.isEmpty else { return nil }
                return "<div>\(escape(c.name)) — SACEM n° \(escape(n))</div>"
            }
            .joined()

        let clauses = ([split.clauses.joined(separator: "\n"), split.notes ?? ""]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n"))
            .ifEmpty("Aucune clause additionnelle.")

        let signatures = split.collaborators.map { c in
            """
            <div class="signature-line">
              <strong>\(escape(c.name))</strong>
              <span class="sig-field">_________________________</span>
              <span>Date : __________</span>
            </div>
            """
        }.joined()

        return """
        <!DOCTYPE html>
        <html lang="fr">
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: -apple-system, Helvetica, Arial, sans-serif; color: #111; font-size: 11pt; line-height: 1.5; }
            h1 { text-align: center; font-size: 16pt; margin-bottom: 20px; text-transform: uppercase; }
            h2 { font-size: 10pt; text-transform: uppercase; color: #444; margin-bottom: 8px; }
            .section { margin-bottom: 16px; padding-bottom: 12px; border-bottom: 1px solid #ccc; }
            table { width: 100%; border-collapse: collapse; margin-top: 8px; font-size: 10pt; }
            th, td { border: 1px solid #ddd; padding: 6px 8px; }
            th { background: #f0f0f0; }
            .total-row td { font-weight: bold; background: #fafafa; }
            .clauses { white-space: pre-wrap; }
            .signature-line { margin-bottom: 24px; }
            .sig-field { border-bottom: 1px solid #333; padding: 0 40px; margin: 0 8px; }
            .footer { margin-top: 24px; text-align: center; font-size: 9pt; color: #666; }
          </style>
        </head>
        <body>
          <h1>Split Sheet — Accord de propriété</h1>
          <div class="section">
            <h2>Morceau</h2>
            <p><strong>MORCEAU :</strong> "\(escape(split.title))"</p>
            \(split.artist.map { "<p><strong>Artiste :</strong> \(escape($0))</p>" } ?? "")
            \(split.genreLabel.map { "<p><strong>Genre :</strong> \(escape($0))</p>" } ?? "")
            <p><strong>Date :</strong> \(dateFormatter.string(from: split.createdAt))</p>
            <p><strong>ISRC :</strong> \(split.isrc?.isEmpty == false ? escape(split.isrc!) : "À obtenir")</p>
            <p><strong>Référence :</strong> \(escape(split.ref))</p>
          </div>
          <div class="section">
            <h2>Répartition des droits</h2>
            <table>
              <thead>
                <tr>
                  <th>Collaborateur</th>
                  <th>Rôle</th>
                  <th style="text-align:center">Master</th>
                  \(pubHeader)
                </tr>
              </thead>
              <tbody>
                \(rows)
                <tr class="total-row">
                  <td colspan="2"><strong>TOTAL</strong></td>
                  <td style="text-align:center">\(split.totalMaster)%</td>
                  \(pubTotal)
                </tr>
              </tbody>
            </table>
          </div>
          \(sacem.isEmpty ? "" : "<div class=\"section\"><h2>PRO / SACEM</h2>\(sacem)</div>")
          <div class="section">
            <h2>Clauses</h2>
            <p class="clauses">\(escape(clauses))</p>
          </div>
          <div class="section">
            <h2>Signatures</h2>
            \(signatures)
          </div>
          <p class="footer">Généré via BeatDeal · Ref : \(escape(split.ref))</p>
        </body>
        </html>
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

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
