import WidgetKit
import SwiftUI
import Intents
import Combine
import Foundation

protocol BaseEntry: TimelineEntry {
    var widgetData: [String: Any]? { get }
    var scheduleData: [String]? { get }
}

struct SimpleEntrySmall: BaseEntry {
    let date: Date
    let configuration: ConfigurationSmallIntent
    var widgetData: [String: Any]?
    var scheduleData: [String]?
}

struct SimpleEntryMedium: BaseEntry {
    let date: Date
    let configuration: ConfigurationMediumIntent
    var widgetData: [String: Any]?
    var scheduleData: [String]?
}

struct SimpleEntryLarge: BaseEntry {
    let date: Date
    let configuration: ConfigurationLargeIntent
    var widgetData: [String: Any]?
    var scheduleData: [String]?
}

struct SimpleEntryLockscreen: BaseEntry {
    let date: Date
    let configuration: ConfigurationLockscreenIntent
    var widgetData: [String: Any]?
    var scheduleData: [String]?
}

enum WidgetHelper {
    static func getWidgetFromDefaults(withId id: String) -> WidgetModel? {
        guard let sharedDefaults = SharedDefaults.userDefaults,
              let data = sharedDefaults.data(forKey: SharedDefaults.widgetsKey),
              let savedWidgets = try? JSONDecoder().decode([WidgetModel].self, from: data) else {
            return nil
        }
        
        Task {
            try? await Task.sleep(for: .seconds(60))
            WidgetCenter.shared.reloadAllTimelines()
        }
        return savedWidgets.first { $0.id == id }
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
                
                if isClosestStop ?? false {
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
                            let compositeKey = "\(variantKey)-\(variantName)"
                            
                            if !usedKeys.contains(compositeKey) {
                                selectedVariants.append([
                                    "key": variantKey,
                                    "name": variantName
                                ])
                                usedKeys.insert(compositeKey)
                                schedulesDict[compositeKey] = scheduleString
                                
                                if selectedVariants.count >= (maxVariants * maxStops) {
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
                            
                            let compositeKey = "\(variantKey)-\(variantName)"
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


struct ProviderSmall: IntentTimelineProvider {
    typealias Entry = SimpleEntrySmall
    
    func placeholder(in context: Context) -> SimpleEntrySmall {
        SimpleEntrySmall(date: Date(), configuration: ConfigurationSmallIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationSmallIntent, in context: Context, completion: @escaping (SimpleEntrySmall) -> Void) {
        Task {
            if let widgetId = configuration.widgetConfig?.identifier,
               let widget = WidgetHelper.getWidgetFromDefaults(withId: widgetId) {
                
                var finalWidgetData = widget.widgetData
                
                if widget.widgetData["isClosestStop"] as? Bool == true {
                    if let location = await LocationManager.shared.getCurrentLocation() {
                        let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: true)
                        if let stops = nearbyStops, !stops.isEmpty {
                            let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                                widgetSizeSystemFormat: .systemSmall,
                                widgetSizeStringFormat: nil
                            )
                            finalWidgetData["stops"] = Array(stops.prefix(maxStops))
                            let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData, isClosestStop: true)
                            finalWidgetData = updatedWidgetData
                            
                            completion(SimpleEntrySmall(
                                date: Date(),
                                configuration: configuration,
                                widgetData: finalWidgetData,
                                scheduleData: schedule
                            ))
                        } else {
                            finalWidgetData["noStopsFound"] = true
                            completion(SimpleEntrySmall(
                                date: Date(),
                                configuration: configuration,
                                widgetData: finalWidgetData,
                                scheduleData: nil
                            ))
                        }
                    }
                } else {
                    let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData)
                    completion(SimpleEntrySmall(
                        date: Date(),
                        configuration: configuration,
                        widgetData: updatedWidgetData,
                        scheduleData: schedule
                    ))
                }
            } else {
                completion(SimpleEntrySmall(date: Date(), configuration: configuration))
            }
        }
    }
    
    func getTimeline(for configuration: ConfigurationSmallIntent, in context: Context, completion: @escaping (Timeline<SimpleEntrySmall>) -> Void) {
        Task {
            let widgetId = configuration.widgetConfig?.identifier
            let widget = widgetId.flatMap { WidgetHelper.getWidgetFromDefaults(withId: $0) }
            var widgetData = widget?.widgetData
            
            if widget?.widgetData["isClosestStop"] as? Bool == true {
                if let location = await LocationManager.shared.getCurrentLocation() {
                    let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: true)
                    if let stops = nearbyStops, !stops.isEmpty {
                        let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                            widgetSizeSystemFormat: .systemSmall,
                            widgetSizeStringFormat: nil
                        )
                        widgetData?["stops"] = Array(stops.prefix(maxStops))
                        let (_, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(widgetData ?? [:], isClosestStop: true)
                        widgetData = updatedWidgetData
                    } else {
                        widgetData?["noStopsFound"] = true
                    }
                }
            }
            
            let timeline = await WidgetHelper.createTimeline(
                currentDate: Date(),
                configuration: configuration,
                widgetData: widgetData
            ) { date, config, data, schedule in
                SimpleEntrySmall(
                    date: date,
                    configuration: config as! ConfigurationSmallIntent,
                    widgetData: data,
                    scheduleData: schedule
                )
            }
            
            completion(timeline)
        }
    }
}


struct ProviderMedium: IntentTimelineProvider {
    typealias Entry = SimpleEntryMedium
    
