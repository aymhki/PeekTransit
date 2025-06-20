
import CoreLocation
import MapKit
import SwiftUI
import Combine

class MapSnapshotCache: ObservableObject {
    static let shared = MapSnapshotCache()
    
    private var cache = NSCache<NSString, CachedSnapshot>()
    private var pendingRequests = [String: [UUID: (UIImage?) -> Void]]()
    private var activeSnapshots = 0
    private let maxConcurrentSnapshots = 8
    private var requestQueue = [(String, UUID, (UIImage?) -> Void)]()
    
    private let serialQueue = DispatchQueue(label: "snapshot.cache", qos: .userInitiated)
    
    private class CachedSnapshot {
        let image: UIImage
        let timestamp: Date
        let themeHash: String
        
        init(image: UIImage, timestamp: Date, themeHash: String) {
            self.image = image
            self.timestamp = timestamp
            self.themeHash = themeHash
        }
    }
    
    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
    }
    
    func clearCache() {
        serialQueue.async {
            self.cache.removeAllObjects()
        }
    }
    
    func cancelPendingRequests() {
        serialQueue.async {
            self.pendingRequests.removeAll()
            self.requestQueue.removeAll()
        }
    }
    
    func cancelRequest(id: UUID) {
        serialQueue.async {
            for (key, requests) in self.pendingRequests {
                if requests[id] != nil {
                    self.pendingRequests[key]?.removeValue(forKey: id)
                    if self.pendingRequests[key]?.isEmpty == true {
                        self.pendingRequests.removeValue(forKey: key)
                    }
                    break
                }
            }
            
            self.requestQueue.removeAll { $0.1 == id }
        }
    }
    
    func snapshot(
        for coordinate: CLLocationCoordinate2D,
        size: CGSize,
        direction: String,
        isDarkMode: Bool,
        requestId: UUID,
        completion: @escaping (UIImage?) -> Void
    ) {
        let themeHash = "\(isDarkMode)"
        let cacheKey = generateCacheKey(coordinate: coordinate, size: size, direction: direction, themeHash: themeHash)
        
        serialQueue.async {
            if let cached = self.cache.object(forKey: cacheKey as NSString),
               cached.themeHash == themeHash,
               Date().timeIntervalSince(cached.timestamp) < 300 {
                DispatchQueue.main.async {
                    completion(cached.image)
                }
                return
            }
            
            if self.pendingRequests[cacheKey] == nil {
                self.pendingRequests[cacheKey] = [:]
            }
            self.pendingRequests[cacheKey]?[requestId] = completion
            
            if self.pendingRequests[cacheKey]?.count ?? 0 > 1 {
                return
            }
            
            if self.activeSnapshots >= self.maxConcurrentSnapshots {
                self.requestQueue.append((cacheKey, requestId, completion))
                return
            }
            
            self.processSnapshotRequest(cacheKey: cacheKey, coordinate: coordinate, size: size, direction: direction, isDarkMode: isDarkMode, themeHash: themeHash)
        }
    }
    
    private func processSnapshotRequest(
        cacheKey: String,
        coordinate: CLLocationCoordinate2D,
        size: CGSize,
        direction: String,
        isDarkMode: Bool,
        themeHash: String
    ) {
        activeSnapshots += 1
        
        generateSnapshot(
            coordinate: coordinate,
            size: size,
            direction: direction,
            isDarkMode: isDarkMode
        ) { [weak self] image in
            guard let self = self else { return }
            
            self.serialQueue.async {
                if let image = image {
                    let cached = CachedSnapshot(image: image, timestamp: Date(), themeHash: themeHash)
                    self.cache.setObject(cached, forKey: cacheKey as NSString)
                }
                
                let callbacks = self.pendingRequests[cacheKey] ?? [:]
                self.pendingRequests.removeValue(forKey: cacheKey)
                self.activeSnapshots -= 1
                
                DispatchQueue.main.async {
                    for (_, callback) in callbacks {
                        callback(image)
                    }
                }
                
                self.processNextQueuedRequest()
            }
        }
    }
    
    private func processNextQueuedRequest() {
        guard !requestQueue.isEmpty, activeSnapshots < maxConcurrentSnapshots else { return }
        
        let (cacheKey, requestId, completion) = requestQueue.removeFirst()
        let components = cacheKey.split(separator: ",")
        
        if components.count == 6,
           let lat = Double(components[0]),
           let lon = Double(components[1]),
           let width = Double(components[2]),
           let height = Double(components[3]),
           let isDarkMode = Bool(String(components[5])) {
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let size = CGSize(width: width, height: height)
            let direction = String(components[4])
            let themeHash = String(components[5])
            
            processSnapshotRequest(
                cacheKey: cacheKey,
                coordinate: coord,
                size: size,
                direction: direction,
                isDarkMode: isDarkMode,
                themeHash: themeHash
            )
        }
    }
    
    private func generateCacheKey(coordinate: CLLocationCoordinate2D, size: CGSize, direction: String, themeHash: String) -> String {
        return "\(coordinate.latitude),\(coordinate.longitude),\(size.width),\(size.height),\(direction),\(themeHash)"
    }
    
    private func generateSnapshot(
        coordinate: CLLocationCoordinate2D,
        size: CGSize,
        direction: String,
        isDarkMode: Bool,
        completion: @escaping (UIImage?) -> Void
    ) {
        let options = MKMapSnapshotter.Options()
        
        let offsetRatio = 0.0000064
        let offsetLatitude = options.region.span.latitudeDelta * offsetRatio
        let offsetCoordinate = CLLocationCoordinate2D(
            latitude: coordinate.latitude + offsetLatitude,
            longitude: coordinate.longitude
        )
        
        options.region = MKCoordinateRegion(
            center: offsetCoordinate,
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
                    y: markerPoint.y - markerSize.height,
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
