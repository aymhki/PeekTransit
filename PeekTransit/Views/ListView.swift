import SwiftUI
import CoreLocation
import MapKit
import WidgetKit


struct ListView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var stopsStore = StopsDataStore.shared
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var searchText = ""
    @State private var showAlert = false
    @State private var savedStopsManager =  SavedStopsManager.shared
    @State private var visibleRows = Set<Int>()
    @State private var isAppActive = true



    var combinedStops: [[String: Any]] {
        var combined = stopsStore.stops
        let existingStopNumbers = Set(combined.compactMap { $0["number"] as? Int })
        
        for stop in stopsStore.searchResults {
            if let number = stop["number"] as? Int,
               !existingStopNumbers.contains(number) {
                combined.append(stop)
            }
        }
        
        return combined
    }
    
    
       var filteredStops: [[String: Any]] {
           guard !searchText.isEmpty else { return combinedStops }
        
           return combinedStops.filter { stop in
            if let name = stop["name"] as? String,
               name.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            if let number = stop["number"] as? Int,
               String(number).contains(searchText) {
                return true
            }
            
            if let variants = stop["variants"] as? [[String: Any]] {
                return variants.contains { variant in
                    if let variantDict = variant["variant"] as? [String: Any],
                       let key = variantDict["key"] as? String {
                        return key.localizedCaseInsensitiveContains(searchText)
                    }
                    return false
                }
            }
            
            return false
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
//                if !networkMonitor.isConnected && stopsStore.stops.isEmpty {
//                    NetworkWaitingView() {
//                        networkMonitor.stopMonitoring()
//                        networkMonitor.startMonitoring()
//                    }
//                } else
                
                if stopsStore.isLoading {
                    ProgressView("Loading stops...")
                } else if let error = stopsStore.error {
                    VStack {
                        Text("Error loading stops")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Retry") {
                            self.stopsStore.error = nil
                            let newLocation = locationManager.location
                            if let location = newLocation {
                                Task {
                                    await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: false)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                } else if combinedStops.isEmpty {
                    Text("No stops found nearby")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        if stopsStore.isSearching {
                            HStack {
                                Spacer()
                                ProgressView("Searching...")
                                Spacer()
                            }
                        }
                        
                        ForEach(filteredStops.indices, id: \.self) { index in
                            let stop = filteredStops[index]
                            
                            StopRow(
                                stop: stop,
                                variants: stop["variants"] as? [[String: Any]],
                                inSaved: false,
                                visibilityAction: { isVisible in
                                    if isVisible {
                                        visibleRows.insert(index)
                                    } else {
                                        visibleRows.remove(index)
                                    }
                                }
                            )
                            
                            
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search stops, routes...")
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .onChange(of: searchText) { query in
                        Task {
                            await stopsStore.searchForStops(query: query, userLocation: locationManager.location)
                        }
                    }
                    .refreshable {
                        let newLocation = locationManager.location
                        if let location = newLocation {
                            Task {
                                await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: false)
                            }
                        }
                        
                        searchText = ""
                        MapSnapshotCache.shared.clearCache()
                    }
                }
            }
            .navigationTitle("Nearby Stops")
            .onDisappear {
                MapSnapshotCache.shared.cancelPendingRequests()
                networkMonitor.stopMonitoring()
            }

        }
        .onAppear {
            networkMonitor.startMonitoring()
            locationManager.requestLocation()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            isAppActive = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            isAppActive = true
        }
        .onChange(of: locationManager.location) { newLocation in
            guard isAppActive else { return }

            if let location = newLocation,
               locationManager.shouldRefresh(for: location) {
                Task {
                    await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: false)
                }
            }
        }
    }

}

