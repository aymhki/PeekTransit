import SwiftUI
import CoreLocation
import MapKit


struct StopMapPreview: View {
    let coordinate: CLLocationCoordinate2D
    let direction: String
    @State private var snapshotImage: UIImage?
    @State private var isVisible = false
    @State private var loadingToken = UUID()
    
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
        let token = UUID()
        self.loadingToken = token
        
        MapSnapshotCache.shared.snapshot(
            for: coordinate,
            size: CGSize(width: 80, height: 80),
            direction: direction,
            isDarkMode: isDarkMode
        ) { image in
            if self.loadingToken == token {
                self.snapshotImage = image
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
        }
        .onChange(of: colorScheme) { _ in
            loadSnapshot()
        }
        .onChange(of: themeManager.currentTheme) { _ in
            loadSnapshot()
        }
    }
}
