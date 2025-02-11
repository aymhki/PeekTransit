import SwiftUI
import WidgetKit

struct SimpleEntryMedium: BaseEntry {
    let date: Date
    let configuration: ConfigurationMediumIntent
    var widgetData: [String: Any]?
    var scheduleData: [String]?
    let relevance: TimelineEntryRelevance?
    
    init(
        date: Date,
        configuration: ConfigurationMediumIntent,
        widgetData: [String: Any]? = nil,
        scheduleData: [String]? = nil
    ) {
        self.date = date
        self.configuration = configuration
        self.widgetData = widgetData
        self.scheduleData = scheduleData
        self.relevance = TimelineRelevance.createRelevance()
    }
}