    func placeholder(in context: Context) -> SimpleEntryMedium {
        SimpleEntryMedium(date: Date(), configuration: ConfigurationMediumIntent())
    }
    
    
    func getSnapshot(for configuration: ConfigurationMediumIntent, in context: Context, completion: @escaping (SimpleEntryMedium) -> Void) {
        Task {
            if let widgetId = configuration.widgetConfig?.identifier,
               let widget = WidgetHelper.getWidgetFromDefaults(withId: widgetId) {
                
                var finalWidgetData = widget.widgetData
                
                if widget.widgetData["isClosestStop"] as? Bool == true {
                    if let location = await LocationManager.shared.getCurrentLocation() {
                        let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: true)
                        if let stops = nearbyStops, !stops.isEmpty {
                            let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                                widgetSizeSystemFormat: .systemMedium,
                                widgetSizeStringFormat: nil
                            )
                            finalWidgetData["stops"] = Array(stops.prefix(maxStops))
                            let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData, isClosestStop: true)
                            finalWidgetData = updatedWidgetData
                            
                            completion(SimpleEntryMedium(
                                date: Date(),
                                configuration: configuration,
                                widgetData: finalWidgetData,
                                scheduleData: schedule
                            ))
                        } else {
                            finalWidgetData["noStopsFound"] = true
                            completion(SimpleEntryMedium(
                                date: Date(),
                                configuration: configuration,
                                widgetData: finalWidgetData,
                                scheduleData: nil
                            ))
                        }
                    }
                } else {
                    let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData)
                    completion(SimpleEntryMedium(
                        date: Date(),
                        configuration: configuration,
                        widgetData: updatedWidgetData,
                        scheduleData: schedule
                    ))
                }
            } else {
                completion(SimpleEntryMedium(date: Date(), configuration: configuration))
            }
        }
    }
    
    func getTimeline(for configuration: ConfigurationMediumIntent, in context: Context, completion: @escaping (Timeline<SimpleEntryMedium>) -> Void) {
        Task {
            let widgetId = configuration.widgetConfig?.identifier
            let widget = widgetId.flatMap { WidgetHelper.getWidgetFromDefaults(withId: $0) }
            var widgetData = widget?.widgetData
            
            if widget?.widgetData["isClosestStop"] as? Bool == true {
                if let location = await LocationManager.shared.getCurrentLocation() {
                    let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: true)
                    if let stops = nearbyStops, !stops.isEmpty {
                        let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                            widgetSizeSystemFormat: .systemMedium,
                            widgetSizeStringFormat: nil
                        )
                        widgetData?["stops"] = Array(stops.prefix(maxStops))
                        let (_, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(widgetData ?? [:], isClosestStop: true)
                        widgetData = updatedWidgetData
                    } else {
                        widgetData?["noStopsFound"] = true
                    }
                }
            }
            
            let timeline = await WidgetHelper.createTimeline(
                currentDate: Date(),
                configuration: configuration,
                widgetData: widgetData
            ) { date, config, data, schedule in
                SimpleEntryMedium(
                    date: date,
                    configuration: config as! ConfigurationMediumIntent,
                    widgetData: data,
                    scheduleData: schedule
                )
            }
            
            completion(timeline)
        }
    }
}

struct ProviderLarge: IntentTimelineProvider {
    typealias Entry = SimpleEntryLarge
    
