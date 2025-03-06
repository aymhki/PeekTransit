import SwiftUI
import MapKit
import WidgetKit

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var stopsStore = StopsDataStore.shared
    @State private var region = MKCoordinateRegion()
    @State private var selectedStop: [String: Any]?
    @State private var showLoadingIndicator = false
    @State private var centerMapOnUser = true
    
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
                    centerMapOnUser: $centerMapOnUser
                )
                .edgesIgnoringSafeArea(.top)
                
                VStack {
                    Spacer()
                    HStack {
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
                
                if stopsStore.isLoading && showLoadingIndicator {
                    ProgressView()
                        .padding()
                        .background(Color(.systemBackground).opacity(1))
                        .cornerRadius(8)
                }
                
                if let error = stopsStore.error {
                    ErrorViewForMapView(error: error) {
                        showLoadingIndicator = true
                        refreshStops()
                    }
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
        }
        .onChange(of: locationManager.location) { newLocation in
            guard let location = newLocation else { return }
            showLoadingIndicator = true
            if locationManager.shouldRefresh(for: location) {
                Task {
                    await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: false)
                    showLoadingIndicator = false
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
        showLoadingIndicator = true
        
        if let location = locationManager.location,
           locationManager.shouldRefresh(for: location) {
            Task {
                await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: false)
                showLoadingIndicator = false
            }
        } else {
            showLoadingIndicator = false
        }
    }
    
    private func refreshStops() {
        guard let location = locationManager.location else { return }
        Task {
            await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: false)
            showLoadingIndicator = false
        }
    }
}




