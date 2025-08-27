import SwiftUI
import WidgetKit



struct SimpleEntryLockscreen: BaseEntry {
    let date: Date
    let configuration: ConfigurationLockscreenIntent
    var widgetData: [String: Any]?
    var scheduleData: [String]?
    let relevance: TimelineEntryRelevance?
    var isLoading: Bool
    var errorMessage: String?
    
    init(
        date: Date,
        configuration: ConfigurationLockscreenIntent,
        widgetData: [String: Any]? = nil,
        scheduleData: [String]? = nil,
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) {
        self.date = date
        self.configuration = configuration
        self.widgetData = widgetData
        self.scheduleData = scheduleData
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.relevance = TimelineRelevance.createRelevance()
    }
}
