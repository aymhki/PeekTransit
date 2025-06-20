import SwiftUI
import CoreLocation
import MapKit


struct StopMapPreview: View {
    let coordinate: CLLocationCoordinate2D
    let direction: String
    
    @State private var snapshotImage: UIImage?
    @State private var isVisible = false
    @State private var requestId = UUID()
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    
    private func getPreferredStyle() -> Bool {
        switch themeManager.currentTheme {
        case .classic:
            return true
        case .modern:
            return colorScheme == .dark
        }
    }
    
    private func loadSnapshot() {
        guard isVisible else { return }
        
        let isDarkMode = getPreferredStyle()
        let newRequestId = UUID()
        self.requestId = newRequestId
        
        MapSnapshotCache.shared.snapshot(
            for: coordinate,
            size: CGSize(width: 80, height: 80),
            direction: direction,
            isDarkMode: isDarkMode,
            requestId: newRequestId
        ) { [requestId = newRequestId] image in
            if self.requestId == requestId {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.snapshotImage = image
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            if let image = snapshotImage {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .transition(.opacity)
            } else {
                Color.gray.opacity(0.2)
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .overlay(
                        DirectionIndicator(direction: direction)
                            .frame(width: 32, height: 32)
                            .opacity(0.7)
                    )
            }
        }
        .onAppear {
            isVisible = true
            loadSnapshot()
        }
        .onDisappear {
            isVisible = false
            MapSnapshotCache.shared.cancelRequest(id: requestId)
        }
        .onChange(of: colorScheme) { _ in
            snapshotImage = nil
            loadSnapshot()
        }
        .onChange(of: themeManager.currentTheme) { _ in
            snapshotImage = nil
            loadSnapshot()
        }
    }
}
