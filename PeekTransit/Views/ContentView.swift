import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @State private var selection: Int = 0
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared
    @StateObject private var stopsStore = StopsDataStore.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedStop: [String: Any]? = nil
    @State private var isLoading = false
    @State private var error: Error? = nil
    @AppStorage(settingsUserDefaultsKeys.defaultTab) private var defaultTab: Int = 0
    
    var body: some View {
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
        .sheet(isPresented: $deepLinkHandler.isShowingBusStop) {
            NavigationView {
                if let stop = selectedStop {
                    BusStopView(stop: stop, isDeepLink: true)
                        .navigationBarItems(trailing:
                            Button(action: {
                                deepLinkHandler.isShowingBusStop = false
                            }) {
                                Text("Done")
                            }
                        )
                } else if isLoading {
                    ProgressView("Loading stop...")
                        .padding()
                } else if let error = error {
                    VStack(spacing: 16) {
                        Text("Error getting stop info")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        
                        Button("Retry") {
                            Task {
                                if let stopNumber = deepLinkHandler.selectedStopNumber {
                                   
                                    await loadStop(number: stopNumber)
                                    
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    

                }
            }
            
            
        
        }
        .environmentObject(themeManager)
        .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
        .onChange(of: deepLinkHandler.selectedStopNumber) { stopNumber in
            guard let stopNumber = stopNumber else { return }
            Task {
               
                await loadStop(number: stopNumber)
                
            }
        }
        .onAppear {
            if selection == 0 {
                selection = defaultTab
            }
            
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func loadStop(number: Int) async {
        isLoading = true
        error = nil
        selectedStop = nil
        
        Task {
            do {
                selectedStop = try await stopsStore.getStop(number: number)
                if selectedStop == nil {
                    throw TransitError.parseError("Stop not found")
                }
            } catch {
                self.error = error
            }
            isLoading = false
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

