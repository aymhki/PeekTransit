import SwiftUI
import SwiftData

@main
struct PeekTransitApp: App {
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared
    @StateObject private var themeManager = ThemeManager.shared


    
    init() {
        WidgetRefreshManager.shared.startPeriodicRefresh()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
                .onOpenURL { url in
                    deepLinkHandler.handleURL(url)
            }
        }
    }
}
