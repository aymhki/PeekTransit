import SwiftUI
import WidgetKit

enum PreviewHelper {
    static func generatePreviewSchedule(from widgetData: [String: Any], noConfig: Bool, timeFormat: TimeFormat, showLastUpdatedStatus: Bool, multipleEntriesPerVariant: Bool, showLateTextStatus: Bool) -> ([String]?, [String: Any]?)? {
        var previewSchedules: [String] = []
        var updatedWidgetData: [String: Any] = widgetData
        let timeFormatTextToUse = timeFormat.brief
        let useLateText = timeFormat == TimeFormat.minutesRemaining ? true : false
        let stringToUseBasedOnTimeFormat = ( (useLateText || multipleEntriesPerVariant) && showLateTextStatus ) ? getLateStatusTextString() : getOKStatusTextString()
        
        if (!noConfig) {
            if (widgetData["isClosestStop"] as? Bool == false) {
                guard let stops = widgetData["stops"] as? [Stop] else { return nil }
                
                for stop in stops {
                    if (widgetData["noSelectedVariants"] as? Bool == false) {
                        if let variants = stop.selectedVariants as? [Variant] {
                            for variant in variants {
                                if let key = variant.key as? String,
                                   let name = variant.name as? String {
                                    
                                    if (multipleEntriesPerVariant) {
                                        previewSchedules.append("\(key)\(getScheduleStringSeparator())\(name)\(getScheduleStringSeparator())\(stringToUseBasedOnTimeFormat)\(getScheduleStringSeparator())\(TimeFormat.minutesRemaining.brief)")
                                        previewSchedules.append("\(key)\(getScheduleStringSeparator())\(name)\(getScheduleStringSeparator())\(getOKStatusTextString())\(getScheduleStringSeparator())\(TimeFormat.clockTime.brief)")
                                    } else {
                                        previewSchedules.append("\(key)\(getScheduleStringSeparator())\(name)\(getScheduleStringSeparator())\(stringToUseBasedOnTimeFormat)\(getScheduleStringSeparator())\(timeFormatTextToUse)")
                                    }
                                }
                            }
                        }
                    } else {
                        let widgetSize = widgetData["size"] as? String ?? "medium"
                        var maxVariants = 0
                        
                        if (multipleEntriesPerVariant) {
                            maxVariants = getMaxVariantsAllowedForMultipleEntries(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
                           
                        } else {
                            maxVariants = getMaxVariantsAllowed(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
                        }
                        
                        var selectedVariants: [Variant] = []
                        for _ in 0..<maxVariants {
                            let variant: Variant = Variant(from:[
                                "key": getWidgetTextPlaceholder(),
                                "name": getWidgetTextPlaceholder()
                            ])
                            selectedVariants.append(variant)
                            if (multipleEntriesPerVariant) {
                                previewSchedules.append("\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(stringToUseBasedOnTimeFormat)\(getScheduleStringSeparator())\(TimeFormat.minutesRemaining.brief)")
                                previewSchedules.append("\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getOKStatusTextString())\(getScheduleStringSeparator())\(TimeFormat.clockTime.brief)")
                            } else {
                                previewSchedules.append("\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(stringToUseBasedOnTimeFormat)\(getScheduleStringSeparator())\(timeFormatTextToUse)")
                            }
                        }
                        
                        var updatedStop = stop
                        updatedStop.selectedVariants = selectedVariants
                        
                        if var updatedStops = updatedWidgetData["stops"] as? [Stop],
                           let stopIndex = updatedStops.firstIndex(where: { ($0.number) == (stop.number) }) {
                            updatedStops[stopIndex] = updatedStop
                            updatedWidgetData["stops"] = updatedStops
                        }
                    }
                }
            } else {
                let widgetSize = widgetData["size"] as? String ?? "medium"
                var maxStops = 0
                var maxVariants = 0

                
                if (multipleEntriesPerVariant) {
                    maxStops = getMaxSopsAllowedForMultipleEntries(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
                } else {
                    maxStops = getMaxSopsAllowed(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
                }
                
                
                if (multipleEntriesPerVariant) {
                    maxVariants = getMaxVariantsAllowedForMultipleEntries(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
                } else {
                    maxVariants = getMaxVariantsAllowed(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
                }
                
                var generatedStops: [Stop] = []
                
                for stopIndex in 0..<maxStops {
                    var selectedVariants: [Variant] = []
                    
                    for _ in 0..<maxVariants {
                        let variant: Variant = Variant(from: [
                            "key": getWidgetTextPlaceholder(),
                            "name": getWidgetTextPlaceholder()
                        ])
                        selectedVariants.append(variant)
                        if (multipleEntriesPerVariant) {
                            previewSchedules.append("\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(stringToUseBasedOnTimeFormat)\(getScheduleStringSeparator())\(TimeFormat.minutesRemaining.brief)")
                            previewSchedules.append("\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getOKStatusTextString())\(getScheduleStringSeparator())\(TimeFormat.clockTime.brief)")
                        } else {
                            previewSchedules.append("\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(stringToUseBasedOnTimeFormat)\(getScheduleStringSeparator())\(timeFormatTextToUse)")
                        }
                    }
                    
                    let stop: Stop = Stop(from:[
                        "id": "preview_stop_\(stopIndex)",
                        "name": getWidgetTextPlaceholder(),
                        "number": getWidgetTextPlaceholder(),
                        "selectedVariants": selectedVariants
                    ])
                    
                    generatedStops.append(stop)
                }
                
                updatedWidgetData["stops"] = generatedStops
            }
        } else {
            let widgetSize = widgetData["size"] as? String ?? "medium"
            var maxStops = 0
            var maxVariants = 0

            
            if (multipleEntriesPerVariant) {
                maxStops = getMaxSopsAllowedForMultipleEntries(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
            } else {
                maxStops = getMaxSopsAllowed(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
            }
            
            
            if (multipleEntriesPerVariant) {
                maxVariants = getMaxVariantsAllowedForMultipleEntries(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
            } else {
                maxVariants = getMaxVariantsAllowed(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
            }
            
            var generatedStops: [Stop] = []
            
            for stopIndex in 0..<maxStops {
                var selectedVariants: [Variant] = []
                
                for _ in 0..<maxVariants {
                    let variant: Variant = Variant(from: [
                        "key": getWidgetTextPlaceholder(),
                        "name": getWidgetTextPlaceholder()
                    ])
                    selectedVariants.append(variant)
                    if (multipleEntriesPerVariant) {
                        previewSchedules.append("\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(stringToUseBasedOnTimeFormat)\(getScheduleStringSeparator())\(TimeFormat.minutesRemaining.brief)")
                        previewSchedules.append("\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getOKStatusTextString())\(getScheduleStringSeparator())\(TimeFormat.clockTime.brief)")
                    } else {
                        previewSchedules.append("\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(getWidgetTextPlaceholder())\(getScheduleStringSeparator())\(stringToUseBasedOnTimeFormat)\(getScheduleStringSeparator())\(timeFormatTextToUse)")
                    }
                }
                
                let stop: Stop = Stop(from: [
                    "id": "preview_stop_\(stopIndex)",
                    "name": getWidgetTextPlaceholder(),
                    "number": getWidgetTextPlaceholder(),
                    "selectedVariants": selectedVariants
                ])
                
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
