import WidgetKit
import SwiftUI
import Intents
import Combine
import Foundation

struct Provider: IntentTimelineProvider {

    typealias Entry = SimpleEntry
    
    typealias Intent = ConfigurationIntent
    
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
            var entries: [SimpleEntry] = []

            // Generate a timeline consisting of five entries an hour apart, starting from the current date.
            let currentDate = Date()
            for hourOffset in 0 ..< 5 {
                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                let entry = SimpleEntry(date: entryDate, configuration: configuration)
                entries.append(entry)
            }
            
        let timeLineEntry = Timeline(entries: entries, policy: .never)
            completion(timeLineEntry)
        }
    
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

struct PeekTransitWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Text(entry.date, style: .time)
        //Text (entry.configuration.widgetName ?? "No Value Entered")
    }
}

@main
struct PeekTransitWidget: Widget {
    let kind: String = "PeekTransitWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            PeekTransitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Example 1")
        .description("Example 2")
        .supportedFamilies([.systemMedium])
    }
}

