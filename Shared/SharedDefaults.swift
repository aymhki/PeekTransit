import Foundation

struct SharedDefaults {
    static let suiteName = "group.com.PeekTransit.widget"
    static let widgetsKey = "savedWidgets"
    
    static var userDefaults: UserDefaults? {
        let defaults = UserDefaults(suiteName: suiteName)
        print("Accessing SharedDefaults with suite name: \(suiteName), success: \(defaults != nil)") // Debug log
        return defaults
    }
}
