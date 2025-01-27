import SwiftUI
import CoreLocation
import MapKit


import SwiftUI
import CoreLocation
import MapKit

struct StopMapPreview: View {
    let coordinate: CLLocationCoordinate2D
    let direction: String
    @State private var snapshotImage: UIImage?
    
    @Environment(\.colorScheme) var colorScheme
    
    private func getMarkerImage() -> UIImage? {
        let imageName: String
        switch direction.lowercased() {
        case "southbound":
            imageName = "GreenBall"
        case "northbound":
            imageName = "OrangeBall"
        case "eastbound":
            imageName = "PinkBall"
        case "westbound":
            imageName = "BlueBall"
        default:
            imageName = "DefaultBall"
        }
        
        let color: UIColor
        switch direction.lowercased() {
        case "southbound":
            color = .systemGreen
        case "northbound":
            color = .systemOrange
        case "eastbound":
            color = .systemRed
        case "westbound":
            color = .systemBlue
        default:
            color = .systemGray
        }
        
        return UIImage(named: imageName)?.withTintColor(color, renderingMode: .alwaysTemplate)
    }
    
    private func generateSnapshot() {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        )
        options.size = CGSize(width: 80, height: 80)
        options.showsBuildings = false
        options.pointOfInterestFilter = .excludingAll
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            guard let snapshot = snapshot,
                  let markerImage = getMarkerImage() else { return }
            
            let markerSize = CGSize(width: 32, height: 32)
            let renderer = UIGraphicsImageRenderer(size: snapshot.image.size)
            
            let finalImage = renderer.image { context in
                snapshot.image.draw(at: .zero)
                
                let markerPoint = snapshot.point(for: coordinate)
                let markerRect = CGRect(
                    x: markerPoint.x - markerSize.width/2,
                    y: markerPoint.y - markerSize.height/2,
                    width: markerSize.width,
                    height: markerSize.height
                )
                
                markerImage.draw(in: markerRect)
                context.cgContext.setBlendMode(.plusLighter)
                
                let brightSpotRect = CGRect(
                    x: markerRect.minX + markerRect.width * 0.35,
                    y: markerRect.minY + markerRect.height * 0.1,
                    width: markerRect.width * 0.1,
                    height: markerRect.height * 0.1
                )
                let brightSpotPath = UIBezierPath(ovalIn: brightSpotRect)
                UIColor.white.withAlphaComponent(0.9).setFill()
                brightSpotPath.fill()
                
                context.cgContext.setShadow(
                    offset: CGSize(width: 0, height: 1),
                    blur: 1,
                    color: UIColor.black.withAlphaComponent(0.3).cgColor
                )
            }
            
            DispatchQueue.main.async {
                self.snapshotImage = finalImage
            }
        }
    }
    
    var body: some View {
        Group {
            if let image = snapshotImage {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
            } else {
                Color.gray.opacity(0.2)
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .onAppear {
                        generateSnapshot()
                    }
            }
        }
        .onChange(of: colorScheme) { _ in
            generateSnapshot()
        }
    }
}


struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? 0
        var totalHeight: CGFloat = 0
        var currentLineWidth: CGFloat = 0
        var currentLineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentLineWidth + size.width > containerWidth {
                totalHeight += currentLineHeight + spacing
                currentLineWidth = size.width
                currentLineHeight = size.height
            } else {
                currentLineWidth += size.width + spacing
                currentLineHeight = max(currentLineHeight, size.height)
            }
        }
        
        totalHeight += currentLineHeight
        return CGSize(width: containerWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var currentLineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > bounds.maxX {
                currentY += currentLineHeight + spacing
                currentX = bounds.minX
                currentLineHeight = 0
            }
            
            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            
            currentX += size.width + spacing
            currentLineHeight = max(currentLineHeight, size.height)
        }
    }
}



struct StopRow: View {
    let stop: [String: Any]
    let variants: [[String: Any]]
    let inSaved: Bool
    
