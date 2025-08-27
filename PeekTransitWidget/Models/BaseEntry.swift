import SwiftUI
import WidgetKit

protocol BaseEntry: TimelineEntry {
    var widgetData: [String: Any]? { get }
    var scheduleData: [String]? { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }  
}
