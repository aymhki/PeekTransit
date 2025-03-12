import SwiftUI

struct WidgetRowView: View {
    let widgetData: [String: Any]
    let onTap: () -> Void
    let isEditing: Bool
    let isSelected: Bool
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        let showLastUpdatedStatus = widgetData["showLastUpdatedStatus"] as? Bool ?? true
        let timeFormatSelected = widgetData["timeFormat"] as? String ?? TimeFormat.default.formattedValue
        let timeFormatSelectedFinal = timeFormatSelected == TimeFormat.clockTime.formattedValue ? TimeFormat.clockTime : TimeFormat.minutesRemaining
        let multipleEntriesPerVariant = widgetData["multipleEntriesPerVariant"] as? Bool ?? true
        let (newSchedule, newWidgetData) = PreviewHelper.generatePreviewSchedule(from: widgetData, noConfig: false, timeFormat: timeFormatSelectedFinal, showLastUpdatedStatus:showLastUpdatedStatus, multipleEntriesPerVariant: multipleEntriesPerVariant ) ?? ([], [:])
        
        HStack(spacing: 12) {
            
            if isEditing {
                Spacer()
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                    
                    DynamicWidgetView(
                        widgetData: newWidgetData ?? [:],
                        scheduleData: newSchedule,
                        size: PreviewHelper.getWidgetSize(from: widgetData["size"] as? String ?? "medium"),
                        updatedAt: Date(),
                        fullyLoaded: true,
                        forPreview: true,
                        isLoading: false
                    )
                    
                    .if(themeManager.currentTheme == .classic) { view in
                        view.background(.black)
                    }
                    .padding(8)
                    .foregroundColor(Color.primary)
                    
                }
                
                .if(themeManager.currentTheme == .classic) { view in
                    view.background(.black)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: getWidgetPreviewWidthForSize(widgetSizeSystemFormat: nil, widgetSizeStringFormat: currentSize))
                .frame(height: getPreviewHeight())
                
                Spacer()
                
                Text(widgetData["name"] as? String ?? "Unnamed Widget")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding()
                
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
//        .onTapGesture {
//            onTap()
//        }
    }
    
    private func getPreviewHeight() -> CGFloat {
        let size = widgetData["size"] as? String ?? "medium"
        return getWidgetPreviewRowHeightForSize(widgetSizeSystemFormat: nil, widgetSizeStringFormat: size)
    }
}
