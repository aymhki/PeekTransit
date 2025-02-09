import SwiftUI
import SwiftData

@main
struct PeekTransitApp: App {
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared

    
    init() {
        WidgetRefreshManager.shared.startPeriodicRefresh()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    deepLinkHandler.handleURL(url)
            }
        }
    }
}
