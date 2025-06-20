import SwiftUI

struct SavedStopsView: View {
    @StateObject private var savedStopsManager = SavedStopsManager.shared
    @State private var searchText = ""

    
    var filteredStops: [SavedStop] {
        guard !searchText.isEmpty else { return savedStopsManager.savedStops }
        
        return savedStopsManager.savedStops.filter { savedStop in
            let stop = savedStop.stopData
            
            if let name = stop.name as? String,
               name.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            if let number = stop.number as? Int,
               String(number).contains(searchText) {
                return true
            }
            
            if let variants = stop.variants as? [Variant] {
                return variants.contains { variant in
                    return variant.key.localizedCaseInsensitiveContains(searchText)
                }
            }
            
            return false
        }
    }

    private var contentView: some View {
            Group {
                if savedStopsManager.isLoading {
                    ProgressView("Loading saved stops...")
                } else if savedStopsManager.savedStops.isEmpty {
                    Text("No saved stops")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(filteredStops) { savedStop in
                            NavigationLink(destination: BusStopView(stop: savedStop.stopData, isDeepLink: false)) {
                                SavedStopRowView(savedStop: savedStop)
                            }

                        }
                        .onDelete { indexSet in
                            savedStopsManager.removeStop(at: indexSet)
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search saved stops...")
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .refreshable {
                        savedStopsManager.loadSavedStops()
                    }
                }
            }
            .navigationTitle("Saved Stops")
    }
    
    var body: some View {
        if isLargeDevice() {
            NavigationView {
                contentView
            }
            .onAppear {
                savedStopsManager.loadSavedStops()
            }
        } else {
            NavigationStack {
                contentView
            }
            .onAppear {
                savedStopsManager.loadSavedStops()
            }
        }
    }
}
