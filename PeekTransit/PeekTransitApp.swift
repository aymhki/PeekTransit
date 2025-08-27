import SwiftUI
import CoreLocation
import SwiftData
import BackgroundTasks



@main
struct PeekTransitApp: App {
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var locationManager = AppLocationManager.shared
    @AppStorage("hasSeenSplashScreen") private var hasSeenSplashScreen = false
    @State private var showSplashScreen = true
    @State private var isInitialized = false
    

    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentBackgroundColor()
                        .ignoresSafeArea()
                
                if isInitialized {
                    if showSplashScreen {
                        Color(UIColor.systemBackground)
                            .ignoresSafeArea()
                        
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
                locationManager.initialize()
                
                let locationStatus = locationManager.authorizationStatus ?? .notDetermined
                showSplashScreen = !hasSeenSplashScreen && locationStatus == .notDetermined
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isInitialized = true
                }
            }
        }
    }
}
