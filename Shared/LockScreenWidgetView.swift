import SwiftUI
import WidgetKit
import SwiftUI

struct LockScreenWidgetView: View {
    let widgetData: [String: Any]
    let scheduleData: [String]?
    
    var body: some View {
        VStack(spacing: 4) {
            if let isClosestStop = widgetData["isClosestStop"] as? Bool,
               let schedules = scheduleData {
                if isClosestStop {
                    ForEach(Array(schedules.prefix(2)).indices, id: \.self) { index in
                        let schedule = schedules[index]
                        let components = schedule.components(separatedBy: " ---- ")
                        if components.count >= 4 {
                            HStack {
                                Text(components[0]) // Bus key
                                    .bold()
                                Text(String(components[1].prefix(1))) // First letter of variant
                                Text(components[3]) // Arrival time
                            }
                        }
                    }
                } else {
                    if let stops = widgetData["stops"] as? [[String: Any]] {
                        ForEach(stops.indices, id: \.self) { stopIndex in
                            let stop = stops[stopIndex]
                            if let variants = stop["selectedVariants"] as? [[String: Any]] {
                                ForEach(variants.indices, id: \.self) { variantIndex in
                                    let variant = variants[variantIndex]
                                    if let key = variant["key"] as? String,
                                       let name = variant["name"] as? String {
                                        HStack {
                                            Text(key).bold()
                                            Text(String(name.prefix(1)))
                                            if let matchingSchedule = schedules.first(where: { $0.contains(key) }) {
                                                let components = matchingSchedule.components(separatedBy: " ---- ")
                                                if components.count >= 4 {
                                                    Text(components[3])
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
