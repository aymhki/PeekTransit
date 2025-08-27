import SwiftUI
import WidgetKit
import Intents

struct PeekTransitMediumWidget: Widget {
    let kind: String = "PeekTransitMediumWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationMediumIntent.self, provider: ProviderMedium()) { entry in
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
        .configurationDisplayName("Transit Widget - Medium")
        .description("Shows transit schedules in medium size")
        .supportedFamilies([.systemMedium])
        .disableContentMarginsIfNeeded()
    }
}