    func placeholder(in context: Context) -> SimpleEntryLarge {
        SimpleEntryLarge(date: Date(), configuration: ConfigurationLargeIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationLargeIntent, in context: Context, completion: @escaping (SimpleEntryLarge) -> Void) {
        Task {
            if let widgetId = configuration.widgetConfig?.identifier,
               let widget = WidgetHelper.getWidgetFromDefaults(withId: widgetId) {
                
                var finalWidgetData = widget.widgetData
                
                if widget.widgetData["isClosestStop"] as? Bool == true {
                    if let location = await LocationManager.shared.getCurrentLocation() {
                        let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: true)
                        if let stops = nearbyStops, !stops.isEmpty {
                            let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                                widgetSizeSystemFormat: .systemLarge,
                                widgetSizeStringFormat: nil
                            )
                            finalWidgetData["stops"] = Array(stops.prefix(maxStops))
                            let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData, isClosestStop: true)
                            finalWidgetData = updatedWidgetData
                            
                            completion(SimpleEntryLarge(
                                date: Date(),
                                configuration: configuration,
                                widgetData: finalWidgetData,
                                scheduleData: schedule
                            ))
                        } else {
                            finalWidgetData["noStopsFound"] = true
                            completion(SimpleEntryLarge(
                                date: Date(),
                                configuration: configuration,
                                widgetData: finalWidgetData,
                                scheduleData: nil
                            ))
                        }
                    }
                } else {
                    let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData)
                    completion(SimpleEntryLarge(
                        date: Date(),
                        configuration: configuration,
                        widgetData: updatedWidgetData,
                        scheduleData: schedule
                    ))
                }
            } else {
                completion(SimpleEntryLarge(date: Date(), configuration: configuration))
            }
        }
    }
    
    func getTimeline(for configuration: ConfigurationLargeIntent, in context: Context, completion: @escaping (Timeline<SimpleEntryLarge>) -> Void) {
        Task {
            let widgetId = configuration.widgetConfig?.identifier
            let widget = widgetId.flatMap { WidgetHelper.getWidgetFromDefaults(withId: $0) }
            var widgetData = widget?.widgetData
            
            if widget?.widgetData["isClosestStop"] as? Bool == true {
                if let location = await LocationManager.shared.getCurrentLocation() {
                    let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: true)
                    if let stops = nearbyStops, !stops.isEmpty {
                        let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                            widgetSizeSystemFormat: .systemLarge,
                            widgetSizeStringFormat: nil
                        )
                        widgetData?["stops"] = Array(stops.prefix(maxStops))
                        let (_, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(widgetData ?? [:], isClosestStop: true)
                        widgetData = updatedWidgetData
                    } else {
                        widgetData?["noStopsFound"] = true
                    }
                }
            }
            
            let timeline = await WidgetHelper.createTimeline(
                currentDate: Date(),
                configuration: configuration,
                widgetData: widgetData
            ) { date, config, data, schedule in
                SimpleEntryLarge(
                    date: date,
                    configuration: config as! ConfigurationLargeIntent,
                    widgetData: data,
                    scheduleData: schedule
                )
            }
            
            completion(timeline)
        }
    }
}

struct ProviderLockscreen: IntentTimelineProvider {
    typealias Entry = SimpleEntryLockscreen
    
