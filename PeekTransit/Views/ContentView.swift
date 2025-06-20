import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @State private var selection: Int = 0
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared
    @AppStorage(settingsUserDefaultsKeys.defaultTab) private var defaultTab: Int = 0
    @State private var showUpdateAlert = false
    @State private var showStopView = false
    @State private var selectedStop: Stop? = nil
    @State private var isLoadingStop = false
    @State private var loadingError: Error? = nil
    
    var body: some View {
        ZStack {
            TabView(selection: $selection) {
                MapView()
                    .tabItem {
                        Label("Map", systemImage: "map.fill")
                    }
                    .tag(0)
                
                ListView()
                    .tabItem {
                        Label("Stops", systemImage: "list.bullet")
                    }
                    .tag(1)
                
                SavedStopsView()
                    .tabItem {
                        Label("Saved", systemImage: "bookmark.fill")
                    }
                    .tag(2)
                
                WidgetsView()
                    .tabItem {
                        Label("Widgets", systemImage: "note.text")
                    }
                    .tag(3)
                
                MoreTabView()
                    .tabItem {
                        Label("More", systemImage: "ellipsis.circle.fill")
                    }
                    .tag(4)
            }
            .environmentObject(themeManager)
            .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
            .onAppear {
                if selection == 0 {
                    selection = defaultTab
                }
                
                
                
                NotificationCenter.default.addObserver(
                    forName: .appUpdateAvailable,
                    object: nil,
                    queue: .main
                ) { _ in
                    showUpdateAlert = true
                }
                
                Task {
                    await AppUpdateChecker().checkForUpdate()
                }
            }
            .alert("Update Available", isPresented: $showUpdateAlert) {
                
                Button("Update Now") {
                    if let appStoreURL = URL(string: "https://apps.apple.com/ca/app/peek-transit/id6741770809") {
                        UIApplication.shared.open(appStoreURL)
                    }
                }
                
                Button("Later", role: .cancel) {}
                
            } message: {
                Text("A new version of the app is available. Would you like to update now?")
            }
            
            if isLoadingStop {
                VStack {
                    ProgressView("Loading Stop...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.4))
                .zIndex(100)
            }
        }
        .sheet(isPresented: $showStopView) {
            if let stop = selectedStop {
                NavigationView {
                    BusStopView(stop: stop, isDeepLink: true, stopLoadError: loadingError)
                        .navigationBarItems(trailing: Button("Close") {
                            showStopView = false
                            loadingError = nil
                        })
                        .onAppear() {
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                }
            } else if loadingError != nil {
                StopLoadErrorView(error: loadingError, onRetry: {
                    handleDeepLink()
                }, onClose: {
                    showStopView = false
                    loadingError = nil
                })
            }
        }
        .onChange(of: deepLinkHandler.isShowingBusStop) { isShowing in
            if isShowing {
                handleDeepLink()
            }
        }
        .onChange(of: deepLinkHandler.selectedStopNumber) { newStopNumber in
            if showStopView && deepLinkHandler.isShowingBusStop {
                handleDeepLink()
            }
        }
    }
    
    private func handleDeepLink() {
        guard let stopNumber = deepLinkHandler.selectedStopNumber else {
            return
        }
        
        loadingError = nil
        
        if let currentStop = selectedStop,
           let currentStopNumber = currentStop.number as? Int,
           currentStopNumber == stopNumber {
            isLoadingStop = true
        } else {
            isLoadingStop = true
            selectedStop = nil
        }
        
        Task {
            do {
                if let stop = try await StopsDataStore.shared.getStop(number: stopNumber) {
                    DispatchQueue.main.async {
                        selectedStop = stop
                        showStopView = true
                        isLoadingStop = false
                    }
                } else {
                    DispatchQueue.main.async {
                        loadingError = TransitError.parseError("Stop not found")
                        showStopView = true
                        isLoadingStop = false
                    }
                }
            } catch {
                print("Error loading stop: \(error)")
                DispatchQueue.main.async {
                    loadingError = error
                    showStopView = true
                    isLoadingStop = false
                }
            }
            
            DispatchQueue.main.async {
                deepLinkHandler.isShowingBusStop = false
            }
        }
    }
}

struct StopLoadErrorView: View {
    let error: Error?
    let onRetry: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .padding(.bottom, 10)
                
                Text("Error Loading Stop")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(error?.localizedDescription ?? "Could not load stop information")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry")
                    }
                    .frame(minWidth: 120)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top, 20)
            }
            .padding()
            .navigationBarItems(trailing: Button("Close") {
                onClose()
            })
        }
    }
}
