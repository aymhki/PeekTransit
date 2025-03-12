import SwiftUI
import MapKit

import SwiftUI
import MapKit
import Combine

struct AddressSearchView: View {
    @Binding var isSearching: Bool
    @State private var searchQuery = ""
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var routePlans: [TripPlan] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingRouteDetails = false
    @State private var networkMonitor = NetworkMonitor()
    @StateObject private var searchHandler = SearchHandler()
    @StateObject private var locationManager = LocationManager()
    @FocusState private var isTextFieldFocused: Bool
    
    var onRouteSelected: (TripPlan) -> Void

    init(isSearching: Binding<Bool>, onRouteSelected: @escaping (TripPlan) -> Void) {
        self._isSearching = isSearching
        self.onRouteSelected = onRouteSelected
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
                        searchHandler.updateSearchQuery(query)
                        if showingRouteDetails && !query.isEmpty {
                            showingRouteDetails = false
                        }
                    }
                    .onAppear {
                        isTextFieldFocused = true
                        networkMonitor.startMonitoring()
                    }
                    .onDisappear {
                        networkMonitor.stopMonitoring()
                    }
                    .disabled(!networkMonitor.isConnected)
                    .disableAutocorrection(true)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)
                
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
                ConnectionErrorViewForAddressSearch(message: "No internet connection available")
                    .transition(.opacity)
            } else if (isLoading || searchHandler.isSearching) && routePlans.isEmpty {
                LoadingViewForAddressSearch()
                    .transition(.opacity)
                    .background(Color(.systemBackground))
                    .clipShape(getBottomRoundedShape())
            } else if let error = errorMessage {
                ErrorViewForAddressSearch(message: error) {
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
            } else if !searchQuery.isEmpty {
                ScrollView {
                    if !isLoading && !searchHandler.isSearching && searchQuery.count > 2  && searchHandler.searchResults.isEmpty {
                        NoResultsViewForAddressSearch()
                            .padding()
                    } else {
                        LazyVStack(alignment: .leading) {
                            ForEach(searchHandler.searchResults, id: \.self) { result in
                                SearchResultRowForAddressSearch(result: result) {
                                    handleSelection(result)
                                }
                                Divider()
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(getBottomRoundedShape())
            }
            
            Spacer()
        }
        .frame(maxWidth: isLargeDevice() ? UIScreen.main.bounds.width * 0.5 : UIScreen.main.bounds.width * 0.9,  maxHeight: isLargeDevice() ? UIScreen.main.bounds.height * 0.5 : UIScreen.main.bounds.height * 0.7)
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onReceive(searchHandler.$searchResults) { results in
            self.searchResults = results
        }
        .onReceive(searchHandler.$error) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private var showingResultsOrDetails: Bool {
        return ((!searchHandler.searchResults.isEmpty && !searchQuery.isEmpty) ||
               showingRouteDetails ||
               isLoading ||
               searchHandler.isSearching ||
                (searchHandler.searchResults.isEmpty && !isLoading && !searchHandler.isSearching && !searchQuery.isEmpty)) && errorMessage == nil
    }

    private func getCustomRoundedShape(isAttached: Bool) -> some Shape {
        let cornerRadius: CGFloat = 12
        if isAttached {
            return RoundedCornersForAddressSearch(radius: cornerRadius, corners: [.topLeft, .topRight])
        } else {
            return RoundedCornersForAddressSearch(radius: cornerRadius)
        }
    }

    private func getBottomRoundedShape() -> some Shape {
        let cornerRadius: CGFloat = 12
        return RoundedCornersForAddressSearch(radius: cornerRadius, corners: [.bottomLeft, .bottomRight])
    }

    private func getRoutWithShortestDuration(availableRoutes: [TripPlan]) -> TripPlan {
        let reccomendedRoute = TripPlan.getRecommendedRoute(from: availableRoutes)
        return reccomendedRoute // availableRoutes[0]
    }
    
    private func handleSelection(_ result: MKLocalSearchCompletion) {
        isTextFieldFocused = false
        isLoading = true
        searchHandler.isSearching = false
        errorMessage = nil
        searchQuery = result.title
        
        Task {
            do {
                let searchRequest = MKLocalSearch.Request(completion: result)
                let search = MKLocalSearch(request: searchRequest)
                let response = try await search.start()
                
                guard let selectedItem = response.mapItems.first,
                      let location = selectedItem.placemark.location else {
                    throw NSError(domain: "", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Location not found"])
                }
                
                guard let userLocation = locationManager.location else {
                    throw NSError(domain: "", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Could not determine your location"])
                }
                
                if let destinationKey = try await TransitAPI.shared.getLocationKey(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                ), let currentLocationKey = try await TransitAPI.shared.getLocationKey(
                    latitude: userLocation.coordinate.latitude,
                    longitude: userLocation.coordinate.longitude) {
                    
                    let plans = try await TransitAPI.shared.findTripWithLocationKey(
                        from: currentLocationKey,
                        toLocationKey: destinationKey,
                        walkSpeed: 5.0,
                        maxWalkTime: 15,
                        minTransferWait: 2,
                        maxTransferWait: 15,
                        maxTransfers: 3,
                        mode: "depart-after"
                    )
                    
                    await MainActor.run {
                        if plans.isEmpty {
                            errorMessage = "No transit routes available to this destination right now"
                        } else {
                            routePlans = plans
                            showingRouteDetails = true
                        }
                        isLoading = false
                    }
                } else {
                    let plans = try await TransitAPI.shared.findTrip(
                        from: userLocation,
                        to: location
                    )
                    
                    await MainActor.run {
                        if plans.isEmpty {
                            errorMessage = "No transit routes available to this destination right now"
                        } else {
                            routePlans = plans
                            showingRouteDetails = true
                        }
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to find transit routes: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    
}