    private var coordinate: CLLocationCoordinate2D? {
        guard let centre = stop["centre"] as? [String: Any],
              let geographic = centre["geographic"] as? [String: Any],
              let lat = Double(geographic["latitude"] as? String ?? ""),
              let lon = Double(geographic["longitude"] as? String ?? "") else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var body: some View {
        NavigationLink(destination: BusStopView(stop: stop)) {
            HStack(alignment: .top, spacing: 12) {
                if let coordinate = coordinate {
                                    StopMapPreview(
                                        coordinate: coordinate,
                                        direction: stop["direction"] as? String ?? "Unknown Direction"
                                    )
                                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(stop["name"] as? String ?? "Unknown Stop")
                            .font(.headline)
                            .lineLimit(3)
                        Spacer()
                        Text("#\(stop["number"] as? Int ?? 0)".replacingOccurrences(of: ",", with: ""))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            
                    }
                    
                    
                    if (!inSaved) {
                        if let distances = stop["distances"] as? [String: Any],
                           let currentDistance = distances.first,
                           let currentDistandValueString = currentDistance.value as? String,
                           let distanceInMeters = Double(currentDistandValueString) {
                            
                            Text(String(format: "%.0f meters away", distanceInMeters))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ScrollView {
                        FlowLayout(spacing: 2) {
                            ForEach(variants.indices, id: \.self) { index in
                                if let route = variants[index]["route"] as? [String: Any],
                                   let variant = variants[index]["variant"] as? [String: Any] {
                                    VariantBadge(route: route, variant: variant)
                                }
                            }
                        }
                        .padding(.top)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


extension CLLocationCoordinate2D: Identifiable {
    public var id: String {
        "\(latitude)-\(longitude)"
    }
}


struct VariantBadge: View {
    let route: [String: Any]
    let variant: [String: Any]
    
    private var variantNumber: String {
        if let key = variant["key"] as? String {
            return key.split(separator: "-")[0].description
        }
        return ""
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(variantNumber)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.3))
        .cornerRadius(8)
    }
}

struct ListView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var stopsStore = StopsDataStore.shared
    @State private var searchText = ""
    @State private var showAlert = false


       var filteredStops: [[String: Any]] {
           guard !searchText.isEmpty else { return stopsStore.stops }
        
           return stopsStore.stops.filter { stop in
            if let name = stop["name"] as? String,
               name.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            if let number = stop["number"] as? Int,
               String(number).contains(searchText) {
                return true
            }
            
            if let variants = stop["variants"] as? [[String: Any]] {
                return variants.contains { variant in
                    if let variantDict = variant["variant"] as? [String: Any],
                       let key = variantDict["key"] as? String {
                        return key.localizedCaseInsensitiveContains(searchText)
                    }
                    return false
                }
            }
            
            return false
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if stopsStore.isLoading {
                    ProgressView("Loading stops...")
                } else if let error = stopsStore.error {
                    VStack {
                        Text("Error loading stops")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Retry") {
                            let newLocation = locationManager.location
                            if let location = newLocation {
                                Task {
                                    await stopsStore.loadStops(userLocation: location)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if stopsStore.stops.isEmpty {
                    Text("No stops found nearby")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(filteredStops.indices, id: \.self) { index in
                            let stop = filteredStops[index]
                            if let variants = stop["variants"] as? [[String: Any]] {
                                StopRow(stop: stop, variants: variants, inSaved: false)
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search stops, routes...")
                    .refreshable {
                        let newLocation = locationManager.location
                        if let location = newLocation {
                            Task {
                                await stopsStore.loadStops(userLocation: location)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nearby Stops")
            .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    guard let url = URL(string: "mailto:agamyahk@myumanitoba.ca") else { return }
                                    if UIApplication.shared.canOpenURL(url) {
                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                    } else {
                                        
                                        showAlert = true
                                    }
                                }) {
                                    Image(systemName: "info.circle")
                                }

                            }
                        }
                        .alert("Could not find an email client", isPresented: $showAlert) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text("There does not seem to be an email client set for this device.")
                        }
        }
        .onAppear {
            locationManager.requestLocation()
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation,
               locationManager.shouldRefresh(for: location) {
                Task {
                    await stopsStore.loadStops(userLocation: location)
                }
            }
        }
    }

}
