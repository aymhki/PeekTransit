import SwiftUI
import WidgetKit

struct StopSelectionStep: View {
    @Binding var selectedStops: [[String: Any]]
    @Binding var isClosestStop: Bool
    let maxStopsAllowed: Int
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var stopsStore = StopsDataStore.shared
    @State private var searchText = ""
    
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
    
    private func isStopSelected(_ stop: [String: Any]) -> Bool {
        selectedStops.contains(where: { ($0["number"] as? Int) == (stop["number"] as? Int) })
    }
    
    private func toggleStopSelection(_ stop: [String: Any]) {
        if let index = selectedStops.firstIndex(where: { ($0["number"] as? Int) == (stop["number"] as? Int) }) {
            selectedStops.remove(at: index)
        } else if selectedStops.count < maxStopsAllowed {
            selectedStops.append(stop)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Select which bus stops you want to show on your widget from nearby stops or search for more")
                .font(.title3)
                .padding([.top, .horizontal])
            
            Text("You can select up to \(maxStopsAllowed) stop\(maxStopsAllowed > 1 ? "s" : "") for this widget size")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                withAnimation {
                    isClosestStop.toggle()
                    if isClosestStop {
                        selectedStops = []
                    }
                }
            }) {
                HStack {
                    if isClosestStop {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                        Text("Closest stop(s) based on location selected, click again to go back to stop selection or click next to proceed")
                    } else {
                        Image(systemName: "location.fill")
                        Text("Click here to use closest stop\(maxStopsAllowed > 1 ? "s" : "") based on your location at the time of viewing the widget")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isClosestStop ? Color.red : Color.accentColor)
                .foregroundColor(isClosestStop ? .white : Color(uiColor: UIColor.systemBackground))
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            if !isClosestStop {
                HStack {
                    Text("Selected stops: \(selectedStops.count)/\(maxStopsAllowed)")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                
                VStack {
                    if stopsStore.isLoading {
                        ProgressView("Loading stops...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                    SelectableStopRow(
                                        stop: stop,
                                        variants: variants,
                                        selectedStops: selectedStops,
                                        isSelected: isStopSelected(stop),
                                        maxStops: maxStopsAllowed,
                                        onSelect: {
                                            withAnimation {
                                                toggleStopSelection(stop)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .listStyle(.plain)
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
                .searchable(text: $searchText, prompt: "Search stops, routes...")
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .onChange(of: searchText) { query in
                    Task {
                        await stopsStore.searchForStops(query: query, userLocation: locationManager.location)
                    }
                }
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
