import WidgetKit
import Foundation

class WidgetUpdateManager {
    static let shared = WidgetUpdateManager()
    private var timer: Timer?
    
    private init() {
        setupTimer()
    }
    
    private func setupTimer() {
        // Invalidate existing timer if any
        timer?.invalidate()
        
        // Create a new timer that fires every minute
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refreshWidgets()
        }
    }
    
    func refreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    deinit {
        timer?.invalidate()
    }
}
