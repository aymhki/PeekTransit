import Foundation

struct SharedDefaults {
    static let suiteName = "group.com.PeekTransit.widget"
    static let widgetsKey = "savedWidgets"
    
    static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
}
