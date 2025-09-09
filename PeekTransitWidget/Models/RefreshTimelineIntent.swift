import AppIntents
import WidgetKit


@available(iOS 17.0, *)
struct RefreshTimelineIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Widget"
    
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
