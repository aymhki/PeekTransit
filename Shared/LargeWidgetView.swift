import SwiftUI


struct LargeWidgetView: View {
    let widgetData: [String: Any]
    let scheduleData: [String]?
    
    var body: some View {
        VStack(alignment: .leading) {
            if let isClosestStop = widgetData["isClosestStop"] as? Bool {
                if isClosestStop {
                    Text("Closest Stops")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let schedules = scheduleData {
                        ForEach(Array(schedules.prefix(6)).indices, id: \.self) { index in
                            BusScheduleRow(schedule: schedules[index], size: "large")
                        }
                    }
                } else if let stops = widgetData["stops"] as? [[String: Any]] {
                    ForEach(Array(stops.prefix(3)).indices, id: \.self) { index in
                        let stop = stops[index]
                        VStack(alignment: .leading) {
                            Text(stop["name"] as? String ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let variants = stop["selectedVariants"] as? [[String: Any]] {
                                ForEach(variants.indices, id: \.self) { variantIndex in
                                    let variant = variants[variantIndex]
                                    if let key = variant["key"] as? String,
                                       let schedules = scheduleData {
                                        if let matchingSchedule = schedules.first(where: { $0.contains(key) }) {
                                            BusScheduleRow(schedule: matchingSchedule, size: "large")
                                        }
                                    }
                                }
                            }
                        }
                        
                        if index < stops.prefix(3).count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
    }
}
