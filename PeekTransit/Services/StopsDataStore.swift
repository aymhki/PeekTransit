import SwiftUI
import CoreLocation

class StopsDataStore: ObservableObject {
    static let shared = StopsDataStore()
    private static let searchDebounceTime: TimeInterval = 1.0
    private static let cacheDuration: TimeInterval = 30
    private var searchTask: Task<Void, Never>?
    private var loadStopsTask: Task<Void, Never>?
    private var enrichmentTask: Task<Void, Never>?
    private var lastFetchTime: Date?
    private var lastFetchLocation: CLLocation?
    private var cachedStops: [Stop] = []
    
    @Published var stops: [Stop] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var errorForGetStopFromTripPlan: Error?
    @Published var searchResults: [Stop] = []
    @Published var isSearching = false
    @Published var searchError: Error?
    private var isCurrentlyLoading = false

    
    private let batchSize = 30
    private var isProcessing = false
    
    private init() {}
    
    private func isCacheValid(for location: CLLocation) -> Bool {
        guard let lastFetchTime = lastFetchTime,
              let lastFetchLocation = lastFetchLocation else {
            return false
        }
        
        let timeValid = Date().timeIntervalSince(lastFetchTime) < Self.cacheDuration
        let distanceValid = location.distance(from: lastFetchLocation) < 1
        
        return timeValid && distanceValid
    }
    
    private func updateCache(location: CLLocation) {
        self.lastFetchTime = Date()
        self.lastFetchLocation = location
        self.cachedStops = self.stops
    }
    
    func loadStops(userLocation: CLLocation, loadingFromWidgetSetup: Bool?) async {
        guard !isCurrentlyLoading else { return }
        loadStopsTask?.cancel()
        // enrichmentTask?.cancel()
        
        if isCacheValid(for: userLocation) {
            await MainActor.run {
                self.stops = self.cachedStops
                self.isLoading = false
                self.error = nil
            }
            return
        }
        
        isCurrentlyLoading = true
        defer { isCurrentlyLoading = false }
        
        loadStopsTask = Task {
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.searchResults = []
                isLoading = true
                error = nil
                stops = []
            }
            
            do {
                guard !Task.isCancelled else { return }
                
                isProcessing = true
                let nearbyStops = try await TransitAPI.shared.getNearbyStops(userLocation: userLocation, forShort: getGlobalAPIForShortUsage())
                
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.stops = nearbyStops
                    
                    if let loadingFromWidgetSetup = loadingFromWidgetSetup, loadingFromWidgetSetup == false {
                        self.isLoading = false
                        
                        if self.stops.isEmpty {
                            self.error = TransitError.parseError("No stops could be loaded")
                        }
                    }
                }
                
                if let loadingFromWidgetSetup = loadingFromWidgetSetup, loadingFromWidgetSetup == true {
                    await enrichStops(nearbyStops)
                    
                    guard !Task.isCancelled else { return }
                    
                    await MainActor.run {
                        self.isLoading = false
                        self.updateCache(location: userLocation)
                        
                        if self.stops.isEmpty {
                            self.error = TransitError.parseError("No stops could be loaded")
                        }
                    }
                } else {
                    enrichmentTask = Task {
                        await enrichStops(nearbyStops)
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            self.updateCache(location: userLocation)
                        }
                    }
                }
                
            } catch {
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    if !Task.isCancelled && !(error is CancellationError) {
                        if self.stops.isEmpty {
                            self.error = error
                        }
                    }
                    self.isLoading = false
                }
            }
            
            isProcessing = false
        }
        
        await loadStopsTask?.value
    }
    
    private func enrichStops(_ stops: [Stop]) async {
        let stopsNeedingEnrichment = stops.filter { stop in
            stop.variants == nil || (stop.variants as? [Variant])?.isEmpty ?? true
        }
        
        guard !stopsNeedingEnrichment.isEmpty else { return }
        
        do {
            let _ = try await TransitAPI.shared.getVariantsForStops(stops: stops) { [weak self] enrichedStop in
                guard let self = self, !Task.isCancelled else { return }
                
                await MainActor.run {
                    if enrichedStop.number != -1,
                       let index = self.stops.firstIndex(where: { ($0.number as? Int) == enrichedStop.number }) {
                        self.stops[index] = enrichedStop
                    }
                }
            }
        } catch {
            guard !Task.isCancelled else { return }
            print("Error processing stops: \(error.localizedDescription)")
        }
    }
    
    func searchForStops(query: String, userLocation: CLLocation?) async {
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            await MainActor.run {
                self.searchResults = []
                self.isSearching = false
                self.searchError = nil
            }
            return
        }
        
        searchTask = Task {
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.isSearching = true
                self.searchError = nil
            }
            
            try? await Task.sleep(nanoseconds: UInt64(Self.searchDebounceTime * 1_000_000_000))
            guard !Task.isCancelled else { return }
            
            do {
                let searchedStops = try await TransitAPI.shared.searchStops(query: query, forShort: getGlobalAPIForShortUsage())
                
                await MainActor.run {
                    self.searchResults = searchedStops
                }
                
                do {
                    let _ = try? await TransitAPI.shared.getVariantsForStops(stops: searchedStops) { [weak self] enrichedStop in
                        guard let self = self, !Task.isCancelled else { return }
                        
                        await MainActor.run {
                            if enrichedStop.number != -1,
                               let index = self.searchResults.firstIndex(where: { ($0.number as? Int) == enrichedStop.number }) {
                                self.searchResults[index] = enrichedStop
                            }
                        }
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    print("Error processing search batch: \(error.localizedDescription)")
                    
                }
                    
                

                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.isSearching = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    if !(error is CancellationError) {
                        self.searchError = error
                    }
                    self.isSearching = false
                }
            }
        }
    }
    
    func getStop(number: Int) async throws -> Stop? {
        if let stop = stops.first(where: { ($0.number) == number }) {
            return stop
        }
        
        if let stop = searchResults.first(where: { ($0.number) == number }) {
            return stop
        }
        
        guard let url = TransitAPI.shared.createURL(
            path: "stops/\(number).json",
            parameters: ["usage": "long"]
        ) else {
            throw TransitError.invalidURL
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        let data = try await TransitAPI.shared.fetchData(from: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let stop = json["stop"] as? [String: Any] else {
            throw TransitError.parseError("Invalid stop data format")
        }
        
        var stopObject = Stop(from: stop)
        
        var enrichedStop = stopObject
        let variants = try await TransitAPI.shared.getOnlyVariantsForStop(stop: stopObject)
        enrichedStop.variants = variants
        let finalStop = enrichedStop
        
        await MainActor.run {
            isLoading = false
            stops.append(finalStop)
            errorForGetStopFromTripPlan = nil
            error = nil
        }
        
        return finalStop
    }
}
