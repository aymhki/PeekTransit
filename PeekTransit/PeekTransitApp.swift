import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct PeekTransitApp: App {
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared
    @StateObject private var themeManager = ThemeManager.shared
    @AppStorage("hasSeenSplashScreen") private var hasSeenSplashScreen = false
    @State private var showSplashScreen = true
    @State private var isInitialized = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isInitialized {
                    if showSplashScreen {
                        SplashScreenView {
                            if !hasSeenSplashScreen {
                                hasSeenSplashScreen = true
                            }
                            withAnimation {
                                showSplashScreen = false
                            }
                        }
                        .transition(.opacity)
                    } else {
                        ContentView()
                            .environmentObject(themeManager)
                            .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
                            .onOpenURL { url in
                                deepLinkHandler.handleURL(url)
                            }
                            .transition(.opacity)
                    }
                } else {
                    Color.clear
                }
            }
            .onAppear {
                showSplashScreen = !hasSeenSplashScreen
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isInitialized = true
                }
            }
        }
    }
}
