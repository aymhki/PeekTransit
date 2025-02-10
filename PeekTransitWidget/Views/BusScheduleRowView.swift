import SwiftUI
import WidgetKit

struct BusScheduleRow: View {
    let schedule: String
    let size: WidgetFamily
    let fullyLoaded: Bool
    let forPreview: Bool
    
    var body: some View {
        let components = schedule.components(separatedBy: getScheduleStringSeparator())
        if components.count >= 4 {
            HStack {
                Text(components[0])
                    .font(.system(size: fontSize, design: .monospaced))
                    .bold()
                
                if !components[1].isEmpty {
                    
                    if (size != .systemSmall && size != .accessoryRectangular) {
                        let routeName: String = components[1].components(separatedBy: .whitespaces).first?.trimmingCharacters(in: .whitespaces) as? String ?? "Unknown"
                        
                        Text(routeName.count > getMaxBusRouteLengthForWidget() ? routeName.prefix(getMaxBusRoutePrefixLengthForWidget()) + "..." : routeName)
                            .font(.system(size: fontSize - 2, design: .monospaced))
                            .bold()
                    
                    } else {
                        if (components[2] == getLateStatusTextString() || components[2] == getEarlyStatusTextString() || components[2] == getCancelledStatusTextString() || components[1].count > 3) {
                            
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
                
                if (components[2] == getLateStatusTextString() || components[2] == getEarlyStatusTextString() ||  components[2] == getCancelledStatusTextString()) {
                    if ( (size == .systemSmall || size == .accessoryRectangular) &&  components[2] != getCancelledStatusTextString() ) {
                        Text("\(components[2].prefix(1)).")
                            .foregroundColor((components[2] == getLateStatusTextString() || components[2] == getCancelledStatusTextString())  ? .red : .blue)
                            .font(.system(size: fontSize - 2, design: .monospaced))
                            .bold()
                        
                        
                    } else {
                        Text(components[2])
                            .foregroundColor((components[2] == getLateStatusTextString() || components[2] == getCancelledStatusTextString()) ? .red : .blue)
                            .font(.system(size: fontSize - 2, design: .monospaced))
                            .frame(alignment: .leading)
                            .bold()
                    }
                }
                    
                
                
                if (components[2] != getCancelledStatusTextString()) {
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
