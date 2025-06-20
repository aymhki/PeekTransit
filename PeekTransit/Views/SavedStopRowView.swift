import SwiftUI

struct SavedStopRowView: View {
    let savedStop: SavedStop
    @ObservedObject private var savedStopsManager = SavedStopsManager.shared
    
    var body: some View {
        if let variants = savedStop.stopData.variants as? [Variant] {
            let uniqueVariants = variants.filter { item in
                
                var seenKeys = Set<String>()
                if seenKeys.contains(item.key.split(separator: "-")[0].description) {
                    return false
                }
                seenKeys.insert(item.key.split(separator: "-")[0].description)
                return true
            }
            
            StopRow(stop: savedStop.stopData, variants: uniqueVariants, inSaved: true, visibilityAction: nil)
            
        }
    }
}
