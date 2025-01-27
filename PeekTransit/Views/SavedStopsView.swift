import SwiftUI

struct SavedStopsView: View {
    @StateObject private var savedStopsManager = SavedStopsManager.shared
    @State private var searchText = ""
    
    var filteredStops: [SavedStop] {
        guard !searchText.isEmpty else { return savedStopsManager.savedStops }
        
        return savedStopsManager.savedStops.filter { savedStop in
            let stop = savedStop.stopData
            
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
    
    var body: some View {
        NavigationView {
            Group {
                if savedStopsManager.isLoading {
                    ProgressView("Loading saved stops...")
                } else if savedStopsManager.savedStops.isEmpty {
                    Text("No saved stops")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(filteredStops) { savedStop in
                            if let variants = savedStop.stopData["variants"] as? [[String: Any]] {
                                StopRow(stop: savedStop.stopData, variants: variants, inSaved: true)
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search saved stops...")
                    .refreshable {
                        savedStopsManager.loadSavedStops()
                    }
                }
            }
            .navigationTitle("Saved Stops")
        }
    }
} 
