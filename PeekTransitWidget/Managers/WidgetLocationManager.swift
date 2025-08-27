import CoreLocation
import WidgetKit

class WidgetLocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = WidgetLocationManager()
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
            
            locationManager?.requestLocation()
            
            if let location = locationManager?.location {
                continuation.resume(returning: location)
            } else {
                locationManager?.requestLocation()
                continuation.resume(returning: nil)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}

