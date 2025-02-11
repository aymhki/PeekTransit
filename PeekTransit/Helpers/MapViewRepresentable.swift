import SwiftUI
import MapKit
import WidgetKit

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let stops: [[String: Any]]
    let userLocation: CLLocation?
    @Binding var userInitiatedRegionChange: Bool
    let onAnnotationTapped: (MKAnnotation) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        if !context.coordinator.isUserInteracting {
            mapView.setRegion(region, animated: true)
        }
        
        let existingAnnotations = mapView.annotations.compactMap { $0 as? MKPointAnnotation }
        let existingStopTitles = Set(existingAnnotations.compactMap { $0.title })
        let newStopTitles = Set(stops.compactMap { $0["name"] as? String })
        
        if existingStopTitles != newStopTitles {
            mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
            addStopAnnotations(to: mapView)
        }
        
        mapView.removeOverlays(mapView.overlays)
        if let userLocation = userLocation {
            let circle = MKCircle(center: userLocation.coordinate, radius: getStopsDistanceRadius())
            mapView.addOverlay(circle)
        }
    }
    
    private func addStopAnnotations(to mapView: MKMapView) {
        for stop in stops {
            if let centre = stop["centre"] as? [String: Any],
               let geographic = centre["geographic"] as? [String: Any],
               let lat = Double(geographic["latitude"] as? String ?? ""),
               let lon = Double(geographic["longitude"] as? String ?? "") {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                annotation.title = stop["name"] as? String
                annotation.subtitle = formatSubtitle(for: stop)
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    private func formatSubtitle(for stop: [String: Any]) -> String {
        var subtitle = "#\(stop["number"] as? Int ?? 0)"
        var variantsString = ""
        
        if let variants = stop["variants"] as? [[String: Any]] {
            let uniqueRoutes = Set(variants.compactMap { variant -> String? in
                guard let variantDict = variant["variant"] as? [String: Any],
                      let key = variantDict["key"] as? String else { return nil }
                return key.split(separator: "-")[0].description
            })
            variantsString = uniqueRoutes.joined(separator: ", ")
        }
        
        subtitle += ": " + variantsString
        subtitle += " - " + (stop["direction"] as? String ?? "Unknown Direction")
        return subtitle
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        var isUserInteracting = false
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            guard let view = mapView.subviews.first else { return }
            isUserInteracting = view.gestureRecognizers?.contains(where: { $0.state == .began || $0.state == .changed }) ?? false
            if isUserInteracting {
                parent.userInitiatedRegionChange = true
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            if isUserInteracting {
                parent.region = mapView.region
            }
            isUserInteracting = false
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
            
            if let subtitle = annotation.subtitle,
               let direction = subtitle?.components(separatedBy: " - ").last {
                
                let markerImage: UIImage?
                switch direction.lowercased() {
                case "southbound":
                    markerImage = UIImage(named: "GreenBall")
                case "northbound":
                    markerImage = UIImage(named: "OrangeBall")
                case "eastbound":
                    markerImage = UIImage(named: "PinkBall")
                case "westbound":
                    markerImage = UIImage(named: "BlueBall")
                default:
                    markerImage = UIImage(named: "DefaultBall")
                }
                
                if let image = markerImage {
                    let size = CGSize(width: 32, height: 32)
                    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                    defer { UIGraphicsEndImageContext() }
                    
                    guard let context = UIGraphicsGetCurrentContext() else {
                        annotationView?.image = image
                        annotationView?.frame.size = size
                        return annotationView
                    }
                    
                    image.draw(in: CGRect(origin: .zero, size: size))
                    context.setBlendMode(.plusLighter)
                    
                    let brightSpotPath = UIBezierPath(ovalIn: CGRect(x: size.width * 0.35,
                                                                    y: size.height * 0.1,
                                                                    width: size.width * 0.1,
                                                                    height: size.height * 0.1))
                    context.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
                    brightSpotPath.fill()
                    
                    let glossyImage = UIGraphicsGetImageFromCurrentImageContext()
                    annotationView?.image = glossyImage
                    annotationView?.frame.size = size
                }
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

