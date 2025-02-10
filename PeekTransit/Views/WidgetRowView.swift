import SwiftUI

struct WidgetRowView: View {
    let widgetData: [String: Any]
    let onTap: () -> Void
    let isEditing: Bool
    let isSelected: Bool
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        let showLastUpdatedStatus = widgetData["showLastUpdatedStatus"] as? Bool ?? true
        let timeFormatSelected = widgetData["timeFormat"] as? String ?? TimeFormat.default.rawValue
        let timeFormatSelectedFinal = timeFormatSelected == TimeFormat.clockTime.rawValue ? TimeFormat.clockTime : TimeFormat.minutesRemaining
        let (newSchedule, newWidgetData) = PreviewHelper.generatePreviewSchedule(from: widgetData, noConfig: false, timeFormat: timeFormatSelectedFinal, showLastUpdatedStatus:showLastUpdatedStatus ) ?? ([], [:])
        
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
                        .fill(Color(themeManager.currentTheme == .classic ? .black : .secondarySystemGroupedBackground))
                        .shadow(radius: 2)
                    
                    DynamicWidgetView(
                        widgetData: newWidgetData ?? [:],
                        scheduleData: newSchedule,
                        size: PreviewHelper.getWidgetSize(from: widgetData["size"] as? String ?? "medium"),
                        updatedAt: Date(),
                        fullyLoaded: true,
                        forPreview: true
                    )
                    .if(themeManager.currentTheme == .classic) { view in
                        view.background(.black)
                    }
                    .padding()
                }
                .if(themeManager.currentTheme == .classic) { view in
                    view.background(.black)
                }
                .frame(maxWidth: getWidgetPreviewWidthForSize(widgetSizeSystemFormat: nil, widgetSizeStringFormat: currentSize))
                .frame(height: getPreviewHeight())
                
                Spacer()
                
                Text(widgetData["name"] as? String ?? "Unnamed Widget")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Divider()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private func getPreviewHeight() -> CGFloat {
        let size = widgetData["size"] as? String ?? "medium"
        return getWidgetPreviewRowHeightForSize(widgetSizeSystemFormat: nil, widgetSizeStringFormat: size)
    }
}
