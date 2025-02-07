import SwiftUI
import WidgetKit
import Intents

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

