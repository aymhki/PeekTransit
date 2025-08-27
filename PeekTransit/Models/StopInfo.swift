import SwiftUI
import CoreLocation

struct StopInfo: Hashable {
    let key: Int
    let name: String
    let location: CLLocationCoordinate2D?
    
    init?(from dict: [String: Any]) {
        guard let key = dict["key"] as? Int,
              let name = dict["name"] as? String,
              let centre = dict["centre"] as? [String: Any],
              let geographic = centre["geographic"] as? [String: Any],
              let lat = geographic["latitude"] as? Double,
              let lon = geographic["longitude"] as? Double else {
            return nil
        }
        
        
        
        self.key = key
        
        self.name = name.replacingOccurrences(of: "@", with: " @ ")
        
        self.location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    init( name: String) {
        self.name = name.replacingOccurrences(of: "@", with: " @ ")
        self.key = -1
        self.location = nil
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(name)
        if let location = location {
            hasher.combine(location.latitude)
            hasher.combine(location.longitude)
        }
    }
    
    public static func == (lhs: StopInfo, rhs: StopInfo) -> Bool {
        return lhs.key == rhs.key &&
               lhs.name == rhs.name &&
               lhs.location?.latitude == rhs.location?.latitude &&
               lhs.location?.longitude == rhs.location?.longitude
    }
}
