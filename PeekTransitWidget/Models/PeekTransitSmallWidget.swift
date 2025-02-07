import SwiftUI
import WidgetKit
import Intents


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
