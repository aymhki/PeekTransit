// Widget Extension/PeekTransitWidget.swift
import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    typealias Entry = WidgetEntry
    
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), widgetData: [:], scheduleData: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let entry = WidgetEntry(date: Date(), widgetData: [:], scheduleData: [])
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            var entries: [WidgetEntry] = []
            let currentDate = Date()
            
            if let sharedDefaults = SharedDefaults.userDefaults,
               let data = sharedDefaults.data(forKey: SharedDefaults.widgetsKey),
               let widgets = try? JSONDecoder().decode([WidgetModel].self, from: data) {
                
                // Find widgets matching the current family
                let matchingWidgets = widgets.filter { ($0.widgetData["size"] as? String) == context.family.description }
                
                for widget in matchingWidgets {
                    var schedules: [String] = []
                    
                    if let isClosestStop = widget.widgetData["isClosestStop"] as? Bool {
                        if isClosestStop {
                            // TODO: Implement closest stop logic
                            schedules = []
                        } else if let stops = widget.widgetData["stops"] as? [[String: Any]] {
                            for stop in stops {
                                if let stopNumber = stop["number"] as? Int {
                                    do {
                                        let schedule = try await TransitAPI.shared.getStopSchedule(stopNumber: stopNumber)
                                        let cleanedSchedules = TransitAPI.shared.cleanStopSchedule(schedule: schedule)
                                        schedules.append(contentsOf: cleanedSchedules)
                                    } catch {
                                        print("Error fetching schedule: \(error)")
                                    }
                                }
                            }
                        }
                    }
                    
                    let entry = WidgetEntry(
                        date: currentDate,
                        widgetData: widget.widgetData,
                        scheduleData: schedules
                    )
                    entries.append(entry)
                }
            }
            
            if entries.isEmpty {
                entries.append(WidgetEntry(date: currentDate, widgetData: [:], scheduleData: []))
            }
            
            let timeline = Timeline(entries: entries, policy: .after(currentDate.addingTimeInterval(20)))
            completion(timeline)
        }
    }
}

// Add this extension to map WidgetFamily to description
extension WidgetFamily {
    var description: String {
        switch self {
        case .systemSmall: return "small"
        case .systemMedium: return "medium"
        case .systemLarge: return "large"
        case .accessoryRectangular: return "lockscreen"
        default: return "unknown"
        }
    }
}

struct WidgetEntry: TimelineEntry {
    let date: Date
    let widgetData: [String: Any]
    let scheduleData: [String]
}


struct PeekTransitWidget: Widget {
    private let kind = "PeekTransit_Widget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PeekTransitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("PeekTransit")
        .description("View your bus schedules")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    }
}

struct PeekTransitWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(widgetData: entry.widgetData, scheduleData: entry.scheduleData)
        case .systemMedium:
            MediumWidgetView(widgetData: entry.widgetData, scheduleData: entry.scheduleData)
        case .systemLarge:
            LargeWidgetView(widgetData: entry.widgetData, scheduleData: entry.scheduleData)
        case .accessoryRectangular:
            LockScreenWidgetView(widgetData: entry.widgetData, scheduleData: entry.scheduleData)
        default:
            EmptyView()
        }
    }
}
