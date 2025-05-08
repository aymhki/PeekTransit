import CoreLocation
import WidgetKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var manager: CLLocationManager?
    private let minimumDistanceThreshold: CLLocationDistance = getDistanceChangeAllowedBeforeRefreshingStops()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    private var lastRefreshLocation: CLLocation?
    
    override init() {
        super.init()
    }
    
    func initialize() {
        guard manager == nil else { return }
        
        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func startUpdatingLocation() {
        manager?.startUpdatingLocation()
    }
    
    func shouldRefresh(for newLocation: CLLocation) -> Bool {
        guard let lastRefresh = lastRefreshLocation else {
            lastRefreshLocation = newLocation
            return true
        }
        
        let distance = newLocation.distance(from: lastRefresh)
        if distance >= minimumDistanceThreshold {
            lastRefreshLocation = newLocation
            WidgetCenter.shared.reloadAllTimelines()
            return true
        }
        
        return false
    }
    
    func requestLocation() {
        guard let manager = manager else { return }
        
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}
