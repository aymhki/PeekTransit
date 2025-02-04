import SwiftUI
import WidgetKit


struct DynamicWidgetView: View {
    let widgetData: [String: Any]
    let scheduleData: [String]?
    let size: WidgetFamily
    let updatedAt: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 2)
            
            LastUpdatedView(updatedAt: updatedAt, size: size == .systemSmall ? "small" : size == .systemMedium ? "medium" : size == .systemLarge ? "large" : "lockscreen")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 4, trailing: 8))
    }
    
    @ViewBuilder
    private var content: some View {
        if let isClosestStop = widgetData["isClosestStop"] as? Bool {
            if isClosestStop {
                closestStopView
            } else {
                selectedStopsView
            }
        }
    }
    
    
    @ViewBuilder
    private var closestStopView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Closest Stop")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
            
            if let schedules = scheduleData {
                ForEach(Array(schedules.prefix(maxSchedules)).indices, id: \.self) { index in
                    BusScheduleRow(schedule: schedules[index], size: size)
                }
            }
        }
    }
    
    @ViewBuilder
    private var selectedStopsView: some View {
        if let stops = widgetData["stops"] as? [[String: Any]] {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(stops.prefix(maxStops)).indices, id: \.self) { stopIndex in
                    let stop = stops[stopIndex]
                    StopView(stop: stop, scheduleData: scheduleData, size: size)
                    
                    if stopIndex < stops.prefix(maxStops).count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
    
    private var maxStops: Int {
        switch size {
        case .systemLarge: return 3
        case .systemMedium: return 2
        case .systemSmall: return 1
        case .accessoryRectangular: return 2
        default: return 1
        }
    }
    
    private var maxSchedules: Int {
        switch size {
        case .systemLarge: return 2
        case .systemMedium: return 2
        case .systemSmall: return 1
        case .accessoryRectangular: return 1
        default: return 1
        }
    }
}

struct BusScheduleRow: View {
    let schedule: String
    let size: WidgetFamily
    
    var body: some View {
        let components = schedule.components(separatedBy: " ---- ")
        if components.count >= 4 {
            HStack {
                Text(components[0])
                    .font(.system(size: fontSize, design: .monospaced))
                    .bold()
                
                if !components[1].isEmpty {
                    
                    if (size != .systemSmall && size != .accessoryRectangular) {
                        Text(components[1])
                            .font(.system(size: fontSize - 2, design: .monospaced))
                            .padding(.leading, 2)
                    
                    } else {
                        Text("\(components[1].prefix(1)).")
                            .font(.system(size: fontSize - 2, design: .monospaced))
                            .padding(.leading, 2)
                    }
                }
                
                Spacer()
                
                if components[2] == "Late" || components[2] == "Early" {
                    if (size == .systemSmall || size == .accessoryRectangular) {
                        Text("\(components[2].prefix(1)).")
                            .foregroundColor(components[2] == "Late" ? .red : .yellow)
                            .font(.system(size: fontSize - 2, design: .monospaced))
                        
                    } else {
                        Text(components[2])
                            .foregroundColor(components[2] == "Late" ? .red : .yellow)
                            .font(.system(size: fontSize - 2, design: .monospaced))
                    }
                }
                
                Text(components[3])
                    .font(.system(size: fontSize, design: .monospaced))
                    .bold()
            }
        }
    }
    
    private var fontSize: CGFloat {
        switch size {
        case .systemLarge: return 16
        case .systemMedium: return 15
        case .systemSmall: return 12
        case .accessoryRectangular: return 10
        default: return 10
        }
    }
}

struct StopView: View {
    let stop: [String: Any]
    let scheduleData: [String]?
    let size: WidgetFamily
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stop["name"] as? String ?? "")
                .font(.system(.caption2))
            
            if (size == .systemLarge || size == .systemSmall) {
                Spacer()
            }
            
            if let variants = stop["selectedVariants"] as? [[String: Any]] {
                ForEach(variants.prefix(2).indices, id: \.self) { variantIndex in
                    if let key = variants[variantIndex]["key"] as? String,
                       let schedules = scheduleData,
                       let matchingSchedule = schedules.first(where: { $0.contains(key) }) {
                        BusScheduleRow(schedule: matchingSchedule, size: size)
                            .padding(.horizontal, 10)
                        
                        if (size == .systemLarge || size == .systemSmall) {
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}


struct LastUpdatedView: View {
    let updatedAt: Date
    let size: String
    
    var body: some View {
        Text("Last updated at \(formattedTime)")
            .font(.system(size:  size == "small" ? 10 : 12))
            .frame(alignment: .center)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: updatedAt)
    }
}
