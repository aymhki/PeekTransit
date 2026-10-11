import SwiftUI
import WidgetKit

struct LastUpdatedView: View {
    let updatedAt: Date
    let size: String
    let isLoading: Bool
    let usingCached: Bool
    let forPreview: Bool
    var reservedTrailingSpace: CGFloat = 0
    
    @Environment(\.refreshBusy) private var refreshBusy
    
    private var showsLoading: Bool {
        return isLoading || refreshBusy
    }
    
    private var currentTheme: StopViewTheme {
        if let savedTheme = SharedDefaults.userDefaults?.string(forKey: settingsUserDefaultsKeys.sharedStopViewTheme),
           let theme = StopViewTheme(rawValue: savedTheme) {
            return theme
        }
        return .default
    }
        
    var body: some View {
        
        if (size == "lockscreen" || size == "small") {
            Text(showsLoading ? "Loading..." : "\(usingCached ? "" : " ")Updated at \(formattedTime)  \(usingCached ? "O." : "")" )
                .widgetTheme(currentTheme, text: "Last updated at \(formattedTime)  \(usingCached ? "O." : "")", size: widgetSizeFromString(size), inPreview: forPreview)
                .if(reservedTrailingSpace > 0) { view in
                    view.lineLimit(1).minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.trailing, reservedTrailingSpace)
                .padding(.bottom, 2)
        } else {
            Text(showsLoading ? "Loading..." : "Last updated at \(formattedTime)  \(usingCached ? "Old." : "")" )
                .widgetTheme(currentTheme, text: "Last updated at \(formattedTime)  \(usingCached ? "Old." : "")", size: widgetSizeFromString(size), inPreview: forPreview)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.trailing, reservedTrailingSpace)
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
