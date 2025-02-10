import SwiftUI
import WidgetKit
import SwiftUI
import WidgetKit

enum PreviewHelper {
    static func generatePreviewSchedule(from widgetData: [String: Any], noConfig: Bool, timeFormat: TimeFormat, showLastUpdatedStatus: Bool) -> ([String]?, [String: Any]?)? {
        var previewSchedules: [String] = []
        var updatedWidgetData: [String: Any] = widgetData
        let timeFormatTextToUse = timeFormat.brief
        
        if (!noConfig) {
            if (widgetData["isClosestStop"] as? Bool == false) {
                guard let stops = widgetData["stops"] as? [[String: Any]] else { return nil }
                
                for stop in stops {
                    if (widgetData["noSelectedVariants"] as? Bool == false) {
                        if let variants = stop["selectedVariants"] as? [[String: Any]] {
                            for variant in variants {
                                if let key = variant["key"] as? String,
                                   let name = variant["name"] as? String {
                                    previewSchedules.append("\(key)\(getScheduleStringSeparator())\(name)\(getScheduleStringSeparator())\(getOKStatusTextString())\(getScheduleStringSeparator())\(timeFormatTextToUse)")
                                }
                            }
                        }
                    } else {
                        let widgetSize = widgetData["size"] as? String ?? "medium"
                        let maxVariants = getMaxVariantsAllowed(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
                        
                        var selectedVariants: [[String: Any]] = []
                        for _ in 0..<maxVariants {
                            let variant: [String: Any] = [
                                "key": getWidgetTextPlaceholder(),
                                "name": getWidgetTextPlaceholder()
                            ]
                            selectedVariants.append(variant)
                            previewSchedules.append("\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getOKStatusTextString())\(getScheduleStringSeparator())\(timeFormatTextToUse)")
                        }
                        
                        var updatedStop = stop
                        updatedStop["selectedVariants"] = selectedVariants
                        
                        if var updatedStops = updatedWidgetData["stops"] as? [[String: Any]],
                           let stopIndex = updatedStops.firstIndex(where: { ($0["number"] as? Int) == (stop["number"] as? Int) }) {
                            updatedStops[stopIndex] = updatedStop
                            updatedWidgetData["stops"] = updatedStops
                        }
                    }
                }
            } else {
                let widgetSize = widgetData["size"] as? String ?? "medium"
                let maxStops = getMaxSopsAllowed(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
                let maxVariants = getMaxVariantsAllowed(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
                
                var generatedStops: [[String: Any]] = []
                
                for stopIndex in 0..<maxStops {
                    var selectedVariants: [[String: Any]] = []
                    
                    for _ in 0..<maxVariants {
                        let variant: [String: Any] = [
                            "key": getWidgetTextPlaceholder(),
                            "name": getWidgetTextPlaceholder()
                        ]
                        selectedVariants.append(variant)
                        previewSchedules.append("\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getOKStatusTextString())\(getScheduleStringSeparator())\(timeFormatTextToUse)")
                    }
                    
                    let stop: [String: Any] = [
                        "id": "preview_stop_\(stopIndex)",
                        "name": getWidgetTextPlaceholder(),
                        "number": Int.random(in: 1000...9999),
                        "selectedVariants": selectedVariants
                    ]
                    
                    generatedStops.append(stop)
                }
                
                updatedWidgetData["stops"] = generatedStops
            }
        } else {
            let widgetSize = widgetData["size"] as? String ?? "medium"
            let maxStops = getMaxSopsAllowed(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
            let maxVariants = getMaxVariantsAllowed(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
            
            var generatedStops: [[String: Any]] = []
            
            for stopIndex in 0..<maxStops {
                var selectedVariants: [[String: Any]] = []
                
                for _ in 0..<maxVariants {
                    let variant: [String: Any] = [
                        "key": getWidgetTextPlaceholder(),
                        "name": getWidgetTextPlaceholder()
                    ]
                    selectedVariants.append(variant)
                    previewSchedules.append("\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getOKStatusTextString())\(getScheduleStringSeparator())\(timeFormatTextToUse)")
                }
                
                let stop: [String: Any] = [
                    "id": "preview_stop_\(stopIndex)",
                    "name": getWidgetTextPlaceholder(),
                    "number": Int.random(in: 1000...9999),
                    "selectedVariants": selectedVariants
                ]
                
                generatedStops.append(stop)
            }
            
            updatedWidgetData["stops"] = generatedStops
            updatedWidgetData["isClosestStop"] = true
            updatedWidgetData["noSelectedVariants"] = false
        }
        
        updatedWidgetData["showLastUpdatedStatus"] = showLastUpdatedStatus
        
        
        return (previewSchedules.isEmpty ? nil : previewSchedules, updatedWidgetData)
    }
    
    static func getWidgetSize(from sizeString: String) -> WidgetFamily {
        switch sizeString.lowercased() {
        case "small":
            return .systemSmall
        case "large":
            return .systemLarge
        case "lockscreen":
            return .accessoryRectangular
        default:
            return .systemMedium
        }
    }
}
