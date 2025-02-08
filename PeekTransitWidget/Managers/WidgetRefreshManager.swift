import WidgetKit
import SwiftUI

class WidgetRefreshManager {
    static let shared = WidgetRefreshManager()
    private var timer: Timer?
    
    func startPeriodicRefresh() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func stopPeriodicRefresh() {
        timer?.invalidate()
        timer = nil
    }
}

