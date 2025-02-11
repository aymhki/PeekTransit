import SwiftUI
import WidgetKit

struct SimpleEntrySmall: BaseEntry {
    let date: Date
    let configuration: ConfigurationSmallIntent
    var widgetData: [String: Any]?
    var scheduleData: [String]?
    let relevance: TimelineEntryRelevance? 
    
    init(
        date: Date,
        configuration: ConfigurationSmallIntent,
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
