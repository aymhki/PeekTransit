import WidgetKit
import SwiftUI
import CoreLocation

struct Provider: TimelineProvider {
    typealias Entry = WidgetEntry

    let api = TransitAPI()
    let locationManager = CLLocationManager()
    
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), config: .placeholder, scheduleData: ["BLUE": "5 min"])
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        let entry = WidgetEntry(date: Date(), config: .placeholder, scheduleData: ["BLUE": "5 min"])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let configs = SharedWidgetData.shared.loadWidgets()
        let currentDate = Date()
        
        // Fetch data for all widgets
        Task {
            var entries: [WidgetEntry] = []
            
            for config in configs {
                var scheduleData = [String: String]() // [variantKey: arrivalText]
                
                do {
                    if config.type == .dynamicLocation {
                        guard let location = locationManager.location else { continue }
                        let stops = try await api.getNearbyStops(userLocation: location)
                        let nearestStop = stops.first
                        if let stopNumber = nearestStop?["number"] as? Int {
                            let schedule = try await api.getStopSchedule(stopNumber: stopNumber)
                            let cleaned = api.cleanStopSchedule(schedule: schedule)
                            scheduleData = processSchedule(cleaned, variants: config.selectedVariants)
                        }
                    } else {
                        if let stopNumber = config.stopNumber {
                            let schedule = try await api.getStopSchedule(stopNumber: stopNumber)
                            let cleaned = api.cleanStopSchedule(schedule: schedule)
                            scheduleData = processSchedule(cleaned, variants: config.selectedVariants)
                        }
                    }
                } catch {
                    scheduleData = ["error": error.localizedDescription]
                }
                
                let entry = WidgetEntry(
                    date: currentDate,
                    config: config,
                    scheduleData: scheduleData
                )
                entries.append(entry)
            }
            
            let timeline = Timeline(entries: entries, policy: .after(Date().addingTimeInterval(300))) // 5 min
            completion(timeline)
        }
    }
    
    private func processSchedule(_ schedule: [String], variants: [String]) -> [String: String] {
        var result = [String: String]()
        
        for entry in schedule {
            let components = entry.components(separatedBy: " ---- ")
            guard components.count >= 4,
                  variants.contains(components[0]) else { continue }
            
            let variantKey = components[0]
            let arrivalText = components[3]
            
            // Keep only the closest arrival time per variant
            if result[variantKey] == nil {
                result[variantKey] = arrivalText
            }
        }
        
        return result
    }
}

struct WidgetEntry: TimelineEntry {
    let date: Date
    let config: WidgetConfig
    let scheduleData: [String: String]
}

struct PeekTransitWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        switch entry.config.size {
        case .small:
            SmallWidgetView(entry: entry)
        case .medium:
            MediumWidgetView(entry: entry)
        case .large:
            LargeWidgetView(entry: entry)
        case .lockscreen:
            LockScreenWidgetView(entry: entry)
        }
    }
}

struct PeekTransitWidget: Widget {
    let kind: String = "PeekTransitWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider()
        ) { entry in
            PeekTransitWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Bus Times")
        .description("Live bus arrival information")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular
        ])
    }
}
