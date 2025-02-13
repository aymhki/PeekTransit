import SwiftUI
import CoreLocation

struct StopRow: View {
    let stop: [String: Any]
    let variants: [[String: Any]]
    let inSaved: Bool
    @ObservedObject private var savedStopsManager = SavedStopsManager.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var forceUpdate = UUID()
    
    private var uniqueVariants: [[String: Any]] {
        var seenKeys = Set<String>()
        return variants.filter { item in
            guard let variant = item["variant"] as? [String: Any],
                  let key = variant["key"] as? String else {
                return false
            }
            if seenKeys.contains(key.split(separator: "-")[0].description) {
                return false
            }
            seenKeys.insert(key.split(separator: "-")[0].description)
            return true
        }
    }
    
    private var coordinate: CLLocationCoordinate2D? {
        guard let centre = stop["centre"] as? [String: Any],
              let geographic = centre["geographic"] as? [String: Any],
              let lat = Double(geographic["latitude"] as? String ?? ""),
              let lon = Double(geographic["longitude"] as? String ?? "") else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var body: some View {
        if !inSaved {
            NavigationLink(destination: BusStopView(stop: stop, isDeepLink: false)) {
                stopRowBody()
            }
            .buttonStyle(PlainButtonStyle())
            .contextMenu(menuItems: {
                Button(action: {
                    savedStopsManager.toggleSavedStatus(for: stop)
                }) {
                    Label(
                        savedStopsManager.isStopSaved(stop) ? "Remove Bookmark" : "Add Bookmark",
                        systemImage: savedStopsManager.isStopSaved(stop) ? "bookmark.slash" : "bookmark"
                    )
                }
            }, preview: {
                BusStopPreviewProvider(stop: stop)
            })
            .onChange(of: themeManager.currentTheme) { _ in
                forceUpdate = UUID()
            }
            .onChange(of: colorScheme) { _ in
                forceUpdate = UUID()
            }
        } else {
            stopRowBody()
            .buttonStyle(PlainButtonStyle())
            .contextMenu(menuItems: {
                Button(action: {
                    savedStopsManager.toggleSavedStatus(for: stop)
                }) {
                    Label(
                        savedStopsManager.isStopSaved(stop) ? "Remove Bookmark" : "Add Bookmark",
                        systemImage: savedStopsManager.isStopSaved(stop) ? "bookmark.slash" : "bookmark"
                    )
                }
            }, preview: {
                BusStopPreviewProvider(stop: stop)
            })
            .onChange(of: themeManager.currentTheme) { _ in
                forceUpdate = UUID()
            }
            .onChange(of: colorScheme) { _ in
                forceUpdate = UUID()
            }
        }
    }
    
    
    @ViewBuilder
    private func stopRowBody() -> some View {
        HStack(alignment: .top, spacing: 12) {
            if let coordinate = coordinate {
                StopMapPreview(
                    coordinate: coordinate,
                    direction: stop["direction"] as? String ?? "Unknown Direction"
                )
                .id(forceUpdate)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(stop["name"] as? String ?? "Unknown Stop")
                        .font(.subheadline)
                        .lineLimit(nil)
                    Spacer()
                    Text("#\(stop["number"] as? Int ?? 0)".replacingOccurrences(of: ",", with: ""))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if (!inSaved) {
                    if let distances = stop["distances"] as? [String: Any],
                       let currentDistance = distances.first,
                       let currentDistandValueString = currentDistance.value as? String,
                       let distanceInMeters = Double(currentDistandValueString) {
                        
                        if (savedStopsManager.isStopSaved(stop)) {
                            HStack {
                                Text(String(format: "%.0f meters away", distanceInMeters))
                                Image(systemName: "bookmark.fill")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        } else {
                            Text(String(format: "%.0f meters away", distanceInMeters))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                ScrollView {
                    FlowLayout(spacing: 8) {
                        ForEach(uniqueVariants.indices, id: \.self) { index in
                            if let route = uniqueVariants[index]["route"] as? [String: Any],
                               let variant = uniqueVariants[index]["variant"] as? [String: Any] {
                                VariantBadge(route: route, variant: variant)
                            }
                        }
                    }
                    .padding(.top)
                }
            }
        }
        .padding(.vertical, 8)
    }
}


