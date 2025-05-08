import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct PeekTransitApp: App {
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared
    @StateObject private var themeManager = ThemeManager.shared
    @AppStorage("hasSeenSplashScreen") private var hasSeenSplashScreen = false
    @State private var showSplashScreen = true  // Start with splash screen shown
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !showSplashScreen {
                    ContentView()
                        .environmentObject(themeManager)
                        .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
                        .onOpenURL { url in
                            deepLinkHandler.handleURL(url)
                        }
                        .transition(.opacity)
                } else {
                    SplashScreenView {
                        if !hasSeenSplashScreen {
                            hasSeenSplashScreen = true
                        }
                        withAnimation {
                            showSplashScreen = false
                        }
                    }
                    .transition(.opacity)
                }
            }
            .onAppear {
                showSplashScreen = !hasSeenSplashScreen
            }
        }
    }
}
