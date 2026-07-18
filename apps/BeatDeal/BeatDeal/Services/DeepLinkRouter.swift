import Foundation

@MainActor
final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()

    @Published private(set) var pendingSplitImport: SplitPadImport?
    @Published var showImportChoice = false

    private init() {}

    func handle(url: URL) {
        guard url.scheme?.lowercased() == "beatdeal" else { return }
        guard url.host?.lowercased() == "split" else { return }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        let query = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item -> (String, String)? in
                guard let value = item.value else { return nil }
                return (item.name, value)
            }
        )

        let title = query["title"]?.removingPercentEncoding?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !title.isEmpty else { return }

        let ref = query["ref"]?.removingPercentEncoding ?? ""
        let artist = query["artist"]?.removingPercentEncoding?.trimmingCharacters(in: .whitespacesAndNewlines)
        let coProducer = query["coProducer"]?.removingPercentEncoding?.trimmingCharacters(in: .whitespacesAndNewlines)
        let coShare = query["coShare"].flatMap { Int($0) }

        pendingSplitImport = SplitPadImport(
            ref: ref,
            title: title,
            artist: artist?.isEmpty == true ? nil : artist,
            coProducerName: coProducer?.isEmpty == true ? nil : coProducer,
            coProducerSharePercent: coShare
        )
    }

    func consumePendingImport() -> SplitPadImport? {
        let value = pendingSplitImport
        pendingSplitImport = nil
        return value
    }
}
