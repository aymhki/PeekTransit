import SwiftUI
import CoreLocation
import MapKit

struct StopMapPreview: View {
    let coordinate: CLLocationCoordinate2D
    let direction: String
    @State private var snapshotImage: UIImage?
    @State private var snapshotID = UUID()
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    
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
        
        return UIImage(named: imageName)
    }
    
    private func generateSnapshot() {
        snapshotImage = nil
        snapshotID = UUID()
        
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        )
        options.size = CGSize(width: 80, height: 80)
        options.showsBuildings = false
        options.pointOfInterestFilter = .excludingAll
        options.traitCollection = UITraitCollection(userInterfaceStyle: getPreferredStyle())
        
        let snapshotter = MKMapSnapshotter(options: options)
        
        Task { @MainActor in
            do {
                let snapshot: MKMapSnapshotter.Snapshot = try await withCheckedThrowingContinuation { continuation in
                    snapshotter.start { snapshot, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        if let snapshot = snapshot {
                            continuation.resume(returning: snapshot)
                        } else {
                            continuation.resume(throwing: NSError(domain: "MapSnapshot", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate snapshot"]))
                        }
                    }
                }
                
                guard let markerImage = getMarkerImage() else { return }
                
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
                
                self.snapshotImage = finalImage
            } catch {
                print("Failed to generate snapshot: \(error)")
            }
        }
    }
    
    private func getPreferredStyle() -> UIUserInterfaceStyle {
        switch themeManager.currentTheme {
        case .classic:
            return .dark
        case .modern:
            return colorScheme == .dark ? .dark : .light
        }
    }
    
    var body: some View {
        Group {
            if let image = snapshotImage {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .id(snapshotID)
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
            withAnimation {
                generateSnapshot()
            }
        }
        .onChange(of: themeManager.currentTheme) { _ in
            withAnimation {
                generateSnapshot()
            }
        }
    }
}
