import SwiftUI
import WidgetKit

struct StopSelectionStep: View {
    @Binding var selectedStops: [[String: Any]]
    @Binding var isClosestStop: Bool
    @Binding var selectedPerferredStopsInClosestStops: Bool
    let maxStopsAllowed: Int
    let settingNotification: Bool
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var stopsStore = StopsDataStore.shared
    @State private var searchText = ""
    @State private var maxPerferredstopsInClosestStops: Int = getMaxPerferredstopsInClosestStops()
    @State private var shouldShowContent = false
    @State private var viewState: ViewState = .loading
    @StateObject private var savedStopsManager = SavedStopsManager.shared
    @State private var selectedTab = 0
    
    private enum ViewState {
        case loading
        case ready
        case transitioning
    }
    
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
        let stopsToFilter = selectedTab == 0 ? combinedStops : savedStopsManager.savedStops.map { $0.stopData }
        
        guard !searchText.isEmpty else { return stopsToFilter }
        
        return stopsToFilter.filter { stop in
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
        if settingNotification {
            return 1
        } else {
            if selectedPerferredStopsInClosestStops {
                return maxPerferredstopsInClosestStops
            } else {
                return maxStopsAllowed
            }
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
    
    private func handleOptionToggle() {
        viewState = .transitioning
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isClosestStop.toggle()
                if isClosestStop {
                    selectedStops = []
                } else {
                    selectedPerferredStopsInClosestStops = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewState = .ready
                }
            }
        }
    }
    
    private func handlePreferredToggle() {
        viewState = .transitioning
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedPerferredStopsInClosestStops.toggle()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewState = .ready
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {

                        
                        Picker("Stops", selection: $selectedTab) {
                            Text("All Stops").tag(0)
                            Text("Bookmarked").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        if settingNotification {
                            Text("Select the notification bus stop")
                                .font(.title3)
                                .padding([.top, .horizontal])
                        } else {
                            Text("Select the widget bus stops")
                                .font(.title3)
                                .padding([.top, .horizontal])
                        }
                        
                        if (selectedTab == 0) {
                            Text("Hint: Use the search bar to search for and select stops that are not near your location.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            
                            if !settingNotification {
                                
                                Button(action: handleOptionToggle) {
                                    HStack(alignment: .center, spacing: 10) {
                                        Image(systemName: isClosestStop ? "checkmark.square.fill" : "square")
                                            .foregroundColor(isClosestStop ? .blue : .secondary)
                                            .font(.system(size: 28))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Auto select closest stops everytime")
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            Text("Automatically use closest stops based on your location everytime you look at the widget")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                                .disabled(viewState == .transitioning)
                                
                                if isClosestStop {
                                    Button(action: handlePreferredToggle) {
                                        HStack(alignment: .center, spacing: 10) {
                                            Image(systemName: selectedPerferredStopsInClosestStops ? "checkmark.square.fill" : "square")
                                                .foregroundColor(selectedPerferredStopsInClosestStops ? .blue : .secondary)
                                                .font(.system(size: 28))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Select preferred stops")
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                                
                                                Text("Allow you to select which stop(s) to display on the widget regardless of distance from your location")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal)
                                    .transition(.opacity.combined(with: .move(edge: .leading)))
                                    .disabled(viewState == .transitioning)
                                }
                            }
                        
                        }

                        if (!isClosestStop || selectedPerferredStopsInClosestStops || settingNotification) {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Selected stops: \(selectedStops.count)/\(getWhichMaxStopsToUse)")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                VStack {
                                    if stopsStore.isLoading {
                                        ProgressView("Loading stops...")
                                            .frame(maxWidth: .infinity, maxHeight: 100)
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
                                                        await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: true)
                                                    }
                                                }
                                            }
                                            .buttonStyle(.bordered)
                                        }
                                    } else if combinedStops.isEmpty {
                                        Text("No stops found nearby")
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, minHeight: 100)
                                    } else {
                                        // Only show content when ready
                                        Group {
                                            if viewState != .transitioning {
                                                stopsListContent
                                            } else {
                                                Color.clear.frame(height: 100)
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)).animation(.easeInOut(duration: 0.3).delay(0.05)),
                                removal: .opacity.animation(.easeInOut(duration: 0.2))
                            ))
                            .id("StopListContainer-\(isClosestStop)-\(selectedPerferredStopsInClosestStops)-\(settingNotification)")
                        }
                    }
                    .padding(.bottom, 20)
                }
                .animation(.easeInOut(duration: 0.3).delay(0.05), value: isClosestStop)
                .animation(.easeInOut(duration: 0.3).delay(0.05), value: selectedPerferredStopsInClosestStops)
                .animation(.easeInOut(duration: 0.3).delay(0.05), value: settingNotification)
                .searchable(text: $searchText, prompt: "Search stops, routes...")
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .refreshable {
                    let newLocation = locationManager.location
                    if let location = newLocation {
                        Task {
                            await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: true)
                        }
                    }
                    
                    searchText = ""
                }
                .onChange(of: searchText) { query in
                    
                    if (selectedTab == 0) {
                        Task {
                            await stopsStore.searchForStops(query: query, userLocation: locationManager.location)
                        }
                    }
                    
                    
                }
                .onChange(of: selectedTab) { _ in
                    searchText = ""
                }
                .onAppear {
                    locationManager.initialize()
                    locationManager.startUpdatingLocation()
                    locationManager.requestLocation()
                    savedStopsManager.loadSavedStops()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewState = .ready
                        shouldShowContent = true
                    }
                }
                .onChange(of: locationManager.location) { newLocation in
                    if let location = newLocation,
                       locationManager.shouldRefresh(for: location) {
                        Task {
                            await stopsStore.loadStops(userLocation: location, loadingFromWidgetSetup: true)
                        }
                    }
                }
                
                if viewState == .transitioning {
                    Color.clear
                        .contentShape(Rectangle())
                        .allowsHitTesting(true)
                }
            }
        }
    }
    
    private var stopsListContent: some View {
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
