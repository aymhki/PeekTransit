import SwiftUI
import MapKit
import WidgetKit


struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var stopsStore = StopsDataStore.shared
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var region = MKCoordinateRegion()
    @State private var selectedStop: [String: Any]?
    @State private var showLoadingIndicator = false
    @State private var centerMapOnUser = true
    @State private var isManualRefresh = true
    @State private var isSearchingRoute = false
    @State private var highlightedStopNumber: Int?
    @State private var routeInstructions: String?
    @State private var focusedStopNumber: Int = -1
    @State private var navigateToFocusedStop: Bool = false
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var isAppActive = true
    @State private var hasPerformedInitialLoad = false



    
    private let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    
    var body: some View {

        NavigationStack {
            
            ZStack {
                
                MapViewRepresentable(
                    stops: stopsStore.stops,
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
                
//                if !networkMonitor.isConnected && stopsStore.stops.isEmpty && !stopsStore.isLoading && stopsStore.error == nil && stopsStore.errorForGetStopFromTripPlan == nil {
//                    NetworkWaitingView() {
//                        networkMonitor.stopMonitoring()
//                        networkMonitor.startMonitoring()
//                    }
//                        .padding()
//                        .background(Color(.systemBackground).opacity(0.9))
//                        .cornerRadius(10)
//                }
                
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
                }
                
                if stopsStore.isLoading && isManualRefresh {
                    ProgressView()
                        .padding()
                        .background(Color(.systemBackground).opacity(1))
                        .cornerRadius(8)
                }
                
                if let error = stopsStore.error {
                    ErrorViewForMapView(error: error) {
                        self.stopsStore.error = nil
                        isManualRefresh = true
                        showLoadingIndicator = true
                        refreshStops()
                    }
                } else if let error = stopsStore.errorForGetStopFromTripPlan {
                    ErrorViewForMapView(error: error) {
                        self.stopsStore.errorForGetStopFromTripPlan = nil
                        isManualRefresh = true
                        showLoadingIndicator = true
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
        .onAppear {
            networkMonitor.startMonitoring()
            locationManager.initialize()
            locationManager.startUpdatingLocation()
            isManualRefresh = true
            locationManager.requestLocation()
        }
        .onDisappear {
            networkMonitor.stopMonitoring()
        }  
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            isAppActive = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            isAppActive = true
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
           // guard !hasPerformedInitialLoad else { return }
            guard isAppActive else { return }
            guard let location = newLocation else { return }
            
            if locationManager.shouldRefresh(for: location) {
                hasPerformedInitialLoad = true
                Task {
                    await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: false)
                    if isManualRefresh {
                        isManualRefresh = false
                    }
                }
            }
        }
        .onChange(of: locationManager.authorizationStatus) { newStatus in
            guard !hasPerformedInitialLoad else { return }
            
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                locationManager.requestLocation()
                if let location = locationManager.location {
                    hasPerformedInitialLoad = true
                    Task {
                        await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: false)
                    }
                }
            }
        }


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
                isManualRefresh = false
            }
        } else {
            isManualRefresh = false
        }
    }
    
    private func refreshStops() {
        guard isAppActive else { return }
        guard let location = locationManager.location else { return }
        
        isManualRefresh = true
        
        Task {
            await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: false)
            showLoadingIndicator = false
            isManualRefresh = false
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
        
        guard let targetNumber = targetStopNumber else {
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
        if let existingStop = stopsStore.stops.first(where: { ($0["number"] as? Int) == stopNumber }) {
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
    
    private func zoomToStop(_ stop: [String: Any]) {
        guard let centre = stop["centre"] as? [String: Any],
              let geographic = centre["geographic"] as? [String: Any],
              let lat = Double(geographic["latitude"] as? String ?? ""),
              let lon = Double(geographic["longitude"] as? String ?? "") else {
            return
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        )
        
        if let mapView = MapViewRepresentable.Coordinator.shared?.mapView {
            mapView.setRegion(region, animated: true)
            
            if let annotation = mapView.annotations.first(where: {
                ($0 as? CustomStopAnnotation)?.stopNumber == (stop["number"] as? Int)
            }) {
                mapView.selectAnnotation(annotation, animated: true)
            }
        }
    }
    
}
