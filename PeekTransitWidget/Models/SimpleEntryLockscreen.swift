import SwiftUI
import WidgetKit



struct SimpleEntryLockscreen: BaseEntry {
    let date: Date
    let configuration: ConfigurationLockscreenIntent
    var widgetData: [String: Any]?
    var scheduleData: [String]?
}
