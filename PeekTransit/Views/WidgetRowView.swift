import SwiftUI

import SwiftUI

struct WidgetRowView: View {
    let widgetData: [String: Any]
    let onTap: () -> Void
    let isEditing: Bool
    let isSelected: Bool
    
    var body: some View {
        let (newSchedule, newWidgetData) = PreviewHelper.generatePreviewSchedule(from: widgetData, noConfig: false) ?? ([], [:])
        
        HStack(spacing: 12) {
            if isEditing {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            
            VStack(spacing: 8) {
                let currentSize = widgetData["size"] as? String ?? "medium"
                
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(radius: 2)
                    
                    DynamicWidgetView(
                        widgetData: newWidgetData ?? [:],
                        scheduleData: newSchedule,
                        size: PreviewHelper.getWidgetSize(from: widgetData["size"] as? String ?? "medium"),
                        updatedAt: Date(),
                        fullyLoaded: true,
                        forPreview: true
                    )
                    .padding(.horizontal, 8)
                }
                .frame(maxWidth: currentSize == "small" || currentSize == "lockscreen" ? 170 : .infinity)
                .frame(height: getPreviewHeight())
                
                Spacer()
                
                Text(widgetData["name"] as? String ?? "Unnamed Widget")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Divider()
            }
        }
        .contentShape(Rectangle()) // Makes the entire row tappable
        .onTapGesture {
            onTap()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private func getPreviewHeight() -> CGFloat {
        let size = widgetData["size"] as? String ?? "medium"
        switch size.lowercased() {
        case "small":
            return 180
        case "large":
            return 380
        case "lockscreen":
            return 100
        default:
            return 180
        }
    }
}
