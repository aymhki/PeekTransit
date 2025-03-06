import SwiftUI

struct SavedStopRowView: View {
    let savedStop: SavedStop
    @ObservedObject private var savedStopsManager = SavedStopsManager.shared
    
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
            
            StopRow(stop: savedStop.stopData, variants: uniqueVariants, inSaved: true, visibilityAction: nil)
            
        }
    }
}
