import Foundation

/// Données reçues depuis SplitPad via deep link `beatdeal://split?...`
struct SplitPadImport: Equatable, Identifiable {
    var id: String { ref }
    let ref: String
    let title: String
    let artist: String?
    let coProducerName: String?
    let coProducerSharePercent: Int?

    init(ref: String, title: String, artist: String?, coProducerName: String?, coProducerSharePercent: Int?) {
        self.ref = ref
        self.title = title
        self.artist = artist
        self.coProducerName = coProducerName
        self.coProducerSharePercent = coProducerSharePercent
    }
}
