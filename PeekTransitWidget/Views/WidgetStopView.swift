import SwiftUI
import WidgetKit

struct WidgetStopView: View {
    let stop: [String: Any]
    let scheduleData: [String]?
    let size: WidgetFamily
    let stopNamePrefixSize = getStopNameMaxPrefixLengthForWidget()
    let fullyLoaded: Bool
    let forPreview: Bool

    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let stopName = stop["name"] as? String ?? "Unknown"
            let stopNumber = stop["number"] as? Int ?? 0
            let stopNamePrefix = "\(stopName.prefix(stopNamePrefixSize))..."
            

            if (size != .accessoryRectangular && fullyLoaded) {
                if (size == .systemSmall) {
                    Text("• \(stopName.count > stopNamePrefixSize ? stopNamePrefix : stopName) - \(stopNumber)")
                        .font(.system(size:  8))
                } else if (size == .systemLarge) {
                    Text("• \(stopName.count > stopNamePrefixSize ? stopNamePrefix : stopName) - \(stopNumber)")
                        .font(.system(.caption2))
                } else {
                    Text("• \(stopName.count > stopNamePrefixSize ? stopNamePrefix : stopName) - \(stopNumber)")
                        .font(.system(.caption2))
                        .padding(.bottom, 1)
                }
                
                if ((size == .systemLarge || size == .systemSmall || (scheduleData)?.count ?? 0 < 3) && fullyLoaded) {
                    Spacer()
                }
            }
            
            
            
            if let variants = stop["selectedVariants"] as? [[String: Any]] {
                let maxSchedules =  getMaxVariantsAllowed(widgetSizeSystemFormat: size, widgetSizeStringFormat: nil)

                ForEach(variants.prefix(maxSchedules).indices, id: \.self) { variantIndex in
                    if let key = variants[variantIndex]["key"] as? String,
                       let schedules = scheduleData,
                       let variantName = variants[variantIndex]["name"] as? String,
                       let matchingSchedule = schedules.first(where: { scheduleString in
                           let components = scheduleString.components(separatedBy: getScheduleStringSeparator())
                           return components.count >= 2 &&
                                  components[0] == key &&
                                  components[1] == variantName
                       }) {
                        
                        if (size == .systemSmall || size == .accessoryRectangular) {
                            BusScheduleRow(schedule: matchingSchedule, size: size, fullyLoaded: fullyLoaded, forPreview: forPreview)
                        } else if (size == .systemLarge) {
                            BusScheduleRow(schedule: matchingSchedule, size: size, fullyLoaded: fullyLoaded, forPreview: forPreview)
                                .padding(.horizontal, 8)
                        } else if (size == .systemMedium) {
                            BusScheduleRow(schedule: matchingSchedule, size: size, fullyLoaded: fullyLoaded, forPreview: forPreview)
                                .padding(.horizontal, 8)
                                .padding(.bottom, variantIndex < variants.prefix(maxSchedules).count  - 1 ? 3 : 0)
                        } else if (size == .accessoryRectangular) {
                            BusScheduleRow(schedule: matchingSchedule, size: size, fullyLoaded: fullyLoaded, forPreview: forPreview)
                        } else if (size == .systemSmall) {
                            BusScheduleRow(schedule: matchingSchedule, size: size, fullyLoaded: fullyLoaded, forPreview: forPreview)
                        }
                        
                        if ((size == .systemLarge || size == .systemSmall || ((scheduleData)?.count ?? 0 < 3 ) && size != .accessoryRectangular ) && fullyLoaded) {
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}



