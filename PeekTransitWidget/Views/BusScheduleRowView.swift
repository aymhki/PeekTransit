import SwiftUI
import WidgetKit

struct BusScheduleRow: View {
    let schedule: String
    let size: WidgetFamily
    let fullyLoaded: Bool
    
    var body: some View {
        let components = schedule.components(separatedBy: " ---- ")
        if components.count >= 4 {
            HStack {
                Text(components[0])
                    .font(.system(size: fontSize, design: .monospaced))
                    .bold()
                
                if !components[1].isEmpty {
                    
                    if (size != .systemSmall && size != .accessoryRectangular) {
                        Text(components[1].count > getMaxBusRouteLengthForWidget() ? components[1].prefix(getMaxBusRoutePrefixLengthForWidget()) + "..." : components[1])
                            .font(.system(size: fontSize - 2, design: .monospaced))
                            .bold()
                    
                    } else {
                        if (components[2] == "Late" || components[2] == "Early" || components[2] == "Cancelled" || components[1].count > 3) {
                            
                            Text("\(components[1].prefix(1)).")
                                .font(.system(size: fontSize - 2, design: .monospaced))
                                .bold()
                        } else {
                            Text(components[1])
                                .font(.system(size: fontSize - 2, design: .monospaced))
                                .bold()
                        }
                        
                    }
                }
                
                if (fullyLoaded && size != .systemSmall && size != .accessoryRectangular) {
                    Spacer()
                }
                
                if (components[2] == "Late" || components[2] == "Early" ||  components[2] == "Cancelled") {
                    if ( (size == .systemSmall || size == .accessoryRectangular) &&  components[2] != "Cancelled" ) {
                        Text("\(components[2].prefix(1)).")
                            .foregroundColor((components[2] == "Late" || components[2] == "Cancelled")  ? .red : .blue)
                            .font(.system(size: fontSize - 2, design: .monospaced))
                            .bold()
                        
                        
                    } else {
                        Text(components[2])
                            .foregroundColor((components[2] == "Late" || components[2] == "Cancelled") ? .red : .blue)
                            .font(.system(size: fontSize - 2, design: .monospaced))
                            .frame(alignment: .leading)
                            .bold()
                    }
                }
                    
                
                
                if (components[2] != "Cancelled") {
                    Text(components[3])
                        .font(.system(size: fontSize - 2, design: .monospaced))
                        .bold()
                        .frame(alignment: .leading)
                }
            }
            
        }
    }
    
    private var fontSize: CGFloat {
        return getNormalFontSizeForWidgetSize(widgetSizeSystemFormat: size, widgetSizeStringFormat: nil)
    }
    
}
