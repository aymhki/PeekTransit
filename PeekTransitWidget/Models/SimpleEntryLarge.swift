import SwiftUI
import WidgetKit

struct SimpleEntryLarge: BaseEntry {
    let date: Date
    let configuration: ConfigurationLargeIntent
    var widgetData: [String: Any]?
    var scheduleData: [String]?
}
