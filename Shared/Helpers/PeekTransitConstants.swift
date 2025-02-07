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
    return 550
}


public func getMaxStopsAllowedToFetch() -> Int {
    return 25
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
    return 8
}


public func getTimePeriodAllowedForNextBusRoutes() -> Int {
    return 6
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
            return 12
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
            return 12
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
            return 10
        } else if (widgetSizeStringFormat == "lockscreen") {
            return 10
        } else {
            return 12
        }
        
    } else if (widgetSizeStringFormat == nil && widgetSizeSystemFormat != nil) {
        if (widgetSizeSystemFormat == .systemLarge) {
            return 12
        } else if (widgetSizeSystemFormat == .systemMedium) {
            return 12
        } else if (widgetSizeSystemFormat == .systemSmall) {
            return 10
        } else if (widgetSizeSystemFormat == .accessoryRectangular) {
            return 10
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
