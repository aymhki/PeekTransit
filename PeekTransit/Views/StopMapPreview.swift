
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
