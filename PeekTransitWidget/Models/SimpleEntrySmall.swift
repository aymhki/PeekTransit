import SwiftUI
import WidgetKit

struct SimpleEntrySmall: BaseEntry {
    let date: Date
    let configuration: ConfigurationSmallIntent
    var widgetData: [String: Any]?
    var scheduleData: [String]?
}
