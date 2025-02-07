import SwiftUI
import CoreLocation

class StopsDataStore: ObservableObject {
    static let shared = StopsDataStore()
    
    @Published var stops: [[String: Any]] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let batchSize = 25
    private var isProcessing = false
    
    private init() {}
    
    func loadStops(userLocation: CLLocation) async {
        guard !isLoading else { return }
        
        await MainActor.run {
            isLoading = true
            error = nil
            stops = []
        }
        
        do {
            isProcessing = true
            let nearbyStops = try await TransitAPI.shared.getNearbyStops(userLocation: userLocation, forShort: false)
            
            for batch in stride(from: 0, to: nearbyStops.count, by: batchSize) {
                let endIndex = min(batch + batchSize, nearbyStops.count)
                let currentBatch = Array(nearbyStops[batch..<endIndex])
                
                do {
                    let enrichedBatch = try await TransitAPI.shared.getVariantsForStops(stops: currentBatch)
                    
                    await MainActor.run {
                        self.stops.append(contentsOf: enrichedBatch)
                    }
                    
                    // try await Task.sleep(nanoseconds: 100_000_000)
                } catch {
                    print("Error processing batch: \(error.localizedDescription)")
                    continue
                }
            }
            
            await MainActor.run {
                self.isLoading = false
                if self.stops.isEmpty {
                    self.error = TransitError.parseError("No stops could be loaded")
                }
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
        
        isProcessing = false
    }
}
