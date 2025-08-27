import SwiftUI
import WidgetKit
import Intents


struct PeekTransitLargeWidget: Widget {
    let kind: String = "PeekTransitLargeWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationLargeIntent.self, provider: ProviderLarge()) { entry in
            Group {
                ZStack {
                    
                    Color(.secondarySystemGroupedBackground).edgesIgnoringSafeArea(.all)
                    
                    ContainerRelativeShape()
                        .stroke(Color(UIColor.separator), lineWidth: 3)
                        .ignoresSafeArea(.all)

                    
                    PeekTransitWidgetEntryView(entry: entry)
                    
                }
                    
            }
            .widgetBackground(backgroundView: Group {Color(.secondarySystemGroupedBackground)})
        }
        .configurationDisplayName("Transit Widget - Large")
        .description("Shows transit schedules in large size")
        .supportedFamilies([.systemLarge])
        .disableContentMarginsIfNeeded()
        
    }
}
