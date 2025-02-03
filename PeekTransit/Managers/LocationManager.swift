import CoreLocation
import WidgetKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager: CLLocationManager
    private let minimumDistanceThreshold: CLLocationDistance = 10 
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    private var lastRefreshLocation: CLLocation?
    
    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
        
    }
    
    func shouldRefresh(for newLocation: CLLocation) -> Bool {
        WidgetCenter.shared.reloadAllTimelines()
        
        guard let lastRefresh = lastRefreshLocation else {
            lastRefreshLocation = newLocation
            return true
        }
        
        let distance = newLocation.distance(from: lastRefresh)
        if distance >= minimumDistanceThreshold {
            lastRefreshLocation = newLocation
            return true
        }
        
        return false
    }
    
    func requestLocation() {
        WidgetCenter.shared.reloadAllTimelines()
        let status = manager.authorizationStatus
            if status == .notDetermined {
                manager.requestWhenInUseAuthorization()
            } else if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        WidgetCenter.shared.reloadAllTimelines()
        location = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        WidgetCenter.shared.reloadAllTimelines()
        authorizationStatus = status
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        WidgetCenter.shared.reloadAllTimelines()
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}
