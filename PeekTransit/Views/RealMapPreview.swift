import SwiftUI
import MapKit

struct RealMapPreview: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    let direction: String

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isUserInteractionEnabled = false
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Bus Stop"
        mapView.addAnnotation(annotation)
        
        mapView.setRegion(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
            ),
            animated: false
        )
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RealMapPreview

        init(_ parent: RealMapPreview) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "BusStopPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }

            let markerImage: UIImage?
            switch parent.direction.lowercased() {
            case "southbound":
                markerImage = UIImage(named: "GreenBall")//?.withTintColor(.systemGreen, renderingMode: .alwaysTemplate)
            case "northbound":
                markerImage = UIImage(named: "OrangeBall")//?.withTintColor(.systemOrange, renderingMode: .alwaysTemplate)
            case "eastbound":
                markerImage = UIImage(named: "PinkBall")//?.withTintColor(.systemRed, renderingMode: .alwaysTemplate)
            case "westbound":
                markerImage = UIImage(named: "BlueBall")//?.withTintColor(.systemBlue, renderingMode: .alwaysTemplate)
            default:
                markerImage = UIImage(named: "DefaultBall")//?.withTintColor(.systemGray, renderingMode: .alwaysTemplate)
            }

            if let image = markerImage {
                annotationView?.image = image
                annotationView?.frame.size = CGSize(width: 32, height: 32)
            }

            return annotationView
        }
    }
}
