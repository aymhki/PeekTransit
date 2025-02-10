import SwiftUI
import WidgetKit

struct LastUpdatedView: View {
    let updatedAt: Date
    let size: String
    
    private var currentTheme: StopViewTheme {
        if let savedTheme = SharedDefaults.userDefaults?.string(forKey: settingsUserDefaultsKeys.sharedStopViewTheme),
           let theme = StopViewTheme(rawValue: savedTheme) {
            return theme
        }
        return .default
    }
    
    var body: some View {
        let fontSizeToUse = getLastSeenFontSizeForWidgetSize(widgetSizeSystemFormat: nil, widgetSizeStringFormat: size)
        
        if (size == "lockscreen" || size == "small") {
            Text("Updated at \(formattedTime)")
                .widgetTheme(currentTheme, text: "Last updated at \(formattedTime)", size: widgetSizeFromString(size))
        } else {
            Text("Last updated at \(formattedTime)")
                .widgetTheme(currentTheme, text: "Last updated at \(formattedTime)", size: widgetSizeFromString(size))
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
