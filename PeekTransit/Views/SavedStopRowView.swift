import SwiftUI

struct SavedStopRowView: View {
    let savedStop: SavedStop
    let savedStopsManager: SavedStopsManager
    
    var body: some View {
        if let variants = savedStop.stopData["variants"] as? [[String: Any]] {
            let uniqueVariants = variants.filter { item in
                guard let variant = item["variant"] as? [String: Any],
                      let key = variant["key"] as? String else {
                    return false
                }
                var seenKeys = Set<String>()
                if seenKeys.contains(key.split(separator: "-")[0].description) {
                    return false
                }
                seenKeys.insert(key.split(separator: "-")[0].description)
                return true
            }
            
            StopRow(stop: savedStop.stopData, variants: uniqueVariants, inSaved: true)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        savedStopsManager.toggleSavedStatus(for: savedStop.stopData)
                    } label: {
                        Label("Delete", systemImage: "star.slash.fill")
                    }
                }
        }
    }
}
