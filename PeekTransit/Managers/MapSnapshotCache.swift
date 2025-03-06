import CoreLocation
import MapKit
import SwiftUI


class MapSnapshotCache {
    static let shared = MapSnapshotCache()
    
    private var cache = NSCache<NSString, UIImage>()
    private var pendingRequests = Set<String>()
    private var activeSnapshottings = 0
    private let maxConcurrentSnapshottings = 3
    private var queuedRequests = [(String, (UIImage?) -> Void)]()
    
    func clearCache() {
        cache.removeAllObjects()
    }
    
    func cancelPendingRequests() {
        pendingRequests.removeAll()
        queuedRequests.removeAll()
    }
    
    func snapshot(
        for coordinate: CLLocationCoordinate2D,
        size: CGSize,
        direction: String,
        isDarkMode: Bool,
        completion: @escaping (UIImage?) -> Void
    ) {
        let cacheKey = "\(coordinate.latitude),\(coordinate.longitude),\(size.width),\(size.height),\(direction),\(isDarkMode)"
        
        if let cachedImage = cache.object(forKey: cacheKey as NSString) {
            completion(cachedImage)
            return
        }
        
        guard !pendingRequests.contains(cacheKey) else {
            return
        }
        
        if activeSnapshottings >= maxConcurrentSnapshottings {
            queuedRequests.append((cacheKey, completion))
            return
        }
        
        pendingRequests.insert(cacheKey)
        activeSnapshottings += 1
        
        generateSnapshot(coordinate: coordinate, size: size, direction: direction, isDarkMode: isDarkMode) { [weak self] image in
            guard let self = self else { return }
            
            if let image = image {
                self.cache.setObject(image, forKey: cacheKey as NSString)
            }
            
            self.pendingRequests.remove(cacheKey)
            self.activeSnapshottings -= 1
            
            DispatchQueue.main.async {
                completion(image)
                
                if !self.queuedRequests.isEmpty {
                    let (nextKey, nextCompletion) = self.queuedRequests.removeFirst()
                    let components = nextKey.split(separator: ",")
                    
                    if components.count == 6,
                       let lat = Double(components[0]),
                       let lon = Double(components[1]),
                       let width = Double(components[2]),
                       let height = Double(components[3]),
                       let isDarkMode = Bool(String(components[5])) {
                        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        let size = CGSize(width: width, height: height)
                        let direction = String(components[4])
                        
                        self.snapshot(
                            for: coord,
                            size: size,
                            direction: direction,
                            isDarkMode: isDarkMode,
                            completion: nextCompletion
                        )
                    }
                }
            }
        }
    }
    
    private func generateSnapshot(
        coordinate: CLLocationCoordinate2D,
        size: CGSize,
        direction: String,
        isDarkMode: Bool,
        completion: @escaping (UIImage?) -> Void
    ) {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        )
        options.size = size
        options.showsBuildings = false
        options.pointOfInterestFilter = .excludingAll
        options.traitCollection = UITraitCollection(userInterfaceStyle: isDarkMode ? .dark : .light)
        
        let snapshotter = MKMapSnapshotter(options: options)
        
        snapshotter.start { [weak self] snapshot, error in
            if let error = error {
                print("Snapshot error: \(error)")
                completion(nil)
                return
            }
            
            guard let snapshot = snapshot, let markerImage = self?.getMarkerImage(for: direction) else {
                completion(nil)
                return
            }
            
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
            
            completion(finalImage)
        }
    }
    
    private func getMarkerImage(for direction: String) -> UIImage? {
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
        
        return UIImage(named: imageName)
    }
}
