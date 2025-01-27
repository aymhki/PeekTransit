import SwiftUI
import MapKit

struct LiveIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<1) { i in
                Circle()
                    .stroke(Color.red.opacity(0.5), lineWidth: 2)
                    .scaleEffect(isAnimating ? 2 : 1)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        .easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 1),
                        value: isAnimating
                    )
            }
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
        }
        .frame(width: 24, height: 24)
        .onAppear {
            isAnimating = true
        }
    }
}

struct RetroBoard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(.black.opacity(0.1))
                    .overlay(
                        GeometryReader { geometry in
                            Path { path in
                                for y in stride(from: 0, to: geometry.size.height, by: 2) {
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                                }
                            }
                            .stroke(.black.opacity(0.05))
                        }
                    )
            )
            .overlay(
                GeometryReader { geometry in
                    Path { path in
                        let gridSize: CGFloat = 4
                        for x in stride(from: 0, to: geometry.size.width, by: gridSize) {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                        }
                        for y in stride(from: 0, to: geometry.size.height, by: gridSize) {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                    }
                    .stroke(.black.opacity(0.05), lineWidth: 0.5)
                }
            )
    }
}

struct BusStopView: View {
    let stop: [String: Any]
    @StateObject private var savedStopsManager = SavedStopsManager.shared
    @State private var isSaved: Bool = false
    @State private var schedules: [String] = []
    @State private var isLoading = false
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    private var coordinate: CLLocationCoordinate2D? {
        guard let centre = stop["centre"] as? [String: Any],
              let geographic = centre["geographic"] as? [String: Any],
              let lat = Double(geographic["latitude"] as? String ?? ""),
              let lon = Double(geographic["longitude"] as? String ?? "") else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    private func loadSchedules() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let stopNumber = stop["number"] as? Int else { return }
            let schedule = try await TransitAPI.shared.getStopSchedule(stopNumber: stopNumber)
            schedules = TransitAPI.shared.cleanStopSchedule(schedule: schedule)
        } catch {
            print("Error loading schedules: \(error)")
        }
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text(stop["name"] as? String ?? "Bus Stop")
                        .font(.title3.bold())
                    Spacer()
                    LiveIndicator()
                }
                .listRowBackground(Color.clear)
            }

            if let coordinate = coordinate {
                Section {
                    RealMapPreview(
                        coordinate: coordinate,
                        direction: stop["direction"] as? String ?? "Unknown Direction"
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .listRowInsets(EdgeInsets())
                }
            }
            
            Section {
//                if isLoading {
//                    VStack(spacing: 16) {
//                        ProgressView()
//                            .scaleEffect(1.5)
//                        Text("Loading schedules...")
//                            .foregroundStyle(.secondary)
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 32)
//                } else
                
                if schedules.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bus.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No service at this bus stop during this time")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    VStack(spacing: 0) {
                        Spacer()
                        ForEach(schedules, id: \.self) { schedule in
                            let components = schedule.components(separatedBy: " ---- ")
                            if components.count == 3 {
                                HStack {
                                    Text(components[0])
                                        .font(.system(.subheadline, design: .monospaced).bold())
                                    Spacer()
                                    Text(components[1])
                                        .font(.system(.subheadline, design: .monospaced).bold())
                                    Spacer()
                                    Text(components[2])
                                        .font(.system(.headline, design: .monospaced).bold())
                                        .foregroundStyle(
                                            components[1].contains("Late") ? .red :
                                            components[1].contains("Cancelled") ? .red :
                                            .primary
                                        )
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                            }
                        }
                        .padding(.all)
                        Spacer()
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
//            header: {
//                Text("Upcoming Buses")
//                    .font(.title3.bold())
//            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("#\(String(stop["number"] as? Int ?? 0))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    savedStopsManager.toggleSavedStatus(for: stop)
                    isSaved.toggle()
                } label: {
                    Image(systemName: isSaved ? "star.fill" : "star")
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                Task {
                    await loadSchedules()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
        }
        .refreshable {
            await loadSchedules()
        }
        .onAppear {
            isSaved = savedStopsManager.isStopSaved(stop)
            Task {
                await loadSchedules()
            }
        }
        .onReceive(timer) { _ in
            Task {
                await loadSchedules()
            }
        }
    }
}
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

            // Set the pin image and color based on direction
            let markerImage: UIImage?
            switch parent.direction.lowercased() {
            case "southbound":
                markerImage = UIImage(named: "GreenBall")?.withTintColor(.systemGreen, renderingMode: .alwaysTemplate)
            case "northbound":
                markerImage = UIImage(named: "OrangeBall")?.withTintColor(.systemOrange, renderingMode: .alwaysTemplate)
            case "eastbound":
                markerImage = UIImage(named: "PinkBall")?.withTintColor(.systemRed, renderingMode: .alwaysTemplate)
            case "westbound":
                markerImage = UIImage(named: "BlueBall")?.withTintColor(.systemBlue, renderingMode: .alwaysTemplate)
            default:
                markerImage = UIImage(named: "DefaultBall")?.withTintColor(.systemGray, renderingMode: .alwaysTemplate)
            }

            if let image = markerImage {
                annotationView?.image = image
                annotationView?.frame.size = CGSize(width: 32, height: 32)
            }

            return annotationView
        }
    }
}
