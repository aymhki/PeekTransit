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

    @ViewBuilder
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
                            if let variants = savedStop.stopData.variants as? [Variant] {
                                let uniqueVariants = variants.filter { item in
                                    
                                    var seenKeys = Set<String>()
                                    if seenKeys.contains(item.key.split(separator: getVariantKeySeperator())[0].description) {
                                        return false
                                    }
                                    seenKeys.insert(item.key.split(separator: getVariantKeySeperator())[0].description)
                                    return true
                                }
                                
                                StopRow(stop: savedStop.stopData, variants: uniqueVariants, inSaved: true, visibilityAction: nil)
                                
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
        NavigationStack {
            contentView
        }
        .onAppear {
            savedStopsManager.loadSavedStops()
        }
    }
}
