import MapKit

/// Annotation personnalisée pour un arrêt
final class StopAnnotation: NSObject, MKAnnotation {
    let place: Place
    let mode: TransportMode
    var isDestination = false

    var coordinate: CLLocationCoordinate2D { place.clCoordinate }
    var title: String? { place.name }

    init(place: Place, mode: TransportMode) {
        self.place = place
        self.mode = mode
    }
}

final class StopAnnotationView: MKMarkerAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    private func configure() {
        guard let stop = annotation as? StopAnnotation else { return }
        markerTintColor = UIColor(hex: stop.mode.colorHex)
        glyphImage = UIImage(systemName: stop.isDestination ? "flag.checkered" : stop.mode.sfSymbol)
    }
}
