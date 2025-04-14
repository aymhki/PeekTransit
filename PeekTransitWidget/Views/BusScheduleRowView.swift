import SwiftUI
import WidgetKit

struct BusScheduleRow: View {
    let schedule: String
    let size: WidgetFamily
    let fullyLoaded: Bool
    let forPreview: Bool
    
    private var currentTheme: StopViewTheme {
        if let savedTheme = SharedDefaults.userDefaults?.string(forKey: settingsUserDefaultsKeys.sharedStopViewTheme),
           let theme = StopViewTheme(rawValue: savedTheme) {
            return theme
        }
        return .default
    }
    
    
    var body: some View {
        let components = schedule.components(separatedBy: getScheduleStringSeparator())
        if components.count >= 4 {
            HStack(spacing: 4) {
                Text(components[0])
                    .widgetTheme(currentTheme, text: components[0], size: size)
                    .frame(width: getRouteNumberWidth(size: size), alignment: .leading)
                
                if !components[1].isEmpty {
                    if (size != .systemSmall && size != .accessoryRectangular) {
                        let routeName = components[1]
                        Text(routeName)
                        .widgetTheme(currentTheme, text: components[1], size: size)
                        .frame(width: getRouteNameWidth(size: size), alignment: .leading)
                    } else {
                        Text("\(components[1].prefix(1)).")
                            .widgetTheme(currentTheme, text: components[1], size: size)
                            .frame(width: getRouteNameWidth(size: size), alignment: .leading)
                    }
                }
                
                
                if (size != .systemSmall && size != .accessoryRectangular) {
                    
                    Spacer()
                }
                
                
                if (components[2] == getLateStatusTextString() ||
                    components[2] == getEarlyStatusTextString() ||
                    components[2] == getCancelledStatusTextString()) {
                    
                    if ( (size == .systemSmall || size == .accessoryRectangular) && components[2] != getCancelledStatusTextString()) {
                        Text("\(components[2].prefix(1)).")
                            .widgetTheme(currentTheme, text: components[2], size: size)
                            .frame(alignment: .center)
                            
                    } else {
                        Text(components[2])
                            .widgetTheme(currentTheme, text: components[2], size: size)
                            .frame(alignment: .center)
                    }
                } else if (size == .accessoryRectangular) {
                    Text(" ")
                        .widgetTheme(currentTheme, text: components[2], size: size)
                        .frame(alignment: .center)
                }
                
                if (size != .systemSmall && size != .accessoryRectangular) {
                    Spacer()
                }
                    
                if (components[2] != getCancelledStatusTextString()) {
                    Text(components[3])
                        .widgetTheme(currentTheme, text: components[3], size: size)
                        .frame(alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
        }
           
    }
    
    

}
