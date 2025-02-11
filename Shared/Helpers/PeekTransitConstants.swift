import WidgetKit
import SwiftUI
import Foundation
import Combine
import CoreLocation


public func getMaxSopsAllowed(widgetSizeSystemFormat: WidgetFamily?, widgetSizeStringFormat: String?) -> Int {
    
    if (widgetSizeSystemFormat == nil && widgetSizeStringFormat != nil) {
        
        if (widgetSizeStringFormat == "large") {
            return 3
        } else if (widgetSizeStringFormat == "medium") {
            return 2
        } else if (widgetSizeStringFormat == "small") {
            return 1
        } else if (widgetSizeStringFormat == "lockscreen") {
            return 2
        } else {
            return 1
        }
        
    } else if (widgetSizeStringFormat == nil && widgetSizeSystemFormat != nil) {
        
        if (widgetSizeSystemFormat == .systemLarge) {
            return 3
        } else if (widgetSizeSystemFormat == .systemMedium) {
            return 2
        } else if (widgetSizeSystemFormat == .systemSmall) {
            return 1
        } else if (widgetSizeSystemFormat == .accessoryRectangular) {
            return 2
        } else {
            return 1
        }
        
    } else {
        return 1
    }
    
}


public func getMaxVariantsAllowed(widgetSizeSystemFormat: WidgetFamily?, widgetSizeStringFormat: String?) -> Int {
    
    if (widgetSizeSystemFormat == nil && widgetSizeStringFormat != nil) {
        
        if (widgetSizeStringFormat == "large") {
            return 2
        } else if (widgetSizeStringFormat == "medium") {
            return 2
        } else if (widgetSizeStringFormat == "small") {
            return 2
        } else if (widgetSizeStringFormat == "lockscreen") {
            return 1
        } else {
            return 1
        }
        
    } else if (widgetSizeStringFormat == nil && widgetSizeSystemFormat != nil) {
        
        if (widgetSizeSystemFormat == .systemLarge) {
            return 2
        } else if (widgetSizeSystemFormat == .systemMedium) {
            return 2
        } else if (widgetSizeSystemFormat == .systemSmall) {
            return 2
        } else if (widgetSizeSystemFormat == .accessoryRectangular) {
            return 1
        } else {
            return 1
        }
        
    } else {
        return 1
    }
    
}

public func getStopsDistanceRadius() -> Double {
    return 650
}


public func getMaxStopsAllowedToFetch() -> Int {
    return 35
}

public func getMaxStopsAllowedToFetchForSearch() -> Int {
    return 10
}


public func getMaxBusRouteLength() -> Int {
    return 10
}

public func getMaxBusRoutePrefixLength() -> Int {
    return 8
}


public func getMaxBusRouteLengthForWidget() -> Int {
    return 12
}

public func getMaxBusRoutePrefixLengthForWidget() -> Int {
    return 10
}


public func getTimePeriodAllowedForNextBusRoutes() -> Int {
    return 12
}

public func getNormalFontSizeForWidgetSize(widgetSizeSystemFormat: WidgetFamily?, widgetSizeStringFormat: String?) -> CGFloat {

    if (widgetSizeSystemFormat == nil && widgetSizeStringFormat != nil) {
        if (widgetSizeStringFormat == "large") {
            return 14
        } else if (widgetSizeStringFormat == "medium") {
            return 13
        } else if (widgetSizeStringFormat == "small") {
            return 12
        } else if (widgetSizeStringFormat == "lockscreen") {
            return 11
        } else {
            return 10
        }
        
    } else if (widgetSizeStringFormat == nil && widgetSizeSystemFormat != nil) {
        if (widgetSizeSystemFormat == .systemLarge) {
            return 14
        } else if (widgetSizeSystemFormat == .systemMedium) {
            return 13
        } else if (widgetSizeSystemFormat == .systemSmall) {
            return 12
        } else if (widgetSizeSystemFormat == .accessoryRectangular) {
            return 11
        } else {
            return 10
        }
    } else {
        return 11
    }
    
}

