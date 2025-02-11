import SwiftUI
import MapKit
import WidgetKit



struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var stopsStore = StopsDataStore.shared
    @State private var region = MKCoordinateRegion()
    @State private var selectedStop: [String: Any]?
    @State private var userInitiatedRegionChange = false
    @State private var isInitialLoad = true
    @State private var showLoadingIndicator = true
    
    private let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    
    var body: some View {
        NavigationStack {
            ZStack {
                MapViewRepresentable(
                    region: $region,
                    stops: stopsStore.stops,
                    userLocation: locationManager.location,
                    userInitiatedRegionChange: $userInitiatedRegionChange,
                    onAnnotationTapped: { annotation in
                        if let title = annotation.title ?? "",
                           let stop = stopsStore.stops.first(where: { ($0["name"] as? String) == title }) {
                            selectedStop = stop
                        }
                    }
                )
                .edgesIgnoringSafeArea(.top)
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: refreshLocation) {
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
                
                if stopsStore.isLoading && showLoadingIndicator {
                    ProgressView()
                        .padding()
                        .background(Color(.systemBackground).opacity(1))
                        .cornerRadius(8)
                }
                
                if let error = stopsStore.error {
                    VStack {
                        Text("Error loading stops")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                        Button("Retry") {
                            let newLocation = locationManager.location
                            if let location = newLocation {
                                region = MKCoordinateRegion(
                                    center: location.coordinate,
                                    span: defaultSpan
                                )
                                Task {
                                    await stopsStore.loadStops(userLocation: location)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(1))
                    .cornerRadius(8)
                }
            }
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
            locationManager.requestLocation()
            if isInitialLoad {
                refreshLocation()
                isInitialLoad = false
            }
        }
        .onChange(of: locationManager.location) { newLocation in
            guard isInitialLoad || !userInitiatedRegionChange else { return }
            if let location = newLocation {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: defaultSpan
                )
                
                if locationManager.shouldRefresh(for: location) {
                    Task {
                        await stopsStore.loadStops(userLocation: location)
                    }
                }
            }
        }
    }
    
    private func refreshLocation() {
        userInitiatedRegionChange = false
        showLoadingIndicator = true
        locationManager.manager.requestLocation()
        
        if let location = locationManager.location {
            withAnimation(.easeInOut(duration: 0.5)) {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: defaultSpan
                )
            }
            
            if locationManager.shouldRefresh(for: location) {
                showLoadingIndicator = false
                Task {
                    await stopsStore.loadStops(userLocation: location)
                }
            }
        }
    }
}
