import SwiftUI
import WidgetKit

protocol BaseEntry: TimelineEntry {
    var widgetData: [String: Any]? { get }
    var scheduleData: [String]? { get }
}
