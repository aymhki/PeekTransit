import SwiftUI
import CoreLocation
import MapKit
import WidgetKit


struct ListView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var stopsStore = StopsDataStore.shared
    @State private var searchText = ""
    @State private var showAlert = false
    @State private var savedStopsManager =  SavedStopsManager.shared


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
                            if let variants = stop["variants"] as? [[String: Any]] {
                                StopRow(stop: stop, variants: variants, inSaved: false)
                            }
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
                                await stopsStore.loadStops(userLocation: location)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nearby Stops")
            .toolbar {
                        
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
        "\(latitude)\(getCompositKeyLinkerForDictionaries())\(longitude)"
    }
}
