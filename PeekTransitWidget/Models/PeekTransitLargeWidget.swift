import SwiftUI
import WidgetKit
import Intents


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
