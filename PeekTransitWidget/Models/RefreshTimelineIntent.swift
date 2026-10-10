import AppIntents
import WidgetKit
import Foundation


struct WidgetRefreshState {
    
    private static func requestedKey(_ id: String) -> String {
        return "widget_refresh_requested_\(id)"
    }
    
    private static func completedKey(_ id: String) -> String {
        return "widget_refresh_completed_\(id)"
    }
    
    static func requestedAt(_ id: String) -> Date? {
        return SharedDefaults.userDefaults?.object(forKey: requestedKey(id)) as? Date
    }
    
    static func completedAt(_ id: String) -> Date? {
        return SharedDefaults.userDefaults?.object(forKey: completedKey(id)) as? Date
    }
    
    static func isPending(_ id: String, now: Date = Date()) -> Bool {
        guard let requested = requestedAt(id) else { return false }
        
        if now.timeIntervalSince(requested) >= getRefreshButtonPendingTimeoutSeconds() {
            return false
        }
        
        guard let completed = completedAt(id) else { return true }
        
        return completed < requested
    }
    
    static func cooldownEnd(_ id: String) -> Date? {
        return requestedAt(id)?.addingTimeInterval(getRefreshButtonCooldownSeconds())
    }
    
    static func isCoolingDown(_ id: String, now: Date = Date()) -> Bool {
        guard let end = cooldownEnd(id) else { return false }
        
        return now < end
    }
    
    @discardableResult
    static func requestRefresh(_ id: String, now: Date = Date()) -> Bool {
        guard !isPending(id, now: now), !isCoolingDown(id, now: now) else { return false }
        guard let defaults = SharedDefaults.userDefaults else { return false }
        
        defaults.set(now, forKey: requestedKey(id))
        defaults.removeObject(forKey: completedKey(id))
        
        return true
    }
    
    static func markCompletedIfPending(_ id: String, now: Date = Date()) {
        guard isPending(id, now: now) else { return }
        
        SharedDefaults.userDefaults?.set(now, forKey: completedKey(id))
    }
}


@available(iOS 17.0, *)
struct RefreshTimelineIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Widget"
    
    @Parameter(title: "Widget Id")
    var widgetId: String
    
    init() {
        self.widgetId = ""
    }
    
    init(widgetId: String) {
        self.widgetId = widgetId
    }
    
    func perform() async throws -> some IntentResult {
        if !widgetId.isEmpty {
            WidgetRefreshState.requestRefresh(widgetId)
        }
        
        return .result()
    }
}
