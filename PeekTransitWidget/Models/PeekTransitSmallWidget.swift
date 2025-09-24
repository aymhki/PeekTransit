import SwiftUI
import WidgetKit
import Intents


struct PeekTransitSmallWidget: Widget {
    let kind: String = "PeekTransitSmallWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationSmallIntent.self, provider: ProviderSmall()) { entry in
            Group {
                ZStack {
                                        
                    ContainerRelativeShape()
                        .stroke(Color(UIColor.separator), lineWidth: 3)
                        .ignoresSafeArea(.all)

                    
                    PeekTransitWidgetEntryView(entry: entry)
                    
                }
                    
            }
            .widgetBackground(backgroundView: Group {Color(.secondarySystemGroupedBackground)})
        }
        .configurationDisplayName("Transit Widget - Small")
        .description("Shows transit schedules in small size")
        .supportedFamilies([.systemSmall])
        .disableContentMarginsIfNeeded()
    
    }
    
}
