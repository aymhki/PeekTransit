import SwiftUI
import MapKit
import WidgetKit


struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var stopsStore = StopsDataStore.shared
    @State private var region = MKCoordinateRegion()
    @State private var selectedStop: [String: Any]?
    @State private var forceRefresh = UUID()

    
    private let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    private let closeSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    
    var body: some View {
        NavigationStack {
            ZStack {
                MapViewRepresentable(
                    region: $region,
                    stops: stopsStore.stops,
                    userLocation: locationManager.location,
                    onAnnotationTapped: { annotation in
                        if let title = annotation.title ?? "",
                           let stop = stopsStore.stops.first(where: { ($0["name"] as? String) == title }) {
                            selectedStop = stop
                        }
                    }
                )
                .id(forceRefresh)
                .edgesIgnoringSafeArea(.top)
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: refreshLocation) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .padding()
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
                
                if stopsStore.isLoading {
                    ProgressView()
                        .padding()
                        .background(Color(.systemBackground).opacity(1))
                        .cornerRadius(8)
                        
                        
                }
                
                if let error = stopsStore.error {
                    VStack {
                        Text("Error loading stops")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                        Button("Retry") {
                            let newLocation = locationManager.location
                            if let location = newLocation {
                                region = MKCoordinateRegion(
                                    center: location.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                                Task {
                                    await stopsStore.loadStops(userLocation: location)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(1))
                    .cornerRadius(8)
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedStop != nil },
                set: { if !$0 { selectedStop = nil } }
            )) {
                if let stop = selectedStop {
                    BusStopView(stop: stop)
                }
            }
        }
        .onAppear {
            locationManager.requestLocation()
            refreshLocation()
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
                
                if locationManager.shouldRefresh(for: location) {
                    Task {
                        await stopsStore.loadStops(userLocation: location)
                    }
                }
            }
        }
    }
    
    private func refreshLocation() {
        locationManager.manager.requestLocation()
        
        if let location = locationManager.location {
            forceRefresh = UUID()
            
            let newRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: closeSpan
            )
            
            withAnimation(.easeInOut(duration: 0.5)) {
                region = newRegion
            }
            
            if locationManager.shouldRefresh(for: location) {
                Task {
                    await stopsStore.loadStops(userLocation: location)
                }
            }
        }
    }
}



struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let stops: [[String: Any]]
    let userLocation: CLLocation?
    let onAnnotationTapped: (MKAnnotation) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        for stop in stops {
            if let centre = stop["centre"] as? [String: Any],
               let geographic = centre["geographic"] as? [String: Any],
               let lat = Double(geographic["latitude"] as? String ?? ""),
               let lon = Double(geographic["longitude"] as? String ?? "") {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                annotation.title = stop["name"] as? String
                annotation.subtitle = "#\(stop["number"] as? Int ?? 0)"
                
                var variantsString = ""
                
                if let variants = stop["variants"] as? [[String: Any]] {
                    for (index, variant) in variants.enumerated() {
                        if let route = variant["route"] as? [String: Any],
                           let variantDict = variant["variant"] as? [String: Any],
                           let key = variantDict["key"] as? String {
                            
                            variantsString += key.split(separator: "-")[0].description
                            
                            if index < variants.count - 1 {
                                variantsString += ", "
                            }
                        }
                    }
                }
                
                annotation.subtitle = annotation.subtitle! + ": " + variantsString
                
                annotation.subtitle = annotation.subtitle! + " - " + (stop["direction"] as? String ?? "Unknown Direction")
                
                
                mapView.addAnnotation(annotation)
            }
        }
        
        if let userLocation = userLocation {
            let circle = MKCircle(center: userLocation.coordinate, radius: 600)
            mapView.addOverlay(circle)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
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
            
            if let subtitle = annotation.subtitle,
               let direction = subtitle?.components(separatedBy: " - ").last {
                
                let markerImage: UIImage?
                switch direction.lowercased() {
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
                    annotationView?.bounds = CGRect(x: 0, y: 0, width: 44, height: 44)
                    annotationView?.centerOffset = CGPoint(x: 0, y: -16)
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
