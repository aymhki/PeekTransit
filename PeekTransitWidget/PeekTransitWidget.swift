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
    
    static func getScheduleForWidget(_ widgetData: [String: Any]) async -> [String]? {
        guard let stops = widgetData["stops"] as? [[String: Any]] else {
            return nil
        }
        
        var schedulesDict: [String: String] = [:]
        
        for stop in stops {
            guard let stopNumber = stop["number"] as? Int,
                  let selectedVariants = stop["selectedVariants"] as? [[String: Any]] else {
                continue
            }
            
            do {
                let schedule = try await TransitAPI.shared.getStopSchedule(stopNumber: stopNumber)
                let cleanedSchedule = TransitAPI.shared.cleanStopSchedule(schedule: schedule, timeFormat: widgetData["timeFormat"] as? String == TimeFormat.clockTime.rawValue ? TimeFormat.clockTime : TimeFormat.minutesRemaining ?? TimeFormat.default)
                
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
            } catch {
                print("Error fetching schedule for stop \(stopNumber): \(error)")
            }
        }
        

        return schedulesDict.isEmpty ? nil : Array(schedulesDict.values)
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
        let entry = createEntry(currentDate, configuration, widgetData, schedule)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
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
                let schedule = await WidgetHelper.getScheduleForWidget(widget.widgetData)
                completion(SimpleEntrySmall(date: Date(), configuration: configuration, widgetData: widget.widgetData, scheduleData: schedule))
            } else {
                completion(SimpleEntrySmall(date: Date(), configuration: configuration))
            }
        }
    }
    
    func getTimeline(for configuration: ConfigurationSmallIntent, in context: Context, completion: @escaping (Timeline<SimpleEntrySmall>) -> Void) {
        Task {
            let widgetId = configuration.widgetConfig?.identifier
            let widget = widgetId.flatMap { WidgetHelper.getWidgetFromDefaults(withId: $0) }
            
            let timeline = await WidgetHelper.createTimeline(
                currentDate: Date(),
                configuration: configuration,
                widgetData: widget?.widgetData
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
                let schedule = await WidgetHelper.getScheduleForWidget(widget.widgetData)
                completion(SimpleEntryMedium(date: Date(), configuration: configuration, widgetData: widget.widgetData, scheduleData: schedule))
            } else {
                completion(SimpleEntryMedium(date: Date(), configuration: configuration))
            }
        }
    }
    
    func getTimeline(for configuration: ConfigurationMediumIntent, in context: Context, completion: @escaping (Timeline<SimpleEntryMedium>) -> Void) {
        Task {
            let widgetId = configuration.widgetConfig?.identifier
            let widget = widgetId.flatMap { WidgetHelper.getWidgetFromDefaults(withId: $0) }
            
            let timeline = await WidgetHelper.createTimeline(
                currentDate: Date(),
                configuration: configuration,
                widgetData: widget?.widgetData
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
                let schedule = await WidgetHelper.getScheduleForWidget(widget.widgetData)
                completion(SimpleEntryLarge(date: Date(), configuration: configuration, widgetData: widget.widgetData, scheduleData: schedule))
            } else {
                completion(SimpleEntryLarge(date: Date(), configuration: configuration))
            }
        }
    }
    
    func getTimeline(for configuration: ConfigurationLargeIntent, in context: Context, completion: @escaping (Timeline<SimpleEntryLarge>) -> Void) {
        Task {
            let widgetId = configuration.widgetConfig?.identifier
            let widget = widgetId.flatMap { WidgetHelper.getWidgetFromDefaults(withId: $0) }
            
            let timeline = await WidgetHelper.createTimeline(
                currentDate: Date(),
                configuration: configuration,
                widgetData: widget?.widgetData
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
                let schedule = await WidgetHelper.getScheduleForWidget(widget.widgetData)
                completion(SimpleEntryLockscreen(date: Date(), configuration: configuration, widgetData: widget.widgetData, scheduleData: schedule))
            } else {
                completion(SimpleEntryLockscreen(date: Date(), configuration: configuration))
            }
        }
    }
    
    func getTimeline(for configuration: ConfigurationLockscreenIntent, in context: Context, completion: @escaping (Timeline<SimpleEntryLockscreen>) -> Void) {
        Task {
            let widgetId = configuration.widgetConfig?.identifier
            let widget = widgetId.flatMap { WidgetHelper.getWidgetFromDefaults(withId: $0) }
            
            let timeline = await WidgetHelper.createTimeline(
                currentDate: Date(),
                configuration: configuration,
                widgetData: widget?.widgetData
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
    
    var body: some View {
        if let widgetData = entry.widgetData {
            DynamicWidgetView(
                widgetData: widgetData,
                scheduleData: entry.scheduleData,
                size: family,
                updatedAt: entry.date
            )
        } else {
            Text("Select a widget configuration")
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


