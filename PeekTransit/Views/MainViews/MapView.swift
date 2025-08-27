import SwiftUI
import MapKit
import WidgetKit

struct MapView: View {
    @Binding var isSearchingActive: Bool
    @Binding var isDetailViewPresented: Bool
    @StateObject private var locationManager = AppLocationManager.shared
    @StateObject private var stopsStore = StopsDataStore.shared
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var region = MKCoordinateRegion()
    @State private var selectedStop: Stop?
    @State private var showLoadingIndicator = false
    @State private var centerMapOnUser = true
    @State private var isManualRefresh = false
    @State private var isSearchingRoute = false
    @State private var highlightedStopNumber: Int?
    @State private var routeInstructions: String?
    @State private var focusedStopNumber: Int = -1
    @State private var navigateToFocusedStop: Bool = false
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var isAppActive = true
    @State private var hasAttemptedInitialLoad = false
    @State private var initialLoadTimer: Timer?
    
    var locationDenied: Bool {
        locationManager.authorizationStatus == .denied ||
        locationManager.authorizationStatus == .restricted
    }
    
    private let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    
    var currentlyAvailableStops: [Stop] {
        let currentDate = Date()
        return stopsStore.stops.filter { stop in
            return (
                (stop.effectiveFrom == nil || currentDate >= stop.effectiveFrom ?? Date()) &&
                     (stop.effectiveTo == nil || currentDate <= stop.effectiveTo ?? Date())
                )
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                MapViewRepresentable(
                    stops: currentlyAvailableStops,
                    userLocation: locationManager.location,
                    onAnnotationTapped: { annotation in
                        if let customAnnotation = annotation as? CustomStopAnnotation {
                            selectedStop = customAnnotation.stopData
                        }
                    },
                    centerMapOnUser: $centerMapOnUser,
                    highlightedStopNumber: highlightedStopNumber
                )
                .edgesIgnoringSafeArea(.top)
                
                if locationDenied {
                    LocationPermissionDeniedView()
                        .zIndex(1)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        if !isSearchingRoute && stopsStore.error == nil && !stopsStore.isLoading && isAppActive  {
                            DestinationSearchButton(isSearching: $isSearchingRoute)
                                .padding(.leading)
                        }
                        
                        Spacer()
                        Button(action: centerOnUser) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .padding()
                                .foregroundStyle(.white)
                                .background(.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
                
                if isSearchingRoute {
                    ZStack {
                        Group {
                            if (colorScheme == .dark || themeManager.currentTheme == .classic) {
                                Color.white.opacity(0.1)
                            } else {
                                Color.black.opacity(0.5)
                            }
                        }
                        .edgesIgnoringSafeArea(.top)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSearchingRoute = false
                            }
                        }
                        
                        VStack {
                            AddressSearchView(isSearching: $isSearchingRoute) { selectedRoute in
                                handleSelectedRoute(selectedRoute)
                            }
                            .ignoresSafeArea(.keyboard)
                            
                            Spacer()
                        }
                    }
                    .ignoresSafeArea(.keyboard)
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
                }
                
                if stopsStore.isLoading && (isManualRefresh || currentlyAvailableStops.isEmpty) {
                    ProgressView()
                        .padding()
                        .background(Color(.systemBackground).opacity(1))
                        .cornerRadius(8)
                }
                
                if let error = stopsStore.error {
                    ErrorViewForMapView(error: error) {
                        self.stopsStore.error = nil
                        retryLoadingStops()
                    }
                } else if let error = stopsStore.errorForGetStopFromTripPlan {
                    ErrorViewForMapView(error: error) {
                        self.stopsStore.errorForGetStopFromTripPlan = nil
                        isManualRefresh = true
                        stopsStore.isLoading = true
                        selectAndDisplayStop(withNumber: focusedStopNumber, navigateToBusStopView: navigateToFocusedStop)
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
            .navigationDestination(isPresented: Binding(
                get: { selectedStop != nil },
                set: { if !$0 { selectedStop = nil } }
            )) {
                if let stop = selectedStop {
                    BusStopView(stop: stop, isDeepLink: false)
                }
            }
        }
        .onChange(of: isSearchingRoute) { newValue in
            isSearchingActive = newValue
        }
        .onChange(of: selectedStop) { newValue in
            isDetailViewPresented = (newValue != nil)
        }
        .onAppear {
            handleViewAppear()
        }
        .onDisappear {
            handleViewDisappear()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            isAppActive = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            isAppActive = true
            
            if currentlyAvailableStops.isEmpty && !stopsStore.isLoading {
                attemptToLoadStops()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FocusOnStop"))) { notification in
            withAnimation {
                isSearchingRoute = false
            }
            
            if let stopNumber = notification.userInfo?["stopNumber"] as? Int {
                focusedStopNumber = stopNumber
                navigateToFocusedStop = false
                selectAndDisplayStop(withNumber: stopNumber, navigateToBusStopView: false)
            }
        }
        .onChange(of: locationManager.location) { newLocation in
            handleLocationChange(newLocation)
        }
        .onChange(of: locationManager.authorizationStatus) { newStatus in
            handleAuthorizationStatusChange(newStatus!)
        }
    }
    
    private func handleViewAppear() {
        networkMonitor.startMonitoring()
        
        if locationManager.authorizationStatus == nil {
            locationManager.initialize()
        }
        
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
        
        if currentlyAvailableStops.isEmpty && !stopsStore.isLoading {
            attemptToLoadStops()
        }
    }
    
    private func handleViewDisappear() {
        networkMonitor.stopMonitoring()
        initialLoadTimer?.invalidate()
    }
    
    private func attemptToLoadStops() {
        initialLoadTimer?.invalidate()
        
        if let location = locationManager.location {
            loadStopsWithLocation(location)
        } else {
            locationManager.requestLocation()
            
            initialLoadTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                if currentlyAvailableStops.isEmpty && !stopsStore.isLoading {
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
        
        isManualRefresh = false
        
        Task {
            await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: false)
            await MainActor.run {
                hasAttemptedInitialLoad = true
            }
        }
    }
    
    private func retryLoadingStops() {
        isManualRefresh = true
        hasAttemptedInitialLoad = false
        attemptToLoadStops()
    }
    
    private func centerOnUser() {
        guard locationManager.location != nil else {
            locationManager.requestLocation()
            return
        }
        
        centerMapOnUser = true
        isManualRefresh = true
        
        if let location = locationManager.location,
           locationManager.shouldRefresh(for: location) {
            Task {
                await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: false)
                await MainActor.run {
                    isManualRefresh = false
                }
            }
        } else {
            isManualRefresh = false
        }
    }
    
    private func handleLocationChange(_ newLocation: CLLocation?) {
        guard isAppActive else { return }
        guard let location = newLocation else { return }
        
        if currentlyAvailableStops.isEmpty && !stopsStore.isLoading {
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
            locationManager.startUpdatingLocation()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                attemptToLoadStops()
            }
        }
    }
    
    private func handleSelectedRoute(_ route: TripPlan) {
        let firstSegmentWithStop = route.segments.first { ($0.fromStop != nil && $0.fromStop?.key != -1 && $0.fromStop?.location != nil) || ($0.toStop != nil && $0.toStop?.key != -1 && $0.toStop?.location != nil) }
        
        guard let segment = firstSegmentWithStop else {
            withAnimation {
                isSearchingRoute = false
            }
            return
        }
        
        let targetStopNumber = getStopKeyFromSegment(theSegement: segment)
        self.highlightedStopNumber = targetStopNumber
        self.focusedStopNumber = self.highlightedStopNumber ?? -1
        self.routeInstructions = ""
        self.navigateToFocusedStop = true
        
        guard let _ = targetStopNumber else {
            isSearchingRoute = false
            return
        }
        
        withAnimation {
            isSearchingRoute = false
        }
        
        selectAndDisplayStop(withNumber: focusedStopNumber, navigateToBusStopView: true)
    }
    
    private func getStopKeyFromSegment(theSegement: TripSegment?) -> Int? {
        if let fromStopKey = theSegement?.fromStop?.key, fromStopKey != -1 {
            return fromStopKey
        }
        
        if let toStopKey = theSegement?.toStop?.key, toStopKey != -1 {
            return toStopKey
        }
        
        return -1
    }
    
    private func selectAndDisplayStop(withNumber stopNumber: Int, navigateToBusStopView: Bool) {
        if let existingStop = currentlyAvailableStops.first(where: { ($0.number) == stopNumber }) {
            if (navigateToBusStopView) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.selectedStop = existingStop
                }
            }
            
            zoomToStop(existingStop)
        } else {
            isManualRefresh = true
            
            Task {
                do {
                    if let stopData = try await stopsStore.getStop(number: stopNumber) {
                        await MainActor.run {
                            if (navigateToBusStopView) {
                                self.selectedStop = stopData
                            }
                            self.isManualRefresh = false
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.zoomToStop(stopData)
                            }
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.isManualRefresh = false
                        self.stopsStore.errorForGetStopFromTripPlan = error
                    }
                }
            }
        }
    }
    
    private func zoomToStop(_ stop: Stop) {
        let coordinate = CLLocationCoordinate2D(latitude: stop.centre.geographic.latitude, longitude: stop.centre.geographic.longitude)
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        )
        
        if let mapView = MapViewRepresentable.Coordinator.shared?.mapView {
            mapView.setRegion(region, animated: true)
            
            if let annotation = mapView.annotations.first(where: {
                ($0 as? CustomStopAnnotation)?.stopNumber == (stop.number)
            }) {
                mapView.selectAnnotation(annotation, animated: true)
            }
        }
    }
}

