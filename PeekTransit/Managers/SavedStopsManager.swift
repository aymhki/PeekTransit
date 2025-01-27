import Foundation
import Combine

class SavedStopsManager: ObservableObject {
    static let shared = SavedStopsManager()
    
    @Published private(set) var savedStops: [SavedStop] = []
    @Published private(set) var isLoading = false
    
    private let userDefaultsKey = "savedStops"
    
    private init() {
        loadSavedStops()
    }
    
    func loadSavedStops() {
        isLoading = true
        defer { isLoading = false }
        
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let stops = try? JSONDecoder().decode([SavedStop].self, from: data) {
            savedStops = stops
        }
    }
    
    private func saveToDisk() {
        if let encoded = try? JSONEncoder().encode(savedStops) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func isStopSaved(_ stop: [String: Any]) -> Bool {
        guard let stopNumber = stop["number"] as? Int else { return false }
        return savedStops.contains { $0.id == "\(stopNumber)" }
    }
    
    func toggleSavedStatus(for stop: [String: Any]) {
        guard let stopNumber = stop["number"] as? Int else { return }
        let stopId = "\(stopNumber)"
        
        if let index = savedStops.firstIndex(where: { $0.id == stopId }) {
            savedStops.remove(at: index)
        } else {
            savedStops.append(SavedStop(stopData: stop))
        }
        
        saveToDisk()
    }
} 