import SwiftUI
import WidgetKit

struct LastUpdatedView: View {
    let updatedAt: Date
    let size: String
    let isLoading: Bool
    let usingCached: Bool
    let forPreview: Bool
    
    private var currentTheme: StopViewTheme {
        if let savedTheme = SharedDefaults.userDefaults?.string(forKey: settingsUserDefaultsKeys.sharedStopViewTheme),
           let theme = StopViewTheme(rawValue: savedTheme) {
            return theme
        }
        return .default
    }
        
    var body: some View {
        
        if (size == "lockscreen" || size == "small") {
            Text("\(usingCached ? "" : " ")Updated at \(formattedTime) \(isLoading ? "Updating..." : "") \(usingCached ? "O." : "")" )
                .widgetTheme(currentTheme, text: "Last updated at \(formattedTime) \(isLoading ? "Updating..." : "") \(usingCached ? "O." : "")", size: widgetSizeFromString(size), inPreview: forPreview)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 2)
        } else {
            Text("Last updated at \(formattedTime) \(isLoading ? "Updating..." : "") \(usingCached ? "Old." : "")" )
                .widgetTheme(currentTheme, text: "Last updated at \(formattedTime) \(isLoading ? "Updating..." : "") \(usingCached ? "Old." : "")", size: widgetSizeFromString(size), inPreview: forPreview)
                .frame(maxWidth: .infinity, alignment: .center)
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
