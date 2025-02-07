import SwiftUI
import WidgetKit

struct SimpleEntryMedium: BaseEntry {
    let date: Date
    let configuration: ConfigurationMediumIntent
    var widgetData: [String: Any]?
    var scheduleData: [String]?
}