    func placeholder(in context: Context) -> SimpleEntryLockscreen {
        SimpleEntryLockscreen(date: Date(), configuration: ConfigurationLockscreenIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationLockscreenIntent, in context: Context, completion: @escaping (SimpleEntryLockscreen) -> Void) {
        Task {
            if let widgetId = configuration.widgetConfig?.identifier,
               let widget = WidgetHelper.getWidgetFromDefaults(withId: widgetId) {
                
                var finalWidgetData = widget.widgetData
                
                if widget.widgetData["isClosestStop"] as? Bool == true {
                    if let location = await LocationManager.shared.getCurrentLocation() {
                        let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: true)
                        if let stops = nearbyStops, !stops.isEmpty {
                            let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                                widgetSizeSystemFormat: .accessoryRectangular,
                                widgetSizeStringFormat: nil
                            )
                            finalWidgetData["stops"] = Array(stops.prefix(maxStops))
                            let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData, isClosestStop: true)
                            finalWidgetData = updatedWidgetData
                            
                            completion(SimpleEntryLockscreen(
                                date: Date(),
                                configuration: configuration,
                                widgetData: finalWidgetData,
                                scheduleData: schedule
                            ))
                        } else {
                            finalWidgetData["noStopsFound"] = true
                            completion(SimpleEntryLockscreen(
                                date: Date(),
                                configuration: configuration,
                                widgetData: finalWidgetData,
                                scheduleData: nil
                            ))
                        }
                    }
                } else {
                    let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData)
                    completion(SimpleEntryLockscreen(
                        date: Date(),
                        configuration: configuration,
                        widgetData: updatedWidgetData,
                        scheduleData: schedule
                    ))
                }
            } else {
                completion(SimpleEntryLockscreen(date: Date(), configuration: configuration))
            }
        }
    }
    
    func getTimeline(for configuration: ConfigurationLockscreenIntent, in context: Context, completion: @escaping (Timeline<SimpleEntryLockscreen>) -> Void) {
        Task {
            let widgetId = configuration.widgetConfig?.identifier
            let widget = widgetId.flatMap { WidgetHelper.getWidgetFromDefaults(withId: $0) }
            var widgetData = widget?.widgetData
            
            if widget?.widgetData["isClosestStop"] as? Bool == true {
                if let location = await LocationManager.shared.getCurrentLocation() {
                    let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: true)
                    if let stops = nearbyStops, !stops.isEmpty {
                        let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                            widgetSizeSystemFormat: .accessoryRectangular,
                            widgetSizeStringFormat: nil
                        )
                        widgetData?["stops"] = Array(stops.prefix(maxStops))
                        let (_, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(widgetData ?? [:], isClosestStop: true)
                        widgetData = updatedWidgetData
                    } else {
                        widgetData?["noStopsFound"] = true
                    }
                }
            }
            
            let timeline = await WidgetHelper.createTimeline(
                currentDate: Date(),
                configuration: configuration,
                widgetData: widgetData
            ) { date, config, data, schedule in
                SimpleEntryLockscreen(
                    date: date,
                    configuration: config as! ConfigurationLockscreenIntent,
                    widgetData: data,
                    scheduleData: schedule
                )
            }
            
            completion(timeline)
        }
    }
}

struct PeekTransitWidgetEntryView<T: BaseEntry>: View {
    var entry: T
    @Environment(\.widgetFamily) var family
    
    private func isWidgetFullyLoaded(widgetData: [String: Any], scheduleData: [String]?) -> Bool {
        let scheduleDataSize = scheduleData?.count ?? 0
        var totalNumberOfVariantsInStops = 0
        let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(widgetSizeSystemFormat: family, widgetSizeStringFormat: nil)
        
        if scheduleDataSize > 0 {
            if let widgetStops = widgetData["stops"] as? [[String: Any]] {
                for stopIndex in widgetStops.prefix(maxStops).indices {
                    let stop = widgetStops[stopIndex]
                    
                    let variants = stop["selectedVariants"]
                    
                    totalNumberOfVariantsInStops += (variants as? [[String: Any]])?.count ?? 0
                }
            }
        }
        
        return (scheduleDataSize >= totalNumberOfVariantsInStops)
    }
    
    private func AreAllSelectedVariantsInScheduleData(widgetData: [String: Any], scheduleData: [String]?) -> Bool {
        let scheduleDataSize = scheduleData?.count ?? 0
        var selectedVariantsSimplified: Set<String> = []
        var availableScheduleVariantsSimplified: Set<String> = []
        
        if scheduleDataSize > 0 {
            if let widgetStops = widgetData["stops"] as? [[String: Any]] {
                for stopIndex in widgetStops.indices {
                    let stop = widgetStops[stopIndex]
                    
                    let variants = stop["selectedVariants"]
                    
                    for variant in variants as? [[String: Any]] ?? [] {
                        guard let variantKey = variant["key"] as? String,
                              let variantName = variant["name"] as? String else {
                            continue
                        }
                        
                        selectedVariantsSimplified.insert("\(variantKey)-\(variantName)")
                    }
                }
            }
            
            for scheduleString in scheduleData ?? [] {
                let components = scheduleString.components(separatedBy: " ---- ")
                if components.count >= 2 {
                    let variantKey = components[0]
                    let variantName = components[1]
                    availableScheduleVariantsSimplified.insert("\(variantKey)-\(variantName)")
                }
            }
            
            return selectedVariantsSimplified.isSubset(of: availableScheduleVariantsSimplified)
        }
        
        
        
        return false
    }
    
