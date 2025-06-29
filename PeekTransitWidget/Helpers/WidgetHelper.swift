import WidgetKit
import SwiftUI
import Intents
import Combine
import Foundation



enum WidgetHelper {
    static func retryRequest<T>(maxAttempts: Int = 3, operation: () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    // try? await Task.sleep(nanoseconds: UInt64(1_000_000))
                }
            }
        }
        
        throw lastError!
    }
    
    static func getWidgetFromDefaults(withId id: String) -> WidgetModel? {
        guard let sharedDefaults = SharedDefaults.userDefaults,
              let data = sharedDefaults.data(forKey: SharedDefaults.widgetsKey),
              let savedWidgets = try? JSONDecoder().decode([WidgetModel].self, from: data) else {
            return nil
        }
        
        return savedWidgets.first { $0.id == id }
    }
    
    static func getFilteredStopsForWidget(_ stops: [Stop], maxStops: Int, widgetData: [String: Any]?) async -> [Stop] {
        var filteredStops: [Stop] = []
        var seenVariants = Set<String>()
        
        let nearbyStopsDict = Dictionary(uniqueKeysWithValues: stops.compactMap { stop -> (Int, Stop)? in
            guard let number = stop.number as? Int else { return nil }
            return (number, stop)
        })
        
        var preferredVariants = Set<String>()
        if let preferredStops = widgetData?["perferredStops"] as? [Stop] {
            for preferredStop in preferredStops {
                if let selectedVariants = preferredStop.selectedVariants as? [Variant] {
                    for variant in selectedVariants {
                        if let key = variant.key as? String, let name = variant.name as? String {
                            let variantCombo = "\(key)\(getCompositKeyLinkerForDictionaries())\(name)"
                            preferredVariants.insert(variantCombo)
                        }
                    }
                }
            }
        }
        
        if let preferredStops = widgetData?["perferredStops"] as? [Stop] {
            for preferredStop in preferredStops {
                if filteredStops.count >= maxStops {
                    break
                }
                
                guard let preferredStopNumber = preferredStop.number as? Int,
                      var matchingNearbyStop = nearbyStopsDict[preferredStopNumber] else {
                    continue
                }
                
                do {
                    matchingNearbyStop = preferredStop
                    
                    let schedule = try await retryRequest {
                        try await TransitAPI.shared.getStopSchedule(stopNumber: preferredStopNumber)
                    }
                    
                    let cleanedSchedule = TransitAPI.shared.cleanStopSchedule(
                        schedule: schedule,
                        timeFormat: .default
                    )
                    
                    var stopVariants = Set<String>()
                    for scheduleString in cleanedSchedule {
                        let components = scheduleString.components(separatedBy: getScheduleStringSeparator())
                        if components.count >= 2 {
                            let variantCombo = "\(components[0])\(getCompositKeyLinkerForDictionaries())\(components[1])"
                            stopVariants.insert(variantCombo)
                        }
                    }
                    
                    let uniqueVariants = stopVariants.subtracting(seenVariants)
                    if !uniqueVariants.isEmpty {
                        filteredStops.append(matchingNearbyStop)
                        seenVariants.formUnion(stopVariants)
                    }
                } catch {
                    print("Error fetching schedule for preferred stop \(preferredStopNumber): \(error)")
                    continue
                }
            }
        }
        
        if filteredStops.count < maxStops && !preferredVariants.isEmpty {
            let processedStopNumbers = Set(filteredStops.compactMap { $0.number })
            
            for stop in stops {
                guard let stopNumber = stop.number as? Int else { continue }
                
                if processedStopNumbers.contains(stopNumber) {
                    continue
                }
                
                do {
                    let schedule = try await retryRequest {
                        try await TransitAPI.shared.getStopSchedule(stopNumber: stopNumber)
                    }
                    
                    let cleanedSchedule = TransitAPI.shared.cleanStopSchedule(
                        schedule: schedule,
                        timeFormat: .default
                    )
                    
                    var stopVariants = Set<String>()
                    for scheduleString in cleanedSchedule {
                        let components = scheduleString.components(separatedBy: getScheduleStringSeparator())
                        if components.count >= 2 {
                            let variantCombo = "\(components[0])\(getCompositKeyLinkerForDictionaries())\(components[1])"
                            stopVariants.insert(variantCombo)
                        }
                    }
                    
                    let matchingPreferredVariants = stopVariants.intersection(preferredVariants)
                    if !matchingPreferredVariants.isEmpty {
                        var updatedStop = stop
                        var selectedVariants: [Variant] = []
                        
                        for variantCombo in matchingPreferredVariants {
                            let components = variantCombo.components(separatedBy: getCompositKeyLinkerForDictionaries())
                            if components.count == 2 {
                                selectedVariants.append(Variant(from:[
                                    "key": components[0],
                                    "name": components[1]
                                ]))
                            }
                        }
                        
                        updatedStop.selectedVariants = selectedVariants
                        filteredStops.append(updatedStop)
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
        }
        
        if filteredStops.count < maxStops {
            let processedStopNumbers = Set(filteredStops.compactMap { $0.number })
            
            for stop in stops {
                guard let stopNumber = stop.number as? Int else { continue }
                
                if processedStopNumbers.contains(stopNumber) {
                    continue
                }
                
                do {
                    let schedule = try await retryRequest {
                        try await TransitAPI.shared.getStopSchedule(stopNumber: stopNumber)
                    }
                    
                    let cleanedSchedule = TransitAPI.shared.cleanStopSchedule(
                        schedule: schedule,
                        timeFormat: .default
                    )
                    
                    var stopVariants = Set<String>()
                    for scheduleString in cleanedSchedule {
                        let components = scheduleString.components(separatedBy: getScheduleStringSeparator())
                        if components.count >= 2 {
                            let variantCombo = "\(components[0])\(getCompositKeyLinkerForDictionaries())\(components[1])"
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
        }
        
        if filteredStops.isEmpty {
            var usedKeys = Set<String>()
            
            for stop in stops {
                guard let direction = stop.direction as? String,
                      let street = stop.street as? Street,
                      let streetName = street.name as? String else {
                    continue
                }
                
                let compositeKey = "\(direction)\(getCompositKeyLinkerForDictionaries())\(streetName)"
                
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
        guard let stops = widgetData["stops"] as? [Stop] else {
            return (nil, widgetData)
        }
        
        let multipleEntriesPerVariant = widgetData["multipleEntriesPerVariant"] as? Bool ?? true
        var schedulesArray: [String] = []
        var updatedWidgetData = widgetData
        var updatedStops: [Stop] = []
        var cleanedSchedule: [String] = []
        var maxVariants = 0
        var maxStops = 0
        var currentStop = 0
        
        if (multipleEntriesPerVariant) {
            maxVariants = getMaxVariantsAllowedForMultipleEntries(
                widgetSizeSystemFormat: nil,
                widgetSizeStringFormat: widgetData["size"] as? String
            )
            
            maxStops = getMaxSopsAllowedForMultipleEntries(
                widgetSizeSystemFormat: nil,
                widgetSizeStringFormat: widgetData["size"] as? String
            )
        } else {
            maxVariants = getMaxVariantsAllowedForWidget(
                widgetSizeSystemFormat: nil,
                widgetSizeStringFormat: widgetData["size"] as? String
            )
            
            maxStops = getMaxSopsAllowedForWidget(
                widgetSizeSystemFormat: nil,
                widgetSizeStringFormat: widgetData["size"] as? String
            )
        }
        
        for var stop in stops {
            
            if currentStop < maxStops {
                
                currentStop = currentStop + 1
                guard let stopNumber = stop.number as? Int else { continue }
                
                do {
                    let schedule = try await retryRequest {
                        try await TransitAPI.shared.getStopSchedule(stopNumber: stopNumber)
                    }
                    
                    if (multipleEntriesPerVariant) {
                        cleanedSchedule = TransitAPI.shared.cleanScheduleMixedTimeFormat(schedule: schedule)
                    } else {
                        cleanedSchedule = TransitAPI.shared.cleanStopSchedule(
                            schedule: schedule,
                            timeFormat: widgetData["timeFormat"] as? String == TimeFormat.clockTime.formattedValue ? TimeFormat.clockTime : TimeFormat.minutesRemaining
                        )
                    }
                    
                    if ( ( isClosestStop ?? false && widgetData["selectedPerferredStopsInClosestStops"] as? Bool == false  ) || widgetData["noSelectedVariants"] as? Bool == true || stop.selectedVariants == nil || (stop.selectedVariants as? [Variant])?.isEmpty == true ) {
                        
                        var selectedVariants: [Variant] = []
                        var processedVariants = Set<String>()
                        
                        for scheduleString in cleanedSchedule {
                            let components = scheduleString.components(separatedBy: getScheduleStringSeparator())
                            if components.count >= 2 {
                                let variantKey = components[0]
                                let variantName = components[1]
                                let variantIdentifier = "\(variantKey)\(getCompositKeyLinkerForDictionaries())\(variantName)"
                                
                                if !processedVariants.contains(variantIdentifier) {
                                    let variantEntries = cleanedSchedule.filter { entry in
                                        let entryComponents = entry.components(separatedBy: getScheduleStringSeparator())
                                        return entryComponents.count >= 2 &&
                                        entryComponents[0] == variantKey &&
                                        entryComponents[1] == variantName
                                    }
                                    
                                    
                                    let entriesToAdd = multipleEntriesPerVariant ? Array(variantEntries.prefix(2)) : [variantEntries[0]]
                                    schedulesArray.append(contentsOf: entriesToAdd)
                                    
                                    selectedVariants.append(Variant(from:[
                                        "key": variantKey,
                                        "name": variantName
                                    ]))
                                    processedVariants.insert(variantIdentifier)
                                    
                                    if selectedVariants.count >= maxVariants {
                                        break
                                    }
                                }
                            }
                        }
                        
                        stop.selectedVariants = selectedVariants
                    } else {
                        if let selectedVariants = stop.selectedVariants as? [Variant] {
                            for variant in selectedVariants {
                                guard let variantKey = variant.key as? String,
                                      let variantName = variant.name as? String else {
                                    continue
                                }
                                
                                let matchingSchedules = cleanedSchedule.filter { scheduleString in
                                    let components = scheduleString.components(separatedBy: getScheduleStringSeparator())
                                    return components.count >= 2 &&
                                    components[0] == variantKey &&
                                    components[1] == variantName
                                }
                                
                                if multipleEntriesPerVariant {
                                    schedulesArray.append(contentsOf: Array(matchingSchedules.prefix(2)))
                                } else if let firstMatch = matchingSchedules.first {
                                    schedulesArray.append(firstMatch)
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
            
        }
        
        updatedWidgetData["stops"] = updatedStops
        return (schedulesArray.isEmpty ? nil : schedulesArray, updatedWidgetData)
    }
    
    static func createTimeline<T: BaseEntry>(
        widgetId: String?,
        currentDate: Date,
        configuration: Any,
        widgetData: [String: Any]?,
        createEntry: @escaping (Date, Any, [String: Any]?, [String]?) -> T
    ) async -> Timeline<T> {
        let nextUpdate = Calendar.current.date(byAdding: .second, value: getRefreshWidgetTimelineAfterHowManySeconds(), to: currentDate)!

        
        guard let widgetData = widgetData else {
            let entry = createEntry(currentDate, configuration, nil, nil)
            return Timeline(entries: [entry], policy: .after(nextUpdate))
        }
        
        let schedule = await getScheduleForWidget(widgetData)
        
        if let widgetId = widgetId, let finalScheduleDataToCache = schedule.0,  !finalScheduleDataToCache.isEmpty, !schedule.1.isEmpty {
            cacheEntry(id: widgetId, widgetData: schedule.1, scheduleData: finalScheduleDataToCache, lastUpdatedTime: currentDate)
        }
        
        let entry = createEntry(currentDate, configuration, schedule.1, schedule.0)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    static func getCachedEntry(forId id: String) -> ([String: Any]?, [String]?, Date?)? {
        do {
            guard let sharedDefaults = SharedDefaults.userDefaults else { return nil }
            
            var cachedWidgetData: [String: Any]? = nil
            if let data = sharedDefaults.data(forKey: "widget_cache_data_\(id)") {
                do {
                    let codableDict = try JSONDecoder().decode([String: AnyCodable].self, from: data)
                    cachedWidgetData = codableDict.mapValues { $0.value }
                } catch {
                    print("Failed to decode cached widget data: \(error)")
                }
            }
            
            let cachedScheduleData = sharedDefaults.array(forKey: "widget_cache_schedule_\(id)") as? [String]
            let cachedUpdatedAt = sharedDefaults.object(forKey: "widget_cache_updated_time_\(id)") as? Date
            
            return (cachedWidgetData, cachedScheduleData, cachedUpdatedAt)
        } catch {
            print("Failed to get cached entry: \(error)")
            return nil
        }
    }

    static func cacheEntry(id: String, widgetData: [String: Any], scheduleData: [String], lastUpdatedTime: Date?) {
        do {
            guard let sharedDefaults = SharedDefaults.userDefaults else { return }
            
            do {
                let codableDict = widgetData.mapValues { AnyCodable($0) }
                let data = try JSONEncoder().encode(codableDict)
                sharedDefaults.set(data, forKey: "widget_cache_data_\(id)")
            } catch {
                print("Failed to cache widget data: \(error)")
                return
            }
            
            sharedDefaults.set(scheduleData, forKey: "widget_cache_schedule_\(id)")
            
            if let lastUpdatedTime = lastUpdatedTime {
                sharedDefaults.set(lastUpdatedTime, forKey: "widget_cache_updated_time_\(id)")
            } else {
                sharedDefaults.set(Date(), forKey: "widget_cache_updated_time_\(id)")
            }
        } catch {
            print("Failed to cache entry: \(error)")
        }
    }
    
    
    
    static func getMaxSopsAllowedForWidget(widgetSizeSystemFormat: WidgetFamily?, widgetSizeStringFormat: String?) -> Int {
        return getMaxSopsAllowed(widgetSizeSystemFormat: widgetSizeSystemFormat, widgetSizeStringFormat: widgetSizeStringFormat)
    }
    
    static  func getMaxVariantsAllowedForWidget(widgetSizeSystemFormat: WidgetFamily?, widgetSizeStringFormat: String?) -> Int {
        return getMaxVariantsAllowed(widgetSizeSystemFormat: widgetSizeSystemFormat, widgetSizeStringFormat: widgetSizeStringFormat)
    }
}
