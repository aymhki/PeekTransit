import WidgetKit

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
    return 10
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
            return 16
        } else if (widgetSizeStringFormat == "medium") {
            return 15
        } else if (widgetSizeStringFormat == "small") {
            return 14
        } else if (widgetSizeStringFormat == "lockscreen") {
            return 13
        } else {
            return 11
        }
        
    } else if (widgetSizeStringFormat == nil && widgetSizeSystemFormat != nil) {
        if (widgetSizeSystemFormat == .systemLarge) {
            return 16
        } else if (widgetSizeSystemFormat == .systemMedium) {
            return 15
        } else if (widgetSizeSystemFormat == .systemSmall) {
            return 14
        } else if (widgetSizeSystemFormat == .accessoryRectangular) {
            return 13
        } else {
            return 11
        }
    } else {
        return 11
    }
    
}


public func getLastSeenFontSizeForWidgetSize(widgetSizeSystemFormat: WidgetFamily?, widgetSizeStringFormat: String?) -> CGFloat {
    if (widgetSizeSystemFormat == nil && widgetSizeStringFormat != nil) {
        if (widgetSizeStringFormat == "large") {
            return 12
        } else if (widgetSizeStringFormat == "medium") {
            return 12
        } else if (widgetSizeStringFormat == "small") {
            return 12
        } else if (widgetSizeStringFormat == "lockscreen") {
            return 12
        } else {
            return 12
        }
        
    } else if (widgetSizeStringFormat == nil && widgetSizeSystemFormat != nil) {
        if (widgetSizeSystemFormat == .systemLarge) {
            return 12
        } else if (widgetSizeSystemFormat == .systemMedium) {
            return 12
        } else if (widgetSizeSystemFormat == .systemSmall) {
            return 12
        } else if (widgetSizeSystemFormat == .accessoryRectangular) {
            return 12
        } else {
            return 12
        }
    } else {
        return 11
    }
    
}


public func getStopNameMaxPrefixLengthForWidget() -> Int {
    return 40
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