    private func getFilledScheduleData(widgetData: [String: Any], scheduleData: [String]?) -> [String]? {
                
        if AreAllSelectedVariantsInScheduleData(widgetData: widgetData, scheduleData: scheduleData) {
            return scheduleData
        }
        
        var filledScheduleData: [String] = scheduleData ?? []
        var selectedVariantsSimplified: Set<String> = []
        var availableScheduleVariantsSimplified: Set<String> = []

        if let widgetStops = widgetData["stops"] as? [[String: Any]] {
            for stopIndex in widgetStops.indices {
                let stop = widgetStops[stopIndex]
                
                let variants = stop["selectedVariants"]
                
                for variant in variants as? [[String: Any]] ?? [] {
                    guard let variantKey = variant["key"] as? String,
                          let variantName = variant["name"] as? String else {
                        continue
                    }
                    
                    selectedVariantsSimplified.insert("\(variantKey)-\(variantName)")
                }
            }
        }

        for scheduleString in scheduleData ?? [] {
            let components = scheduleString.components(separatedBy: " ---- ")
            if components.count >= 2 {
                let variantKey = components[0]
                let variantName = components[1]
                availableScheduleVariantsSimplified.insert("\(variantKey)-\(variantName)")
            }
        }

        for selectedVariant in selectedVariantsSimplified {
            if !availableScheduleVariantsSimplified.contains(selectedVariant) {
                let components = selectedVariant.components(separatedBy: "-")
                if components.count >= 2 {
                    filledScheduleData.append("\(components[0]) ---- \(components[1]) ---- Ok ---- \(getTimePeriodAllowedForNextBusRoutes())hrs+")
                }
            }
        }
        
        
        
        return filledScheduleData
        
    }
    
    var body: some View {
        if let widgetData = entry.widgetData {
           let filledScheduleData = getFilledScheduleData(widgetData: widgetData, scheduleData: entry.scheduleData)
                
            
            
            if widgetData["noStopsFound"] as? Bool == true {
                
                if (family != .accessoryRectangular) {
                    Text("Could not fetch nearby bus stops \(String(format: "(within %.0fm)", getStopsDistanceRadius())), please wait a few minutes or move closer to a bus stop.")
                        .foregroundColor(.red)
                        .font(.system(.caption))
                        .padding(.horizontal)
                } else {
                    Text("Could not nearby fetch stops \(String(format: "(%.0fm)", getStopsDistanceRadius())), please wait...")
                        .foregroundColor(.red)
                        .font(.system(.caption))
                        .padding(.horizontal)
                }
                    
                    
            } else if (isWidgetFullyLoaded(widgetData: widgetData, scheduleData: filledScheduleData))  {
                DynamicWidgetView(
                    widgetData: widgetData,
                    scheduleData: filledScheduleData,
                    size: family,
                    updatedAt: entry.date,
                    fullyLoaded: true
                )
            } else {
                DynamicWidgetView(
                    widgetData: widgetData,
                    scheduleData: filledScheduleData,
                    size: family,
                    updatedAt: entry.date,
                    fullyLoaded: false
                )
            }
        } else {
            Text("Select the widget configuration to start")
                .foregroundColor(.blue)
                .font(.system(.caption))
                .padding(.horizontal)
        }
    }
    
}

struct PeekTransitSmallWidget: Widget {
    let kind: String = "PeekTransitSmallWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationSmallIntent.self, provider: ProviderSmall()) { entry in
            PeekTransitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Transit Widget - Small")
        .description("Shows transit schedules in small size")
        .supportedFamilies([.systemSmall])
    }
}

struct PeekTransitMediumWidget: Widget {
    let kind: String = "PeekTransitMediumWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationMediumIntent.self, provider: ProviderMedium()) { entry in
            PeekTransitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Transit Widget - Medium")
        .description("Shows transit schedules in medium size")
        .supportedFamilies([.systemMedium])
    }
}

struct PeekTransitLargeWidget: Widget {
    let kind: String = "PeekTransitLargeWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationLargeIntent.self, provider: ProviderLarge()) { entry in
            PeekTransitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Transit Widget - Large")
        .description("Shows transit schedules in large size")
        .supportedFamilies([.systemLarge])
    }
}

struct PeekTransitLockscreenWidget: Widget {
    let kind: String = "PeekTransitLockscreenWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationLockscreenIntent.self, provider: ProviderLockscreen()) { entry in
            PeekTransitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Transit Widget - Lock Screen")
        .description("Shows transit schedules on lock screen")
        .supportedFamilies([.accessoryRectangular])
    }
}

@main
struct PeekTransitWidgetBundle: WidgetBundle {
    var body: some Widget {
        PeekTransitSmallWidget()
        PeekTransitMediumWidget()
        PeekTransitLargeWidget()
        PeekTransitLockscreenWidget()
    }
}


