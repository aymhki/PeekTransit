import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: StopViewTheme {
        didSet {
            SharedDefaults.userDefaults?.set(currentTheme.rawValue, forKey: settingsUserDefaultsKeys.sharedStopViewTheme)
        }
    }
    
    private init() {
        let savedTheme = SharedDefaults.userDefaults?.string(forKey: settingsUserDefaultsKeys.sharedStopViewTheme) ?? StopViewTheme.default.rawValue
        self.currentTheme = StopViewTheme(rawValue: savedTheme) ?? .default
    }
    
    func updateTheme(_ newTheme: StopViewTheme) {
        currentTheme = newTheme
    }
}

