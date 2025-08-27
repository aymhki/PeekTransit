import WidgetKit
import Foundation

class WidgetUpdateManager {
    static let shared = WidgetUpdateManager()
    private var timer: Timer?
    
    private init() {
        setupTimer()
    }
    
    private func setupTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
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
