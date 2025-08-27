import SwiftUI
import CoreLocation
import MapKit
import WidgetKit

struct ListView: View {
    @StateObject private var locationManager = AppLocationManager.shared
    @StateObject private var stopsStore = StopsDataStore.shared
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var searchText = ""
    @State private var showAlert = false
    @State private var savedStopsManager = SavedStopsManager.shared
    @State private var visibleRows = Set<Int>()
    @State private var isAppActive = true
    @State private var hasAttemptedInitialLoad = false
    @State private var initialLoadTimer: Timer?
    
    var locationDenied: Bool {
        locationManager.authorizationStatus == .denied ||
        locationManager.authorizationStatus == .restricted
    }
    
    var combinedStops: [Stop] {
        var combined = stopsStore.stops
        let existingStopNumbers = Set(combined.compactMap { $0.number })
        
        for stop in stopsStore.searchResults {
            if stop.number != -1,
               !existingStopNumbers.contains(stop.number) {
                combined.append(stop)
            }
        }
        
        return combined
    }
    
    var currentlyAvailableStops: [Stop] {
        let currentDate = Date()
        return combinedStops.filter { stop in
            return (
                (stop.effectiveFrom == nil || currentDate >= stop.effectiveFrom ?? Date()) &&
                     (stop.effectiveTo == nil || currentDate <= stop.effectiveTo ?? Date())
            )
        }
    }
    
    var filteredStops: [Stop] {
        guard !searchText.isEmpty else { return currentlyAvailableStops }
        
        return currentlyAvailableStops.filter { stop in
            if let name = stop.name as? String,
               name.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            if let number = stop.number as? Int,
               String(number).contains(searchText) {
                return true
            }
            
            if let variants = stop.variants as? [Variant] {
                return variants.contains { variant in
                    return variant.key.localizedCaseInsensitiveContains(searchText)
                }
            }
            
            return false
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        ProgressView("Loading stops...")
    }
    
    @ViewBuilder
    private var errorView: some View {
        if let error = stopsStore.error {
            VStack {
                Text("Error loading stops")
                    .font(.headline)
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                retryButton
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var retryButton: some View {
        Button("Retry") {
            self.retryLoadingStops()
        }
        .buttonStyle(.bordered)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        if locationDenied {
            LocationPermissionDeniedView()
        } else {
            VStack {
                Text("No stops found nearby")
                    .foregroundColor(.secondary)
                
                retryButton
            }
        }
    }
    
    @ViewBuilder
    private var stopsListView: some View {
        List {
            if stopsStore.isSearching {
                searchingIndicator
            }
            stopsForEachView
        }
        .searchable(text: $searchText, prompt: "Search stops, routes...")
        .disableAutocorrection(true)
        .autocapitalization(.none)
        .onChange(of: searchText) { query in
            performSearch(query: query)
        }
        .refreshable {
            await performRefresh()
        }
    }
    
    @ViewBuilder
    private var searchingIndicator: some View {
        HStack {
            Spacer()
            ProgressView("Searching...")
            Spacer()
        }
    }
    
    @ViewBuilder
    private var stopsForEachView: some View {
        ForEach(filteredStops.indices, id: \.self) { index in
            let stop = filteredStops[index]
            StopRow(
                stop: stop,
                variants: stop.variants as? [Variant],
                inSaved: false,
                visibilityAction: { isVisible in
                    handleVisibilityChange(for: index, isVisible: isVisible)
                }
            )
        }
    }
    
    @ViewBuilder
    var contentView: some View {
        Group {
            if stopsStore.isLoading && combinedStops.isEmpty && !hasAttemptedInitialLoad {
                loadingView
            } else if stopsStore.error != nil && combinedStops.isEmpty {
                errorView
            } else if combinedStops.isEmpty && hasAttemptedInitialLoad && !stopsStore.isLoading {
                emptyStateView
            } else if !combinedStops.isEmpty {
                stopsListView
            } else {
                loadingView
            }
        }
        .navigationTitle("Nearby Stops")
        .onDisappear {
            handleViewDisappear()
        }
        .onAppear {
            handleViewAppear()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            isAppActive = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            isAppActive = true

            if combinedStops.isEmpty && !stopsStore.isLoading {
                attemptToLoadStops()
            }
        }
        .onChange(of: locationManager.location) { newLocation in
            handleLocationChange(newLocation)
        }
        .onChange(of: locationManager.authorizationStatus) { newStatus in
            handleAuthorizationStatusChange(newStatus!)
        }
    }
    
    var body: some View {
        NavigationStack {
            contentView
        }
    }
    
    private func attemptToLoadStops() {
        initialLoadTimer?.invalidate()
        
        if let location = locationManager.location {
            loadStopsWithLocation(location)
        } else {
            locationManager.requestLocation()
            
            initialLoadTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                if combinedStops.isEmpty && !stopsStore.isLoading {
                    if let location = locationManager.location {
                        loadStopsWithLocation(location)
                    } else {
                        hasAttemptedInitialLoad = true
                    }
                }
            }
        }
    }
    
    private func loadStopsWithLocation(_ location: CLLocation) {
        guard !stopsStore.isLoading else { return }
        
        Task {
            await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: false)
            await MainActor.run {
                hasAttemptedInitialLoad = true
            }
        }
    }
    
    private func retryLoadingStops() {
        self.stopsStore.error = nil
        hasAttemptedInitialLoad = false
        attemptToLoadStops()
    }
    
    private func performSearch(query: String) {
        Task {
            await stopsStore.searchForStops(query: query, userLocation: locationManager.location)
        }
    }
    
    private func performRefresh() async {
        let newLocation = locationManager.location
        if let location = newLocation {
            await MainActor.run {
                searchText = ""
            }
            await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: false)
        } else {
            locationManager.requestLocation()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if let location = locationManager.location {
                await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: false)
            }
        }
    }
    
    private func handleVisibilityChange(for index: Int, isVisible: Bool) {
        if isVisible {
            visibleRows.insert(index)
        } else {
            visibleRows.remove(index)
        }
    }
    
    private func handleViewDisappear() {
        MapSnapshotCache.shared.cancelPendingRequests()
        networkMonitor.stopMonitoring()
        initialLoadTimer?.invalidate()
    }
    
    private func handleViewAppear() {
        networkMonitor.startMonitoring()
        
        if locationManager.authorizationStatus == nil {
            locationManager.initialize()
        }
        
        locationManager.startUpdatingLocation()
        
        if combinedStops.isEmpty && !stopsStore.isLoading {
            attemptToLoadStops()
        }
    }
    
    private func handleLocationChange(_ newLocation: CLLocation?) {
        guard isAppActive else { return }
        guard let location = newLocation else { return }
        
        if combinedStops.isEmpty && !stopsStore.isLoading {
            loadStopsWithLocation(location)
        } else if locationManager.shouldRefresh(for: location) && !stopsStore.isLoading {
            Task {
                await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: false)
            }
        }
    }
    
    private func handleAuthorizationStatusChange(_ newStatus: CLAuthorizationStatus) {
        if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
            locationManager.requestLocation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                attemptToLoadStops()
            }
        }
    }
}
