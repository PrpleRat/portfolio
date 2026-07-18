import PDFKit
import UIKit

enum DoctorExportService {

    static func generatePDF(payload: SavedResultsPayload) -> Data? {
        let html = buildHTML(payload: payload)
        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        renderer.setValue(NSValue(cgRect: pageRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: pageRect.insetBy(dx: 40, dy: 40)), forKey: "printableRect")
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }

    private static func buildHTML(payload: SavedResultsPayload) -> String {
        let date = payload.date.formatted(date: .long, time: .omitted)
        let symptomes = payload.symptomeSelections.map {
            "\(CarenceDatabase.symptomeLabel(for: $0.symptomeId)) (\($0.frequence.label))"
        }.joined(separator: "<br>")

        let carences = payload.scores.prefix(6).map { score in
            let nom = CarenceDatabase.carence(for: score.carenceId)?.nom ?? score.carenceId
            return "<li><strong>\(escape(nom))</strong> — \(escape(score.niveau.label)) (score \(score.score))</li>"
        }.joined()

        let bilans = CarenceDatabase.bilansSuggeres(
            scores: payload.scores,
            regles: CarenceDatabase.shared.reglesCombinatoiresSpeciales.filter {
                payload.reglesDetectees.contains($0.id)
            }
        )
        let bilansHTML = bilans.isEmpty
            ? "<li>NFS, ferritine, 25-OH vitamine D, B12 selon symptômes</li>"
            : bilans.map { "<li>\(escape($0.label)) : \(escape($0.analyses.joined(separator: ", ")))</li>" }.joined()

        return """
        <!DOCTYPE html><html lang="fr"><head><meta charset="utf-8">
        <style>
        body { font-family: -apple-system, Helvetica, Arial; font-size: 11pt; color: #1c1c1e; line-height: 1.5; }
        h1 { color: #4A7C59; font-size: 16pt; }
        h2 { color: #4A7C59; font-size: 12pt; margin-top: 18px; }
        .meta { color: #666; font-size: 10pt; }
        .box { background: #f5f5f3; padding: 10px; border-radius: 8px; margin: 10px 0; }
        .footer { font-size: 9pt; color: #666; margin-top: 20px; border-top: 1px solid #ddd; padding-top: 10px; }
        </style></head><body>
        <h1>Fiche consultation — CarenceScan</h1>
        <p class="meta">Document d'orientation à remettre au médecin — \(escape(date))</p>
        <div class="box"><strong>Patient :</strong> bilan symptômes déclarés via application mobile (non diagnostique).</div>
        <h2>Symptômes déclarés</h2>
        <p>\(symptomes)</p>
        <h2>Carences nutritionnelles suspectées (orientation)</h2>
        <ul>\(carences)</ul>
        <h2>Bilans sanguins suggérés</h2>
        <ul>\(bilansHTML)</ul>
        <h2>Demandes au praticien</h2>
        <ul>
        <li>Validation des carences suspectées par analyses ciblées</li>
        <li>Conseil sur supplémentation éventuelle (notamment fer)</li>
        <li>Recherche d'autres causes si symptômes persistants</li>
        </ul>
        <p class="footer">\(escape(AppConstants.disclaimerPrincipal))</p>
        </body></html>
        """
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
