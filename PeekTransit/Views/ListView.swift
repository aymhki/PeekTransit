import SwiftUI
import CoreLocation
import MapKit



struct ListView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var stopsStore = StopsDataStore.shared
    @State private var searchText = ""
    @State private var showAlert = false


       var filteredStops: [[String: Any]] {
           guard !searchText.isEmpty else { return stopsStore.stops }
        
           return stopsStore.stops.filter { stop in
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
                            let newLocation = locationManager.location
                            if let location = newLocation {
                                Task {
                                    await stopsStore.loadStops(userLocation: location)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if stopsStore.stops.isEmpty {
                    Text("No stops found nearby")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(filteredStops.indices, id: \.self) { index in
                            let stop = filteredStops[index]
                            if let variants = stop["variants"] as? [[String: Any]] {
                                StopRow(stop: stop, variants: variants, inSaved: false)
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search stops, routes...")
                    .refreshable {
                        let newLocation = locationManager.location
                        if let location = newLocation {
                            Task {
                                await stopsStore.loadStops(userLocation: location)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nearby Stops")
            .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    guard let url = URL(string: "mailto:agamyahk@myumanitoba.ca") else { return }
                                    if UIApplication.shared.canOpenURL(url) {
                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                    } else {
                                        
                                        showAlert = true
                                    }
                                }) {
                                    Image(systemName: "info.circle")
                                }

                            }
                        }
                        .alert("Could not find an email client", isPresented: $showAlert) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text("There does not seem to be an email client set for this device.")
                        }
        }
        .onAppear {
            locationManager.requestLocation()
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation,
               locationManager.shouldRefresh(for: location) {
                Task {
                    await stopsStore.loadStops(userLocation: location)
                }
            }
        }
    }

}


extension CLLocationCoordinate2D: Identifiable {
    public var id: String {
        "\(latitude)-\(longitude)"
    }
}
