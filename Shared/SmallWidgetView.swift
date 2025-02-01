import SwiftUI

struct SmallWidgetView: View {
    let widgetData: [String: Any]
    let scheduleData: [String]?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let isClosestStop = widgetData["isClosestStop"] as? Bool {
                if isClosestStop {
                    if let schedules = scheduleData?.prefix(2) {
                        Text("Closest Stop")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ForEach(Array(schedules).indices, id: \.self) { index in
                            BusScheduleRow(schedule: Array(schedules)[index], size: "small")
                        }
                    }
                } else if let stops = widgetData["stops"] as? [[String: Any]],
                          let stop = stops.first {
                    Text(stop["name"] as? String ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let variants = stop["selectedVariants"] as? [[String: Any]] {
                        ForEach(variants.indices, id: \.self) { index in
                            let variant = variants[index]
                            if let key = variant["key"] as? String,
                               let schedules = scheduleData {
                                if let matchingSchedule = schedules.first(where: { $0.contains(key) }) {
                                    BusScheduleRow(schedule: matchingSchedule, size: "small")
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}
