import SwiftUI
import WidgetKit

struct StopSelectionStep: View {
    @Binding var selectedStops: [[String: Any]]
    @Binding var isClosestStop: Bool
    @Binding var selectedPerferredStopsInClosestStops: Bool
    let maxStopsAllowed: Int
    
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var stopsStore = StopsDataStore.shared
    @State private var searchText = ""
    @State private var maxPerferredstopsInClosestStops: Int = getMaxPerferredstopsInClosestStops()
    
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
    
    var getWhichMaxStopsToUse: Int {
        if selectedPerferredStopsInClosestStops {
            return maxPerferredstopsInClosestStops
        } else {
            return maxStopsAllowed
        }
    }
    
    private func isStopSelected(_ stop: [String: Any]) -> Bool {
        selectedStops.contains(where: { ($0["number"] as? Int) == (stop["number"] as? Int) })
    }
    
    private func toggleStopSelection(_ stop: [String: Any]) {
        if let index = selectedStops.firstIndex(where: { ($0["number"] as? Int) == (stop["number"] as? Int) }) {
            selectedStops.remove(at: index)
        } else if selectedStops.count < getWhichMaxStopsToUse {
            selectedStops.append(stop)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Select the widget bus stops")
                        .font(.title3)
                        .padding([.top, .horizontal])

                    Button(action: {
                        withAnimation {
                            isClosestStop.toggle()
                            if isClosestStop {
                                selectedStops = []
                            } else {
                                selectedPerferredStopsInClosestStops = false
                            }
                        }
                    }) {
                        HStack(alignment: .center, spacing: 10) {
                            Image(systemName: isClosestStop ? "checkmark.square.fill" : "square")
                                .foregroundColor(isClosestStop ? .blue : .secondary)
                                .font(.system(size: 28))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Use closest stops based on location")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text("Updates automatically when viewing widget")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    
                    
                    if isClosestStop {
                        Button(action: {
                            withAnimation {
                                selectedPerferredStopsInClosestStops.toggle()
                            }
                        })
                         {
                            HStack(alignment: .center, spacing: 10) {
                                Image(systemName: selectedPerferredStopsInClosestStops ? "checkmark.square.fill" : "square")
                                    .foregroundColor(selectedPerferredStopsInClosestStops ? .blue : .secondary)
                                    .font(.system(size: 28))
                                
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Select preferred stops")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Text("Allow selection to filter from closest stops")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }

                    if (!isClosestStop || selectedPerferredStopsInClosestStops) {
                        HStack {
                            Text("Selected stops: \(selectedStops.count)/\(getWhichMaxStopsToUse)")
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
                                LazyVStack(spacing: 0) {
                                    if stopsStore.isSearching {
                                        HStack {
                                            Spacer()
                                            ProgressView("Searching...")
                                            Spacer()
                                        }
                                        .padding()
                                    }

                                    ForEach(filteredStops.indices, id: \.self) { index in
                                        let stop = filteredStops[index]
                                        if let variants = stop["variants"] as? [[String: Any]] {
                                            SelectableStopRow(
                                                stop: stop,
                                                variants: variants,
                                                selectedStops: selectedStops,
                                                isSelected: isStopSelected(stop),
                                                maxStops: getWhichMaxStopsToUse,
                                                onSelect: {
                                                    withAnimation {
                                                        toggleStopSelection(stop)
                                                    }
                                                }
                                            )
                                            if index < filteredStops.count - 1 {
                                                Divider()
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search stops, routes...")
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .refreshable {
                let newLocation = locationManager.location
                if let location = newLocation {
                    Task {
                        await stopsStore.loadStops(userLocation: location)
                    }
                }
                
                searchText = ""
            }
            .onChange(of: searchText) { query in
                Task {
                    await stopsStore.searchForStops(query: query, userLocation: locationManager.location)
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
}
