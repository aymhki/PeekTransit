
import MapKit
import Foundation
import SwiftUI

struct MapViewRepresentable: UIViewRepresentable {
    let stops: [Stop]
    let userLocation: CLLocation?
    let onAnnotationTapped: (MKAnnotation) -> Void
    @Binding var centerMapOnUser: Bool
    let highlightedStopNumber: Int?
    private let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    
    
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        context.coordinator.mapView = mapView
        Coordinator.shared = context.coordinator
        mapView.showsUserLocation = true
        
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        
        if let location = userLocation {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                span: defaultSpan
            )
            mapView.setRegion(region, animated: true)
            mapView.setCenter(location.coordinate, animated: true)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        updateAnnotations(on: mapView)
        updateOverlay(on: mapView)
        
        if centerMapOnUser, let location = userLocation {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                span: defaultSpan
            )
            
            mapView.setRegion(region, animated: true)
            DispatchQueue.main.async {
                centerMapOnUser = false
            }
        }
    }
    
    private func updateAnnotations(on mapView: MKMapView) {
        let group = DispatchGroup()

        let existingAnnotations = Dictionary(
            mapView.annotations.compactMap { annotation -> (Int, MKAnnotation)? in
                guard let pointAnnotation = annotation as? CustomStopAnnotation else { return nil }
                return (pointAnnotation.stopNumber, annotation)
            },
            uniquingKeysWith: { (first, _) in first }
        )

        var updatedStopNumbers = Set<Int>()
        var newAnnotationsToAdd: [MKAnnotation] = []

        for stop in stops {
            // group.enter()

            updatedStopNumbers.insert(stop.number)
            let coordinate = CLLocationCoordinate2D(latitude: stop.centre.geographic.latitude, longitude: stop.centre.geographic.longitude)

            if let existingAnnotation = existingAnnotations[stop.number] as? CustomStopAnnotation {
                existingAnnotation.coordinate = coordinate
                existingAnnotation.title = stop.name
                existingAnnotation.subtitle = formatSubtitle(for: stop)
                existingAnnotation.stopData = stop
                // group.leave()
            } else {
                let annotation = CustomStopAnnotation(stopNumber: stop.number, stopData: stop)
                annotation.coordinate = coordinate
                annotation.title = stop.name
                annotation.subtitle = formatSubtitle(for: stop)
                newAnnotationsToAdd.append(annotation)
                // group.leave()
            }
        }

        let annotationsToRemove = mapView.annotations.compactMap { $0 as? CustomStopAnnotation }
            .filter { !updatedStopNumbers.contains($0.stopNumber) }

        if !annotationsToRemove.isEmpty {
            mapView.removeAnnotations(annotationsToRemove)
        }

        if !newAnnotationsToAdd.isEmpty {
            mapView.addAnnotations(newAnnotationsToAdd)
        }

        // group.notify(queue: .main) {} 
    }
    
    private func updateOverlay(on mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays)
        if let userLocation = userLocation {
            let circle = MKCircle(center: userLocation.coordinate, radius: getStopsDistanceRadius())
            mapView.addOverlay(circle)
        }
    }
    
    private func formatSubtitle(for stop:Stop) -> String {
        var subtitle = "#\(stop.number)"
        
        if !stop.variants.isEmpty {
            var variantsString = ""
            let uniqueRoutes = Set(stop.variants.compactMap { variant -> String? in
                return variant.key.split(separator: "-")[0].description
            })
            variantsString = uniqueRoutes.sorted().joined(separator: ", ")
            if !variantsString.isEmpty {
                subtitle += ": " + variantsString
            }
        }
        
        
        subtitle += " - " + stop.direction
    
        return subtitle
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        static weak var shared: Coordinator?
        weak var mapView: MKMapView?
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            
            let identifier = "StopPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                let button = UIButton(type: .detailDisclosure)
                annotationView?.rightCalloutAccessoryView = button
            } else {
                annotationView?.annotation = annotation
            }
            
            
            let direction = annotation.subtitle??.components(separatedBy: " - ").last ?? ""
            
            let markerImage: UIImage?
            switch direction.lowercased() {
                case "southbound": markerImage = UIImage(named: "GreenBall")
                case "northbound": markerImage = UIImage(named: "OrangeBall")
                case "eastbound": markerImage = UIImage(named: "PinkBall")
                case "westbound": markerImage = UIImage(named: "BlueBall")
                default: markerImage = UIImage(named: "DefaultBall")
            }
            
            if let image = markerImage {
                let size = CGSize(width: 32, height: 32)
                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                image.draw(in: CGRect(origin: .zero, size: size))
                
                if let context = UIGraphicsGetCurrentContext() {
                    context.setBlendMode(.plusLighter)
                    let brightSpotPath = UIBezierPath(ovalIn: CGRect(x: size.width * 0.35,
                                                                    y: size.height * 0.1,
                                                                    width: size.width * 0.1,
                                                                    height: size.height * 0.1))
                    context.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
                    brightSpotPath.fill()
                }
                
                annotationView?.image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                annotationView?.frame.size = size
                
                annotationView?.centerOffset = CGPoint(x: 0, y: -size.height / 2)
            }
            
            annotationView?.layer.shadowColor = UIColor.black.cgColor
            annotationView?.layer.shadowOffset = CGSize(width: 0, height: 1)
            annotationView?.layer.shadowOpacity = 0.3
            annotationView?.layer.shadowRadius = 1
            annotationView?.displayPriority = .required
        
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circleOverlay = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circleOverlay)
                renderer.fillColor = .clear
                renderer.strokeColor = .accent
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if let annotation = view.annotation {
                parent.onAnnotationTapped(annotation)
            }
        }
    }
}