public func getStopNameFontSizeForWidgetSize(widgetSizeSystemFormat: WidgetFamily?, widgetSizeStringFormat: String?) -> CGFloat {

    if (widgetSizeSystemFormat == nil && widgetSizeStringFormat != nil) {
        if (widgetSizeStringFormat == "large") {
            return 11
        } else if (widgetSizeStringFormat == "medium") {
            return 11
        } else if (widgetSizeStringFormat == "small") {
            return 11
        } else if (widgetSizeStringFormat == "lockscreen") {
            return 11
        } else {
            return 8
        }
        
    } else if (widgetSizeStringFormat == nil && widgetSizeSystemFormat != nil) {
        if (widgetSizeSystemFormat == .systemLarge) {
            return 11
        } else if (widgetSizeSystemFormat == .systemMedium) {
            return 11
        } else if (widgetSizeSystemFormat == .systemSmall) {
            return 11
        } else if (widgetSizeSystemFormat == .accessoryRectangular) {
            return 11
        } else {
            return 8
        }
    } else {
        return 8
    }
    
}



public func getLastSeenFontSizeForWidgetSize(widgetSizeSystemFormat: WidgetFamily?, widgetSizeStringFormat: String?) -> CGFloat {
    if (widgetSizeSystemFormat == nil && widgetSizeStringFormat != nil) {
        if (widgetSizeStringFormat == "large") {
            return 10
        } else if (widgetSizeStringFormat == "medium") {
            return 10
        } else if (widgetSizeStringFormat == "small") {
            return 10
        } else if (widgetSizeStringFormat == "lockscreen") {
            return 10
        } else {
            return 8
        }
        
    } else if (widgetSizeStringFormat == nil && widgetSizeSystemFormat != nil) {
        if (widgetSizeSystemFormat == .systemLarge) {
            return 10
        } else if (widgetSizeSystemFormat == .systemMedium) {
            return 10
        } else if (widgetSizeSystemFormat == .systemSmall) {
            return 10
        } else if (widgetSizeSystemFormat == .accessoryRectangular) {
            return 10
        } else {
            return 8
        }
    } else {
        return 8
    }
    
}


public func getStopNameMaxPrefixLengthForWidget() -> Int {
    return 28
}


public func getWidgetPreviewHeightForSize(widgetSizeSystemFormat: WidgetFamily?, widgetSizeStringFormat: String?) -> CGFloat {
    if (widgetSizeSystemFormat == nil && widgetSizeStringFormat != nil) {
        
        if (widgetSizeStringFormat == "large") {
            return 300
        } else if (widgetSizeStringFormat == "medium") {
            return 170
        } else if (widgetSizeStringFormat == "small") {
            return 170
        } else if (widgetSizeStringFormat == "lockscreen") {
            return 80
        } else {
            return 300
        }
        
    } else if (widgetSizeStringFormat == nil && widgetSizeSystemFormat != nil) {
        if (widgetSizeSystemFormat == .systemLarge) {
            return 300
        } else if (widgetSizeSystemFormat == .systemMedium) {
            return 170
        } else if (widgetSizeSystemFormat == .systemSmall) {
            return 170
        } else if (widgetSizeSystemFormat == .accessoryRectangular) {
            return 80
        } else {
            return 300
        }
    } else {
        return 300
    }
}

public func getWidgetPreviewRowHeightForSize(widgetSizeSystemFormat: WidgetFamily?, widgetSizeStringFormat: String?) -> CGFloat {
    if (widgetSizeSystemFormat == nil && widgetSizeStringFormat != nil) {
        
        if (widgetSizeStringFormat == "large") {
            return 380
        } else if (widgetSizeStringFormat == "medium") {
            return 180
        } else if (widgetSizeStringFormat == "small") {
            return 180
        } else if (widgetSizeStringFormat == "lockscreen") {
            return 100
        } else {
            return 380
        }
        
    } else if (widgetSizeStringFormat == nil && widgetSizeSystemFormat != nil) {
        if (widgetSizeSystemFormat == .systemLarge) {
            return 380
        } else if (widgetSizeSystemFormat == .systemMedium) {
            return 180
        } else if (widgetSizeSystemFormat == .systemSmall) {
            return 180
        } else if (widgetSizeSystemFormat == .accessoryRectangular) {
            return 100
        } else {
            return 380
        }
    } else {
        return 380
    }
}

