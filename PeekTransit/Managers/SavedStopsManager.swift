import Foundation
import Combine

class SavedStopsManager: ObservableObject {
    static let shared = SavedStopsManager()
    
    @Published private(set) var savedStops: [SavedStop] = []
    @Published private(set) var isLoading = false
    
    private let userDefaultsKey = "savedStops"
    private let queue = DispatchQueue(label: "com.app.savedstops", qos: .userInitiated)
    
    private init() {
        loadSavedStops()
    }
    
    func loadSavedStops() {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if let data = UserDefaults.standard.data(forKey: self.userDefaultsKey) {
                do {
                    let stops = try JSONDecoder().decode([SavedStop].self, from: data)
                    
                    DispatchQueue.main.async {
                        self.savedStops = stops
                        self.isLoading = false
                    }
                } catch {
                    print("Error decoding saved stops: \(error)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func saveToDisk() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let data = try JSONEncoder().encode(self.savedStops)
                UserDefaults.standard.set(data, forKey: self.userDefaultsKey)
                UserDefaults.standard.synchronize()
            } catch {
                print("Error saving stops: \(error)")
            }
        }
    }
    
    func isStopSaved(_ stop: Stop) -> Bool {
        return savedStops.contains { $0.id == "\(stop.number)" }
    }
    
    func toggleSavedStatus(for stop: Stop) {
        let stopId = "\(stop.number)"
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let index = self.savedStops.firstIndex(where: { $0.id == stopId }) {
                self.savedStops.remove(at: index)
            } else {
                self.savedStops.append(SavedStop(stopData: stop))
            }
            
            self.objectWillChange.send()
            self.saveToDisk()
        }
    }
    
    func removeStop(at indexSet: IndexSet) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.savedStops.remove(atOffsets: indexSet)
            self.objectWillChange.send()
            self.saveToDisk()
        }
    }
}
