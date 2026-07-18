import Foundation

enum RecettePortionsScaler {

    static func ingredientsAjustes(
        _ ingredients: [String],
        portionsBase: Int,
        portionsVoulues: Int
    ) -> [String] {
        guard portionsBase > 0, portionsVoulues > 0, portionsVoulues != portionsBase else {
            return ingredients
        }
        let ratio = Double(portionsVoulues) / Double(portionsBase)
        return ingredients.map { ajusterLigne($0, ratio: ratio) }
    }

    static func ajusterLigne(_ ligne: String, ratio: Double) -> String {
        guard ratio != 1 else { return ligne }

        if let regex = try? NSRegularExpression(pattern: #"^(\d+)\s*/\s*(\d+)(\s+)"#),
           regex.firstMatch(in: ligne, range: NSRange(ligne.startIndex..., in: ligne)) != nil {
            return remplacerFraction(regex, in: ligne, ratio: ratio)
        }

        var result = ligne

        if let regex = try? NSRegularExpression(pattern: #"(\d+)\s*-\s*(\d+)"#) {
            result = remplacerPlage(regex, in: result, ratio: ratio)
        }

        if let regex = try? NSRegularExpression(
            pattern: #"(\d+(?:[.,]\d+)?)\s*(g|kg|ml|cl|L)\b"#,
            options: .caseInsensitive
        ) {
            result = remplacerQuantites(regex, in: result, ratio: ratio)
        }

        if let regex = try? NSRegularExpression(
            pattern: #"(\d+(?:[.,]\d+)?)\s*(cs|cc|cuillères?(?:\s+à\s+(?:soupe|café))?)"#,
            options: .caseInsensitive
        ) {
            result = remplacerQuantites(regex, in: result, ratio: ratio)
        }

        if let regex = try? NSRegularExpression(pattern: #"d'(\d+(?:[.,]\d+)?)"#, options: .caseInsensitive) {
            result = remplacerQuantites(regex, in: result, ratio: ratio, groupe: 1)
        }

        if let regex = try? NSRegularExpression(pattern: #"^(\d+(?:[.,]\d+)?)(\s+)"#) {
            result = remplacerQuantites(regex, in: result, ratio: ratio, groupe: 1, prefixOnly: true)
        }

        return result
    }

    private static func remplacerFraction(
        _ regex: NSRegularExpression,
        in text: String,
        ratio: Double
    ) -> String {
        guard let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges >= 4,
              let numRange = Range(match.range(at: 1), in: text),
              let denRange = Range(match.range(at: 2), in: text),
              let num = Double(text[numRange]),
              let den = Double(text[denRange]), den != 0,
              let fullRange = Range(match.range, in: text),
              let suffix = Range(match.range(at: 3), in: text)
        else { return text }

        let valeur = (num / den) * ratio
        let formate = formaterQuantite(valeur)
        return text.replacingCharacters(in: fullRange, with: "\(formate)\(text[suffix])")
    }

    private static func remplacerPlage(
        _ regex: NSRegularExpression,
        in text: String,
        ratio: Double
    ) -> String {
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        guard !matches.isEmpty else { return text }

        var result = text
        for match in matches.reversed() {
            guard match.numberOfRanges >= 3,
                  let aRange = Range(match.range(at: 1), in: result),
                  let bRange = Range(match.range(at: 2), in: result),
                  let a = Double(result[aRange]),
                  let b = Double(result[bRange]),
                  let fullRange = Range(match.range, in: result)
            else { continue }

            let na = formaterQuantite(a * ratio)
            let nb = formaterQuantite(b * ratio)
            result.replaceSubrange(fullRange, with: "\(na)-\(nb)")
        }
        return result
    }

    private static func remplacerQuantites(
        _ regex: NSRegularExpression,
        in text: String,
        ratio: Double,
        groupe: Int = 1,
        prefixOnly: Bool = false
    ) -> String {
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, range: range)
        guard !matches.isEmpty else { return text }

        let mutable = NSMutableString(string: text)
        for match in matches.reversed() {
            if prefixOnly, match.range.location != 0 { continue }
            let qNSRange = match.range(at: groupe)
            guard qNSRange.location != NSNotFound else { continue }
            let extrait = mutable.substring(with: qNSRange)
            guard let valeur = parseNombre(extrait) else { continue }

            let nouveau = formaterQuantite(valeur * ratio)
            mutable.replaceCharacters(in: qNSRange, with: nouveau)
        }
        return mutable as String
    }

    private static func parseNombre(_ s: String) -> Double? {
        let normalise = s.replacingOccurrences(of: ",", with: ".")
        return Double(normalise)
    }

    static func formaterQuantite(_ valeur: Double) -> String {
        let arrondi = (valeur * 10).rounded() / 10
        if abs(arrondi - arrondi.rounded()) < 0.05 {
            return String(Int(arrondi.rounded()))
        }
        let texte = String(format: "%.1f", arrondi)
        return texte.replacingOccurrences(of: ".", with: ",")
    }
}
