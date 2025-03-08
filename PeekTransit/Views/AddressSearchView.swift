import SwiftUI
import MapKit

struct AddressSearchView: View {
    @Binding var isSearching: Bool
    @State private var searchQuery = ""
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var selectedDestination: MKLocalSearchCompletion?
    @State private var routePlans: [TripPlan] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingRouteDetails = false
    @State private var networkMonitor = NetworkMonitor()
    @StateObject private var locationManager = LocationManager()
    @FocusState private var isTextFieldFocused: Bool
    
    private let searchCompleter: MKLocalSearchCompleter
    private let debouncer = Debouncer(delay: 0.3)
    private var completerDelegate = LocalSearchCompleterDelegate()
    
    var onRouteSelected: (TripPlan) -> Void

    init(isSearching: Binding<Bool>, onRouteSelected: @escaping (TripPlan) -> Void) {
        self._isSearching = isSearching
        self.onRouteSelected = onRouteSelected
        
        self.searchCompleter = MKLocalSearchCompleter()
        self.searchCompleter.resultTypes = [.address, .pointOfInterest]
        
        let winnipegCenter = CLLocationCoordinate2D(latitude: 49.8951, longitude: -97.1384)
        let searchRegion = MKCoordinateRegion(
            center: winnipegCenter,
            latitudinalMeters: 100000,
            longitudinalMeters: 100000
        )
        self.searchCompleter.region = searchRegion
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Type your destination address", text: $searchQuery)
                    .focused($isTextFieldFocused)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onChange(of: searchQuery) { query in
                        if !query.isEmpty {
                            if showingRouteDetails {
                                showingRouteDetails = false
                            }
                            
                            debouncer.debounce {
                                searchCompleter.queryFragment = query
                            }
    
                        } else {
                            searchResults = []
                        }
                    }
                    .onAppear {
                        isTextFieldFocused = true
                        
                        completerDelegate.onResultsUpdated = { results in
                            searchResults = results
                        }
                        searchCompleter.delegate = completerDelegate
                        networkMonitor.startMonitoring()
                    }
                    .onDisappear {
                        networkMonitor.stopMonitoring()
                    }
                    .disabled(!networkMonitor.isConnected)
                    .disableAutocorrection(true)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)
                    .autocapitalization(.none)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        searchQuery = ""
                        isSearching = false
                    }
                    
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            .padding()
            .background(Color(.systemBackground))
            .clipShape(getCustomRoundedShape(isAttached: showingResultsOrDetails))
            
            if !networkMonitor.isConnected {
                ConnectionErrorView(message: "No internet connection available")
                    .transition(.opacity)
            } else if isLoading {
                LoadingView()
                    .transition(.opacity)
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    errorMessage = nil
                }
                .transition(.opacity)
                
            } else if showingRouteDetails, !routePlans.isEmpty {
                ScrollView {
                    RouteDetailsView(
                        routePlan: getRoutWithShortestDuration(availableRoutes: routePlans),
                        onDismiss: {
                            withAnimation {
                                showingRouteDetails = false
                                searchQuery = ""
                            }
                        },
                        onRouteSelected: onRouteSelected
                    )
                }
                .background(Color(.systemBackground))
                .clipShape(getBottomRoundedShape())
                
            
            } else if !searchResults.isEmpty && !searchQuery.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(searchResults, id: \.self) { result in
                            SearchResultRow(result: result) {
                                handleSelection(result)
                            }
                            Divider()
                        }
                    }
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
                .clipShape(getBottomRoundedShape())
            }
            
            Spacer()
        }
        .frame(maxWidth: isLargeDevice() ? UIScreen.main.bounds.width * 0.3 : UIScreen.main.bounds.width * 0.9, maxHeight: UIScreen.main.bounds.height * 0.6)
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var showingResultsOrDetails: Bool {
        return (!searchResults.isEmpty && !searchQuery.isEmpty) ||
               showingRouteDetails ||
               isLoading ||
               errorMessage != nil
    }

    private func getCustomRoundedShape(isAttached: Bool) -> some Shape {
        let cornerRadius: CGFloat = 12
        if isAttached {
            return RoundedCorners(radius: cornerRadius, corners: [.topLeft, .topRight])
        } else {
            return RoundedCorners(radius: cornerRadius)
        }
    }

    private func getBottomRoundedShape() -> some Shape {
        let cornerRadius: CGFloat = 12
        return RoundedCorners(radius: cornerRadius, corners: [.bottomLeft, .bottomRight])
    }

    struct RoundedCorners: Shape {
        var radius: CGFloat
        var corners: UIRectCorner = .allCorners
        
        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(roundedRect: rect,
                                  byRoundingCorners: corners,
                                  cornerRadii: CGSize(width: radius, height: radius))
            return Path(path.cgPath)
        }
    }
    
    private func getRoutWithShortestDuration(availableRoutes: [TripPlan]) -> TripPlan {
        
        var shortestRoute: TripPlan = availableRoutes[0]
        var shortestDuration = shortestRoute.duration
        
        for route in availableRoutes {
            if (route.duration < shortestDuration) {
                shortestDuration = route.duration
                shortestRoute = route
            }
        }
        
        return shortestRoute
    }
    
    private func searchForRoutes(to destination: MKLocalSearchCompletion) {
        isLoading = true
        errorMessage = nil
        
        let searchRequest = MKLocalSearch.Request(completion: destination)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            if let error = error {
                self.errorMessage = "Failed to find address: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            guard let mapItem = response?.mapItems.first,
                  let location = mapItem.placemark.location else {
                self.errorMessage = "Could not determine location for this address"
                self.isLoading = false
                return
            }
            
            self.findTransitRoute(to: location)
        }
    }
    
    private func setupSearchCompleter() {
        searchCompleter.delegate = SearchCompleterDelegate(
            onResultsUpdated: { results in
                searchResults = results
            },
            onError: { error in
                errorMessage = error.localizedDescription
            }
        )
    }
    
    private func handleSelection(_ result: MKLocalSearchCompletion) {
        isLoading = true
        errorMessage = nil
        searchQuery = ""
        
        Task {
            do {
                let searchRequest = MKLocalSearch.Request(completion: result)
                let search = MKLocalSearch(request: searchRequest)
                let response = try await search.start()
                
                guard let selectedItem = response.mapItems.first,
                      let location = selectedItem.placemark.location else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Location not found"])
                }
                
                guard let userLocation = locationManager.location else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not determine your location"])
                }
                
                let plans = try await TransitAPI.shared.findTrip(
                    from: userLocation,
                    to: location
                )
                
                await MainActor.run {
                    if plans.isEmpty {
                        errorMessage = "No transit routes available to this destination"
                    } else {
                        routePlans = plans
                        showingRouteDetails = true
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to find transit routes: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func findTransitRoute(to destination: CLLocation) {
        guard let userLocation = locationManager.location else {
            errorMessage = "Could not determine your current location"
            isLoading = false
            return
        }
        
        Task {
            do {
                let plans = try await TransitAPI.shared.findTrip(
                    from: userLocation,
                    to: destination
                )
                
                await MainActor.run {
                    if plans.isEmpty {
                        errorMessage = "No transit routes available to this destination"
                    } else {
                        routePlans = plans
                        showingRouteDetails = true
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to find transit routes: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private struct LoadingView: View {
            var body: some View {
                VStack {
                    ProgressView("Finding routes...")
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
            }
        }
        
        private struct ErrorView: View {
            let message: String
            let onDismiss: () -> Void
            
            var body: some View {
                VStack(spacing: 12) {
                    Text("Error")
                        .font(.headline)
                    Text(message)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        onDismiss()
                    }
                    .padding(.top)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
            }
        }
        
        private struct ConnectionErrorView: View {
            let message: String
            
            var body: some View {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.title)
                    Text(message)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
            }
        }
        
        private struct SearchResultsList: View {
            let results: [MKLocalSearchCompletion]
            let onResultSelected: (MKLocalSearchCompletion) -> Void
            
            var body: some View {
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(results, id: \.self) { result in
                            Button(action: {
                                onResultSelected(result)
                            }) {
                                VStack(alignment: .leading) {
                                    Text(result.title)
                                        .font(.system(size: 16, weight: .medium))
                                    Text(result.subtitle)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
}

import Network

class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    @Published var isConnected = true
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
}

class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    init(delay: TimeInterval) {
        self.delay = delay
    }
    
    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
}


class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    let onResultsUpdated: ([MKLocalSearchCompletion]) -> Void
    let onError: (Error) -> Void
    
    init(onResultsUpdated: @escaping ([MKLocalSearchCompletion]) -> Void,
         onError: @escaping (Error) -> Void) {
        self.onResultsUpdated = onResultsUpdated
        self.onError = onError
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onResultsUpdated(completer.results)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        onError(error)
    }
}


struct SearchResultRow: View {
    let result: MKLocalSearchCompletion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.system(size: 16, weight: .medium))
                if !result.subtitle.isEmpty {
                    Text(result.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .buttonStyle(PlainButtonStyle())
    }
}

import SwiftUI
import MapKit

class LocalSearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    var onResultsUpdated: ([MKLocalSearchCompletion]) -> Void = { _ in }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onResultsUpdated(completer.results)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Address search error: \(error.localizedDescription)")
    }
}
