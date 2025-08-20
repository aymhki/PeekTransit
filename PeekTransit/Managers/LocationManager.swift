import CoreLocation
import WidgetKit

class AppLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = AppLocationManager()
    private var manager: CLLocationManager?
    private let minimumDistanceThreshold: CLLocationDistance = getDistanceChangeAllowedBeforeRefreshingStops()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    private var lastRefreshLocation: CLLocation?
    private var hasInitialLocation = false
    
    private override init() {
        super.init()
    }
    
    func initialize() {
        guard manager == nil else { return }
        
        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyBest
        
        authorizationStatus = manager?.authorizationStatus
    }
    
    func startUpdatingLocation() {
        manager?.startUpdatingLocation()
    }
    
    func shouldRefresh(for newLocation: CLLocation) -> Bool {
        guard let lastRefresh = lastRefreshLocation else {
            return true
        }
        
        let distance = newLocation.distance(from: lastRefresh)
        return distance >= minimumDistanceThreshold
    }
    
    func markLocationAsRefreshed(newLocation: CLLocation) {
        lastRefreshLocation = newLocation
    }
    
    func requestLocation() {
        guard let manager = manager else {
            initialize()
            return
        }
        
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if status == .restricted || status == .denied {
            print("Location access denied or restricted")
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.first {
            location = newLocation
            
            if !hasInitialLocation {
                hasInitialLocation = true
                NotificationCenter.default.post(name: .initialLocationAvailable, object: nil)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .locationUnknown:
                print("Location temporarily unavailable")
            case .denied:
                print("Location access denied")
            case .network:
                print("Network error getting location")
            default:
                print("Location error: \(error.localizedDescription)")
            }
        }
    }
}

extension Notification.Name {
    static let initialLocationAvailable = Notification.Name("initialLocationAvailable")
}

