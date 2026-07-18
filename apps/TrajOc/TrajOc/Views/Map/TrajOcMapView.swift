import MapKit
import SwiftUI

struct TrajOcMapView: UIViewRepresentable {
    let journey: Journey
    @Binding var selectedSection: JourneySection?

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.showsCompass = true
        map.showsScale = true
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations)

        for section in journey.sections {
            let coords: [CLLocationCoordinate2D]
            if let encoded = section.encodedPolyline {
                coords = PolylineDecoder.decode(encoded)
            } else {
                coords = [section.from.clCoordinate, section.to.clCoordinate]
            }
            guard coords.count >= 2 else { continue }

            let overlay = SectionPolyline(coordinates: coords, count: coords.count)
            overlay.mode = section.mode
            overlay.isSelected = selectedSection?.id == section.id
            map.addOverlay(overlay, level: .aboveRoads)
        }

        for section in journey.sections {
            map.addAnnotation(StopAnnotation(place: section.from, mode: section.mode))
        }
        if let last = journey.sections.last {
            let annotation = StopAnnotation(place: last.to, mode: .walk)
            annotation.isDestination = true
            map.addAnnotation(annotation)
        }

        if !map.annotations.isEmpty {
            map.showAnnotations(map.annotations, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        let parent: TrajOcMapView

        init(parent: TrajOcMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? SectionPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor(hex: polyline.mode.colorHex)
            renderer.lineWidth = polyline.isSelected ? 6 : 4
            renderer.lineDashPattern = polyline.mode == .walk ? [4, 6] : nil
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let stop = annotation as? StopAnnotation else { return nil }
            return StopAnnotationView(annotation: stop, reuseIdentifier: "stop")
        }
    }
}

/// Polyline avec métadonnées de mode de transport
final class SectionPolyline: MKPolyline {
    var mode: TransportMode = .walk
    var isSelected: Bool = false
}
