import CoreLocation

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
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}
