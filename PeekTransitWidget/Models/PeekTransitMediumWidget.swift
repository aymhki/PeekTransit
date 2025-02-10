import SwiftUI
import WidgetKit
import Intents

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
