import CoreLocation
import WidgetKit

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private var locationManager: CLLocationManager?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func getCurrentLocation() async -> CLLocation? {
        return await withCheckedContinuation { continuation in
            if let location = locationManager?.location {
                continuation.resume(returning: location)
            } else {
                locationManager?.requestLocation()
                continuation.resume(returning: nil)
            }
        }
    }
    
    // CLLocationManagerDelegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}

