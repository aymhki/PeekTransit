import SwiftUI
import CoreLocation

struct StopRow: View {
    let stop: [String: Any]
    let variants: [[String: Any]]
    let inSaved: Bool
    @ObservedObject private var savedStopsManager = SavedStopsManager.shared
    
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
        NavigationLink(destination: BusStopView(stop: stop, isDeepLink: false)) {
            HStack(alignment: .top, spacing: 12) {
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
        .buttonStyle(PlainButtonStyle())
    }
}