public func getWidgetPreviewWidthForSize(widgetSizeSystemFormat: WidgetFamily?, widgetSizeStringFormat: String?) -> CGFloat {
    if (widgetSizeSystemFormat == nil && widgetSizeStringFormat != nil) {
        if (widgetSizeStringFormat == "large") {
            return .infinity
        } else if (widgetSizeStringFormat == "medium") {
            return .infinity
        } else if (widgetSizeStringFormat == "small") {
            return 170
        } else if (widgetSizeStringFormat == "lockscreen") {
            return 170
        } else {
            return .infinity
        }
        
    } else if (widgetSizeStringFormat == nil && widgetSizeSystemFormat != nil) {
        if (widgetSizeSystemFormat == .systemLarge) {
            return .infinity
        } else if (widgetSizeSystemFormat == .systemMedium) {
            return .infinity
        } else if (widgetSizeSystemFormat == .systemSmall) {
            return 170
        } else if (widgetSizeSystemFormat == .accessoryRectangular) {
            return 170
        } else {
            return .infinity
        }
    } else {
        return .infinity
    }
}

public func getScheduleStringSeparator() -> String {
    return " ---- "
}

public func getCompositKeyLinkerForDictionaries() -> String {
    return "-"
}

public func getWidgetTextPlaceholder() -> String {
    return "TBD"
}


public func getLateStatusTextString() -> String {
    return "LATE"
}

public func getEarlyStatusTextString() -> String {
    return "EARLY"
}

public func getCancelledStatusTextString() -> String {
    return "CANCELLED"
}

public func getOKStatusTextString() -> String {
    return "OK"
}

public func getDueStatusTextString() -> String {
    return "DUE"
}

public enum DefaultTab: Int, CaseIterable, Identifiable {
    case map = 0
    case stops = 1
    case saved = 2
    case widgets = 3
    case more = 4
    
    public var id: Int { self.rawValue }
    
    public var name: String {
        switch self {
        case .map: return "Map"
        case .stops: return "Stops"
        case .saved: return "Saved"
        case .widgets: return "Widgets"
        case .more: return "More"
        }
    }
    
    public var icon: String {
        switch self {
        case .map: return "map.fill"
        case .stops: return "list.bullet"
        case .saved: return "bookmark.fill"
        case .widgets: return "note.text"
        case .more: return "ellipsis.circle.fill"
        }
    }
}




public enum StopViewTheme: String, CaseIterable {
    case modern = "Modern"
    case classic = "Classic"
    
    public var id: String { self.rawValue }
    
    static var `default`: StopViewTheme {
        return .modern
    }
    
    var description: String {
        switch self {
        case .classic:
            return "Always Dark"
        case .modern:
            return "Auto"
        }
    }
    
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .modern:
            return nil
        case .classic:
            return .dark
        }
    }
}

public struct ThemeModifier: ViewModifier {
    let theme: StopViewTheme
    let text: String
    
    public func body(content: Content) -> some View {
        switch theme {
        case .modern:
            content
                .font(.system(size: 14, design: .monospaced).bold())
                .background(Color(.secondarySystemGroupedBackground))
                .foregroundStyle(.primary)
                .foregroundStyle(foregroundColor(for: text))
        case .classic:
            content
                .font(.custom("LCDDot", size: 10)).bold()
                .fontWeight(.black)
                .background(.black)
                .foregroundStyle(Color(hex: "#EB8634", brightness: 150, saturation: 150))
                //.shadow(color: Color(hex: "#EB8634", brightness: 2).opacity(0.5), radius: 4)
        }
    }
    
    private func foregroundColor(for text: String) -> Color {
        if text.contains(getLateStatusTextString()) || text.contains(getCancelledStatusTextString()) {
            return .red
        } else if text.contains(getEarlyStatusTextString()) {
            return .blue
        }
        return .primary
    }
}

public extension View {
    func stopViewTheme(_ theme: StopViewTheme, text: String) -> some View {
        modifier(ThemeModifier(theme: theme, text: text))
    }
}

extension Color {
    init(hex: String, brightness: Double = 1.0, saturation: Double = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        let uiColor = UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1.0)

        let adjustedColor = uiColor.adjustBrightness(brightness).adjustSaturation(saturation)

        self.init(uiColor: adjustedColor)
    }
}

