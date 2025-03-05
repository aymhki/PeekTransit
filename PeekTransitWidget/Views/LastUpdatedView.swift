import SwiftUI
import WidgetKit

struct LastUpdatedView: View {
    let updatedAt: Date
    let size: String
    let isLoading: Bool
    let usingCached: Bool
    
    private var currentTheme: StopViewTheme {
        if let savedTheme = SharedDefaults.userDefaults?.string(forKey: settingsUserDefaultsKeys.sharedStopViewTheme),
           let theme = StopViewTheme(rawValue: savedTheme) {
            return theme
        }
        return .default
    }
    
    var body: some View {
        
        if (size == "lockscreen" || size == "small") {
            Text("Updated at \(formattedTime) \(isLoading ? "Updating..." : "") \(usingCached ? "O." : "")" )
                .widgetTheme(currentTheme, text: "Last updated at \(formattedTime) \(isLoading ? "Updating..." : "") \(usingCached ? "O." : "")", size: widgetSizeFromString(size))
                .padding(.bottom, 2)
        } else {
            Text("Last updated at \(formattedTime) \(isLoading ? "Updating..." : "") \(usingCached ? "Old." : "")" )
                .widgetTheme(currentTheme, text: "Last updated at \(formattedTime) \(isLoading ? "Updating..." : "") \(usingCached ? "Old." : "")", size: widgetSizeFromString(size))
                .padding(.bottom, 8)
        }
    }
    
    private func widgetSizeFromString(_ size: String) -> WidgetFamily {
        switch size {
        case "large": return .systemLarge
        case "medium": return .systemMedium
        case "small": return .systemSmall
        case "lockscreen": return .accessoryRectangular
        default: return .systemMedium
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: updatedAt)
    }
}
