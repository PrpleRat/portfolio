import Foundation

/// Actor centralisé pour toutes les requêtes réseau
/// Gère : timeout, retry, cache, User-Agent
actor NetworkManager {

    static let shared = NetworkManager()

    private let session: URLSession
    private var cache: [String: (data: Data, timestamp: Date)] = [:]
    private var lastNominatimRequest: Date?

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConstants.networkTimeout
        config.timeoutIntervalForResource = AppConstants.networkTimeout * 2
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    /// Effectue une requête GET avec retry automatique et cache optionnel
    func get(
        url: URL,
        headers: [String: String] = [:],
        cacheDuration: Double? = nil,
        rateLimitNominatim: Bool = false
    ) async throws -> Data {
        if rateLimitNominatim {
            await enforceNominatimRateLimit()
        }

        let cacheKey = url.absoluteString

        if let duration = cacheDuration,
           let cached = cache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < duration {
            return cached.data
        }

        var request = URLRequest(url: url)
        request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        var lastError: Error?
        for attempt in 1...(AppConstants.maxRetries + 1) {
            do {
                let (data, response) = try await session.data(for: request)

                guard let http = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                guard (200...299).contains(http.statusCode) else {
                    let message = Self.parseErrorMessage(from: data)
                    throw NetworkError.httpError(statusCode: http.statusCode, message: message)
                }

                if cacheDuration != nil {
                    cache[cacheKey] = (data: data, timestamp: Date())
                }

                return data
            } catch {
                lastError = error
                if attempt <= AppConstants.maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000)
                }
            }
        }

        throw lastError ?? NetworkError.unknown
    }

    /// POST (Overpass, etc.)
    func post(
        url: URL,
        body: String,
        contentType: String = "application/x-www-form-urlencoded",
        formField: String? = nil,
        headers: [String: String] = [:],
        cacheDuration: Double? = nil
    ) async throws -> Data {
        let payload: Data
        if let formField {
            let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? body
            payload = Data("\(formField)=\(encoded)".utf8)
        } else {
            payload = Data(body.utf8)
        }

        let cacheKey = "POST:\(url.absoluteString):\(body.hashValue)"

        if let duration = cacheDuration,
           let cached = cache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < duration {
            return cached.data
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = payload
        request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NetworkError.invalidResponse
        }

        if cacheDuration != nil {
            cache[cacheKey] = (data: data, timestamp: Date())
        }
        return data
    }

    private static func parseErrorMessage(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let body = try? decoder.decode(APIErrorBody.self, from: data) {
            return body.bestMessage
        }
        if let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty, text.count < 300 {
            return text
        }
        return nil
    }

    /// Respecte la limite Nominatim : 1 requête/seconde max
    private func enforceNominatimRateLimit() async {
        if let last = lastNominatimRequest {
            let elapsed = Date().timeIntervalSince(last)
            if elapsed < AppConstants.nominatimMinInterval {
                let wait = AppConstants.nominatimMinInterval - elapsed
                try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            }
        }
        lastNominatimRequest = Date()
    }

    func clearCache() {
        cache.removeAll()
    }

    private struct APIErrorBody: Decodable {
        let error: ErrorDetail?
        let message: String?

        struct ErrorDetail: Decodable {
            let id: String?
            let message: String?
        }

        var bestMessage: String? {
            if let msg = error?.message, !msg.isEmpty { return msg }
            if let msg = message, !msg.isEmpty { return msg }
            return nil
        }
    }
}

enum NetworkError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, message: String? = nil)
    case noData
    case decodingError(underlying: Error)
    case noConnection
    case unknown

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "Pas de connexion internet. Vérifie ta connexion et réessaie."
        case .httpError(let code, let message) where code == 401:
            return message ?? "Clé API invalide. Vérifie tes clés dans GitHub Secrets."
        case .httpError(let code, let message) where code == 404:
            return humanize(message) ?? "Données introuvables pour cette recherche. Essaie une gare ou une adresse plus précise."
        case .httpError(let code, let message) where code == 429:
            return message ?? "Trop de requêtes. Attends quelques secondes."
        case .httpError(_, let message) where message != nil:
            return humanize(message)
        case .httpError(let code, _) where code >= 500:
            return "Le service est temporairement indisponible."
        default:
            return "Une erreur réseau s'est produite. Réessaie."
        }
    }

    private func humanize(_ message: String?) -> String? {
        guard let message, !message.isEmpty else { return nil }
        let lower = message.lowercased()
        if lower.contains("unable to find") || lower.contains("not found") || lower.contains("no journey") {
            return "Aucun trajet trouvé pour ces lieux. Essaie une gare à proximité."
        }
        if lower.contains("data not found") || lower.contains("données introuvables") {
            return "Données introuvables pour cette recherche. Essaie une gare ou une adresse plus précise."
        }
        return message
    }
}
