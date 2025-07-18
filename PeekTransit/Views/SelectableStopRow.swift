import SwiftUI
import Foundation
import CoreLocation


struct SelectableStopRow: View {
    let stop: Stop
    let variants: [Variant]
    let selectedStops: [Stop]
    let isSelected: Bool
    let maxStops: Int
    let onSelect: () -> Void
    @ObservedObject private var savedStopsManager = SavedStopsManager.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var forceUpdate = UUID()

    private func getEffectiveDateFormatted(effectiveDate: Date) -> String  {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, hh:mm a"
        
        return dateFormatter.string(from: effectiveDate)
    }
    
    private var currentlyAvailableVariants: [Variant]? {
        let currentDate = Date()
        
        var seen = Set<Variant>()
        var result: [Variant] = []
        
        for variant in variants {
            if (
                (variant.effectiveFrom == nil || currentDate >= variant.effectiveFrom ?? Date()) &&
                (variant.effectiveTo == nil || currentDate <= variant.effectiveTo ?? Date())
            ) {
                let currentVariantKey = variant.key.split(separator: "-")[0]
                var isDuplicate = false
                
                for existingVariant in seen {
                    if existingVariant.key.split(separator: "-")[0] == currentVariantKey {
                        isDuplicate = true
                        break
                    }
                }
                
                if !isDuplicate {
                    seen.insert(variant)
                    result.append(variant)
                }
            }
        }
        
        return result.isEmpty ? nil : result
    }
    
    private var futureVariants: [Variant]? {
        let currentDate = Date()
        
        var seen = Set<Variant>()
        var result: [Variant] = []
        
        for variant in variants {
            if (variant.effectiveFrom != nil && variant.effectiveFrom ?? Date() > currentDate) {
                let currentVariantKey = variant.key.split(separator: "-")[0]
                var isDuplicate = false
                
                for existingVariant in seen {
                    if existingVariant.key.split(separator: "-")[0] == currentVariantKey {
                        isDuplicate = true
                        break
                    }
                }
                
                if !isDuplicate {
                    seen.insert(variant)
                    result.append(variant)
                }
            }
        }
        
        return result.isEmpty ? nil : result
    }
    
    private var theyAreBothTheSame: Bool {
        if  currentlyAvailableVariants?.count ?? 0 == futureVariants?.count ?? 0 {
            for (index, variant) in (currentlyAvailableVariants ?? []).enumerated() {
                if index >= (futureVariants?.count ?? 0) {
                    return false
                } else if variant.key.split(separator: "-")[0].description != futureVariants?[index].key.split(separator: "-")[0].description {
                    return false
                }
            }
            
            return true
        } else {
            return false
        }
    }
    
    private var coordinate: CLLocationCoordinate2D? {
        return CLLocationCoordinate2D(latitude: stop.centre.geographic.latitude, longitude: stop.centre.geographic.longitude)
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                CircularCheckbox(isSelected: isSelected)
                    .padding(.top, 8)
                
                if let coordinate = coordinate {
                    StopMapPreview(
                        coordinate: coordinate,
                        direction: stop.direction
                    )
                    .id(forceUpdate)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(stop.name)
                            .font(.subheadline)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Text("#\(stop.number)".replacingOccurrences(of: ",", with: ""))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if stop.distance != Double.infinity {
                        let distanceInMeters = Double(stop.distance)
                        
                        if (savedStopsManager.isStopSaved(stop)) {
                            HStack {
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
                    
                    VStack(alignment: .leading) {
                        if let currentVariants = currentlyAvailableVariants {
                            FlowLayout(spacing: 12) {
                                ForEach(currentVariants.indices, id: \.self) { index in
                                    VariantBadge(variant: currentVariants[index], showFullVariantKey: false, showVariantName: false)
                                }
                            }
                        }
                        
                        if let futureVariants = futureVariants, !theyAreBothTheSame {
                            VStack(alignment: .leading, spacing: 4) {
                                let groupedFutureVariants = Dictionary(grouping: futureVariants) { variant in
                                    Calendar.current.dateComponents([.year, .month, .day], from: variant.effectiveFrom ?? Date())
                                }
                                
                                let sortedGroups = groupedFutureVariants.keys.sorted { components1, components2 in
                                    let date1 = Calendar.current.date(from: components1) ?? Date()
                                    let date2 = Calendar.current.date(from: components2) ?? Date()
                                    return date1 < date2
                                }
                                
                                ForEach(sortedGroups.indices, id: \.self) { groupIndex in
                                    let dateComponents = sortedGroups[groupIndex]
                                    let groupVariants = groupedFutureVariants[dateComponents] ?? []
                                    
                                    if let effectiveDate = Calendar.current.date(from: dateComponents) {

                                        Text("Effective From \( getEffectiveDateFormatted(effectiveDate: effectiveDate) ):")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.top, 4)
                                        
                                        FlowLayout(spacing: 12) {
                                            ForEach(groupVariants.indices, id: \.self) { index in
                                                VariantBadge(variant: groupVariants[index], showFullVariantKey: false, showVariantName: false)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
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
