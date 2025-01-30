import SwiftUI

struct SavedStopRowView: View {
    let savedStop: SavedStop
    let savedStopsManager: SavedStopsManager
    
    var body: some View {
        if let variants = savedStop.stopData["variants"] as? [[String: Any]] {
            StopRow(stop: savedStop.stopData, variants: variants, inSaved: true)
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