extension UIColor {
    func adjustBrightness(_ factor: Double) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            brightness = min(brightness * CGFloat(factor), 1.0)
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
        return self
    }

    func adjustSaturation(_ factor: Double) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            saturation = min(saturation * CGFloat(factor), 1.0)
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
        return self
    }
}


public let settingsUserDefaultsKeys = (
    defaultTab: "default_tab_preference",
    stopViewTheme: "stop_view_theme_preference",
    sharedStopViewTheme: "shared_stop_view_theme"
)


public struct WidgetThemeModifier: ViewModifier {
    let theme: StopViewTheme
    let text: String
    let widgetSize: WidgetFamily
    
    public func body(content: Content) -> some View {
        switch theme {
        case .modern:
            content
                .font(.system(size: getFontSize(), design: .monospaced).bold())
                .background(Color(widgetSize == .accessoryRectangular ? .clear : .secondarySystemGroupedBackground))
                .foregroundStyle(.primary)
                .foregroundStyle(foregroundColor(for: text))
        case .classic:
            content
                .font(.custom("LCDDot", size: getFontSize())).bold()
                .fontWeight(.black)
                .background(widgetSize == .accessoryRectangular ? .clear : .black)
                .foregroundStyle(Color(hex: "#EB8634", brightness: 150, saturation: 150))
        }
    }
    
    private func getFontSize() -> CGFloat {
        var baseFontSize = getNormalFontSizeForWidgetSize(widgetSizeSystemFormat: widgetSize, widgetSizeStringFormat: nil)
        
        if theme == .classic {
            baseFontSize = baseFontSize - 4
        }
        
        if text.contains(getLateStatusTextString()) ||
           text.contains(getEarlyStatusTextString()) ||
           text.contains(getCancelledStatusTextString()) {
            return baseFontSize - 2
        }
        
        if text.lowercased().contains("updated") {
            baseFontSize = getLastSeenFontSizeForWidgetSize(widgetSizeSystemFormat: widgetSize, widgetSizeStringFormat: nil)
            
            if (theme == .classic) {
                baseFontSize = baseFontSize - 2
            }
        }
        
        if text.lowercased().contains("stop") {
            baseFontSize = getStopNameFontSizeForWidgetSize(widgetSizeSystemFormat: widgetSize, widgetSizeStringFormat: nil)
            
            if (theme == .classic) {
                baseFontSize = baseFontSize - 4
            }
        }
        

        
        return baseFontSize
    }
    
    private func foregroundColor(for text: String) -> Color {
        if text.contains(getLateStatusTextString()) || text.contains(getCancelledStatusTextString()) {
            return .red
        } else if text.contains(getEarlyStatusTextString()) {
            return .blue
        }
        return .primary
    }
}

public extension View {
    func widgetTheme(_ theme: StopViewTheme, text: String, size: WidgetFamily) -> some View {
        modifier(WidgetThemeModifier(theme: theme, text: text, widgetSize: size))
    }
}


public extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct ConditionalRefreshable: ViewModifier {
    let isEnabled: Bool
    let action: () async -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content.refreshable {
                await action()
            }
        } else {
            content
        }
    }
}


extension CLLocationCoordinate2D: Identifiable {
    public var id: String {
        "\(latitude)\(getCompositKeyLinkerForDictionaries())\(longitude)"
    }
}


extension Bundle {
    var iconFileName: String? {
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconFileName = iconFiles.last
        else { return nil }
        return iconFileName
    }
}


public func getRouteNumberWidth(size: WidgetFamily) -> CGFloat {
    switch size {
    case .systemLarge: return 40
    case .systemMedium: return 35
    case .systemSmall: return 30
    case .accessoryRectangular: return 25
    default: return 30
    }
}

public func getRouteNameWidth(size: WidgetFamily) -> CGFloat {
    switch size {
    case .systemLarge: return 130
    case .systemMedium: return 130
    case .systemSmall: return 70
    case .accessoryRectangular: return 60
    default: return 70
    }
}

public func shouldShowShortRouteName(_ status: String) -> Bool {
    return status == getLateStatusTextString() ||
           status == getEarlyStatusTextString() ||
           status == getCancelledStatusTextString()
}
