import Foundation

struct SharedDefaults {
    static let suiteName = "group.com.PeekTransit.widget"
    static let widgetsKey = "savedWidgets"
    
    static var userDefaults: UserDefaults? {
        let defaults = UserDefaults(suiteName: suiteName)
        return defaults
    }
}
