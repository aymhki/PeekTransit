
import SwiftUI
import MapKit
import Combine

class SearchHandler: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    private let searchCompleter = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()
    private let debounceTime: TimeInterval = 0.3
    private var searchTask: Task<Void, Never>?
    @Published var isSearching = false
    
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var error: Error?
    private var searchQuerySubject = PassthroughSubject<String, Never>()

    override init() {
        super.init()
        setupSearchCompleter()
    }

    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
        
        let winnipegCenter = CLLocationCoordinate2D(latitude: 49.8951, longitude: -97.1384)
        let searchRegion = MKCoordinateRegion(
            center: winnipegCenter,
            latitudinalMeters: 100000,
            longitudinalMeters: 100000
        )
        searchCompleter.region = searchRegion
        
        searchQuerySubject
            .debounce(for: .seconds(debounceTime), scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self = self else { return }
                
                if query.isEmpty {
                    self.searchResults = []
                    self.isSearching = false
                } else {
                    self.isSearching = true
                    self.searchTask?.cancel()
                    self.searchTask = Task {
                        await self.performSearch(query)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func updateSearchQuery(_ query: String) {
        searchQuerySubject.send(query)
    }
    
    @MainActor
    private func performSearch(_ query: String) async {
        searchCompleter.queryFragment = query
    }
        
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async { [weak self] in
            self?.searchResults = completer.results
            self?.isSearching = false
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.error = error
            self?.searchResults = []
            self?.isSearching = false
        }
    }
}
