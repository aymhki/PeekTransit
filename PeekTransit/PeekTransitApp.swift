import SwiftUI
import SwiftData

@main
struct PeekTransitApp: App {
    
    init() {
        WidgetRefreshManager.shared.startPeriodicRefresh()
    }

    
    var body: some Scene {
        WindowGroup {
   
            ContentView()
            
        }
    }
}
