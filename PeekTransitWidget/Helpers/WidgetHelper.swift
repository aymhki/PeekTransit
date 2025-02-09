import WidgetKit
import SwiftUI
import Intents
import Combine
import Foundation



enum WidgetHelper {
    static func getWidgetFromDefaults(withId id: String) -> WidgetModel? {
        guard let sharedDefaults = SharedDefaults.userDefaults,
              let data = sharedDefaults.data(forKey: SharedDefaults.widgetsKey),
              let savedWidgets = try? JSONDecoder().decode([WidgetModel].self, from: data) else {
            return nil
        }
        
        return savedWidgets.first { $0.id == id }
    }
    
    static func getFilteredStopsForWidget(_ stops: [[String: Any]], maxStops: Int) async -> [[String: Any]] {
        var filteredStops: [[String: Any]] = []
        var seenVariants = Set<String>()
        
        for stop in stops {
            guard let stopNumber = stop["number"] as? Int else {
                continue
            }
            
            do {
                let schedule = try await TransitAPI.shared.getStopSchedule(stopNumber: stopNumber)
                let cleanedSchedule = TransitAPI.shared.cleanStopSchedule(
                    schedule: schedule,
                    timeFormat: .default
                )
                
                var stopVariants = Set<String>()
                for scheduleString in cleanedSchedule {
                    let components = scheduleString.components(separatedBy: " ---- ")
                    if components.count >= 2 {
                        let variantCombo = "\(components[0])-\(components[1])"
                        stopVariants.insert(variantCombo)
                    }
                }
                
                let uniqueVariants = stopVariants.subtracting(seenVariants)
                if !uniqueVariants.isEmpty {
                    filteredStops.append(stop)
                    seenVariants.formUnion(stopVariants)
                    
                    if filteredStops.count >= maxStops {
                        break
                    }
                }
            } catch {
                print("Error fetching schedule for stop \(stopNumber): \(error)")
                continue
            }
        }

        if filteredStops.isEmpty {
            var usedKeys = Set<String>()
            
            for stop in stops {
                guard let direction = stop["direction"] as? String,
                      let street = stop["street"] as? [String: Any],
                      let streetName = street["name"] as? String else {
                    continue
                }
                
                let compositeKey = "\(direction)-\(streetName)"
                
                if !usedKeys.contains(compositeKey) {
                    filteredStops.append(stop)
                    usedKeys.insert(compositeKey)
                    
                    if filteredStops.count >= maxStops {
                        break
                    }
                }
            }
            
            if filteredStops.isEmpty {
                filteredStops = Array(stops.prefix(maxStops))
            }
        }
        
        return filteredStops
    }
    
    static func getScheduleForWidget(_ widgetData: [String: Any], isClosestStop: Bool? = false) async -> ([String]?, [String: Any]) {
        guard let stops = widgetData["stops"] as? [[String: Any]] else {
            return (nil, widgetData)
        }
        
        var schedulesDict: [String: String] = [:]
        var updatedWidgetData = widgetData
        var updatedStops: [[String: Any]] = []
        
        for var stop in stops {
            guard let stopNumber = stop["number"] as? Int else { continue }
            
            do {
                let schedule = try await TransitAPI.shared.getStopSchedule(stopNumber: stopNumber)
                let cleanedSchedule = TransitAPI.shared.cleanStopSchedule(
                    schedule: schedule,
                    timeFormat: widgetData["timeFormat"] as? String == TimeFormat.clockTime.rawValue ? TimeFormat.clockTime : TimeFormat.minutesRemaining
                )
                
                if ((isClosestStop ?? false) || widgetData["noSelectedVariants"] as? Bool == true) {
                    let maxVariants = getMaxVariantsAllowedForWidget(
                        widgetSizeSystemFormat: nil,
                        widgetSizeStringFormat: widgetData["size"] as? String
                    )
                    
                    let maxStops = getMaxSopsAllowedForWidget(
                        widgetSizeSystemFormat: nil,
                        widgetSizeStringFormat: widgetData["size"] as? String
                    )
                    
                    var selectedVariants: [[String: Any]] = []
                    var usedKeys = Set<String>()
                    
                    for scheduleString in cleanedSchedule {
                        let components = scheduleString.components(separatedBy: " ---- ")
                        if components.count >= 2 {
                            let variantKey = components[0]
                            let variantName = components[1]
                            let compositeKey = "\(stopNumber)-\(variantKey)-\(variantName)"
                            
                            if !usedKeys.contains(compositeKey) {
                                selectedVariants.append([
                                    "key": variantKey,
                                    "name": variantName
                                ])
                                usedKeys.insert(compositeKey)
                                schedulesDict[compositeKey] = scheduleString
                                
                                if selectedVariants.count >= (maxVariants * maxStops < 2 ? 2 : maxVariants * maxStops) {
                                    break
                                }
                            }
                        }
                    }
                    
                    stop["selectedVariants"] = selectedVariants
                } else {
                    if let selectedVariants = stop["selectedVariants"] as? [[String: Any]] {
                        for variant in selectedVariants {
                            guard let variantKey = variant["key"] as? String,
                                  let variantName = variant["name"] as? String else {
                                continue
                            }
                            
                            let compositeKey = "\(stopNumber)-\(variantKey)-\(variantName)"
                            if !schedulesDict.keys.contains(compositeKey),
                               let firstMatchingSchedule = cleanedSchedule.first(where: { scheduleString in
                                   let components = scheduleString.components(separatedBy: " ---- ")
                                   return components.count >= 2 &&
                                          components[0] == variantKey &&
                                          components[1] == variantName
                               }) {
                                schedulesDict[compositeKey] = firstMatchingSchedule
                            }
                        }
                    }
                }
            } catch {
                print("Error fetching schedule for stop \(stopNumber): \(error)")
                continue
            }
            
            updatedStops.append(stop)
        }
        
        updatedWidgetData["stops"] = updatedStops
        return (schedulesDict.isEmpty ? nil : Array(schedulesDict.values), updatedWidgetData)
    }
    
    static func createTimeline<T: BaseEntry>(
        currentDate: Date,
        configuration: Any,
        widgetData: [String: Any]?,
        createEntry: @escaping (Date, Any, [String: Any]?, [String]?) -> T
    ) async -> Timeline<T> {

        
        guard let widgetData = widgetData else {
            let entry = createEntry(currentDate, configuration, nil, nil)
            return Timeline(entries: [entry], policy: .atEnd)
        }
        
        let schedule = await getScheduleForWidget(widgetData)
        let entry = createEntry(currentDate, configuration, schedule.1, schedule.0)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    
    
    
    static func getMaxSopsAllowedForWidget(widgetSizeSystemFormat: WidgetFamily?, widgetSizeStringFormat: String?) -> Int {
        return getMaxSopsAllowed(widgetSizeSystemFormat: widgetSizeSystemFormat, widgetSizeStringFormat: widgetSizeStringFormat)
    }
    
    static  func getMaxVariantsAllowedForWidget(widgetSizeSystemFormat: WidgetFamily?, widgetSizeStringFormat: String?) -> Int {
        return getMaxVariantsAllowed(widgetSizeSystemFormat: widgetSizeSystemFormat, widgetSizeStringFormat: widgetSizeStringFormat)
    }
}
