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
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(stop["name"] as? String ?? "Unknown Stop")
                            .font(.headline)
                            .lineLimit(3)
                        Spacer()
                        Text("#\(stop["number"] as? Int ?? 0)".replacingOccurrences(of: ",", with: ""))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let distances = stop["distances"] as? [String: Any],
                       let currentDistance = distances.first,
                       let currentDistandValueString = currentDistance.value as? String,
                       let distanceInMeters = Double(currentDistandValueString) {
                        
                        Text(String(format: "%.0f meters away", distanceInMeters))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    ScrollView {
                        FlowLayout(spacing: 2) {
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
        .buttonStyle(PlainButtonStyle())
        .disabled(selectedStops.count >= maxStops && !isSelected)
    }
}
