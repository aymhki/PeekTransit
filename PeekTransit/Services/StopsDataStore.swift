import SwiftUI
import CoreLocation

class StopsDataStore: ObservableObject {
    static let shared = StopsDataStore()
    private static let searchDebounceTime: TimeInterval = 1.0
    private static let cacheDuration: TimeInterval = 180
    private var searchTask: Task<Void, Never>?

    private var lastFetchTime: Date?
    private var lastFetchLocation: CLLocation?
    private var cachedStops: [[String: Any]] = []
    
    @Published var stops: [[String: Any]] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var errorForGetStopFromTripPlan: Error?
    @Published var searchResults: [[String: Any]] = []
    @Published var isSearching = false
    @Published var searchError: Error?
    
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
        guard !isLoading else { return }
        
        if isCacheValid(for: userLocation) {
            await MainActor.run {
                self.stops = self.cachedStops
                self.isLoading = false
                self.error = nil
            }
            return
        }
        
        await MainActor.run {
            self.searchResults = []
            isLoading = true
            error = nil
            stops = []
        }
        
        do {
            isProcessing = true
            let nearbyStops = try await TransitAPI.shared.getNearbyStops(userLocation: userLocation, forShort: getGlobalAPIForShortUsage())
            
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
                
                await MainActor.run {
                    self.isLoading = false
                    self.updateCache(location: userLocation)
                    
                    if self.stops.isEmpty {
                        self.error = TransitError.parseError("No stops could be loaded")
                    }
                }
            } else {
                Task {
                    await enrichStops(nearbyStops)
                    await MainActor.run {
                        self.updateCache(location: userLocation)
                    }
                }
            }
            
        } catch {
            await MainActor.run {
                if self.stops.isEmpty {
                    self.error = error
                }
                
                self.isLoading = false
            }
        }
        
        isProcessing = false
    }
    
    private func enrichStops(_ stops: [[String: Any]]) async {
        var enrichedStops: [[String: Any]] = []
        
        for batch in stride(from: 0, to: stops.count, by: batchSize) {
            let endIndex = min(batch + batchSize, stops.count)
            let currentBatch = Array(stops[batch..<endIndex])
            
            do {
                let enrichedBatch = try await TransitAPI.shared.getVariantsForStops(stops: currentBatch)
                enrichedStops.append(contentsOf: enrichedBatch)
                
                await MainActor.run {
                    for enrichedStop in enrichedBatch {
                        if let number = enrichedStop["number"] as? Int,
                           let index = self.stops.firstIndex(where: { ($0["number"] as? Int) == number }) {
                            self.stops[index] = enrichedStop
                        }
                    }
                }
                
                
            } catch {
                print("Error processing batch: \(error.localizedDescription)")
                continue
            }
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
            await MainActor.run {
                self.isSearching = true
                self.searchError = nil
            }
            
            try? await Task.sleep(nanoseconds: UInt64(Self.searchDebounceTime * 1_000_000_000))
            guard !Task.isCancelled else { return }
            
            do {
                let searchedStops = try await TransitAPI.shared.searchStops(query: query, forShort: getGlobalAPIForShortUsage())
                
                var enrichedSearchResults: [[String: Any]] = []
                
                for batch in stride(from: 0, to: searchedStops.count, by: batchSize) {
                    guard !Task.isCancelled else { return }
                    
                    let endIndex = min(batch + batchSize, searchedStops.count)
                    let currentBatch = Array(searchedStops[batch..<endIndex])
                    
                    do {
                        let enrichedBatch = try await TransitAPI.shared.getVariantsForStops(stops: currentBatch)
                        enrichedSearchResults.append(contentsOf: enrichedBatch)
                    } catch {
                        print("Error processing search batch: \(error.localizedDescription)")
                        continue
                    }
                }
                
                await MainActor.run {
                    self.searchResults = enrichedSearchResults
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.searchError = error
                    self.isSearching = false
                }
            }
        }
    }
    
    
    func getStop(number: Int) async throws -> [String: Any]? {
        if let stop = stops.first(where: { ($0["number"] as? Int) == number }) {
            return stop
        }
        
        if let stop = searchResults.first(where: { ($0["number"] as? Int) == number }) {
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
        
        var enrichedStop = stop
        let variants = try await TransitAPI.shared.getOnlyVariantsForStop(stop: stop)
        enrichedStop["variants"] = variants
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
