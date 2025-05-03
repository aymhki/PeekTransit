import SwiftUI
import Foundation
import CoreLocation


struct SelectableStopRow: View {
    let stop: [String: Any]
    let variants: [[String: Any]]
    let selectedStops: [[String: Any]]
    let isSelected: Bool
    let maxStops: Int
    let onSelect: () -> Void
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
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                CircularCheckbox(isSelected: isSelected)
                    .padding(.top, 8)
                
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
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Text("#\(stop["number"] as? Int ?? 0)".replacingOccurrences(of: ",", with: ""))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let distances = stop["distances"] as? [String: Any],
                       let currentDistance = distances.first,
                       let currentDistandValueString = currentDistance.value as? String,
                       let distanceInMeters = Double(currentDistandValueString) {
                        
                        if (savedStopsManager.isStopSaved(stop)) {
                            HStack {
                                //Text(String(format: "%.0f meters away", distanceInMeters))
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
                    
                    VStack {
                        FlowLayout(spacing: 12) {
                            ForEach(uniqueVariants.indices, id: \.self) { index in
                                if let route = uniqueVariants[index]["route"] as? [String: Any],
                                   let variant = uniqueVariants[index]["variant"] as? [String: Any] {
                                    VariantBadge(route: route, variant: variant)
                                }
                            }
                        }
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
            }
            .padding(.vertical, 8)
        }
        .onChange(of: themeManager.currentTheme) { _ in
            forceUpdate = UUID()
        }
        .onChange(of: colorScheme) { _ in
            forceUpdate = UUID()
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(selectedStops.count >= maxStops && !isSelected)
    }
}
