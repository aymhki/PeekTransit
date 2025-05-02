import SwiftUI
struct WidgetRowView: View {
    let widgetData: [String: Any]
    let onTap: () -> Void
    let isEditing: Bool
    let isSelected: Bool
    var onDelete: (() -> Void)?
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        let showLastUpdatedStatus = widgetData["showLastUpdatedStatus"] as? Bool ?? true
        let timeFormatSelected = widgetData["timeFormat"] as? String ?? TimeFormat.default.formattedValue
        let timeFormatSelectedFinal = timeFormatSelected == TimeFormat.clockTime.formattedValue ? TimeFormat.clockTime : TimeFormat.minutesRemaining
        let multipleEntriesPerVariant = widgetData["multipleEntriesPerVariant"] as? Bool ?? true
        let (newSchedule, newWidgetData) = PreviewHelper.generatePreviewSchedule(from: widgetData, noConfig: false, timeFormat: timeFormatSelectedFinal, showLastUpdatedStatus:showLastUpdatedStatus, multipleEntriesPerVariant: multipleEntriesPerVariant, showLateTextStatus: false ) ?? ([], [:])
        
        HStack(spacing: 12) {
            if isEditing {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
                    .frame(width: 44) // Fixed width for consistent alignment
                    .padding(.leading, 16)
            }
            
            VStack() {
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
                //.clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: getWidgetPreviewWidthForSize(widgetSizeSystemFormat: nil, widgetSizeStringFormat: currentSize))
                .frame(height: getPreviewHeight())
                
                Spacer()
            
                Text(widgetData["name"] as? String ?? "Unnamed Widget")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding()
                    
                if !isEditing {
                    HStack(spacing: 20) {

                        CircularIconButton(
                            iconName: "trash",
                            backgroundColor: .red,
                            action: { if let onDelete = onDelete { onDelete() } }
                        )
                        .padding(.horizontal)
  
                        CircularIconButton(
                            iconName: "square.and.pencil",
                            backgroundColor: .blue,
                            action: onTap
                        )
                        .padding(.horizontal)
                
                    }
                    .padding(.bottom)
                }
            }
            .padding()
            
            if isEditing {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditing {
                onTap()
            }
        }
    }
    
    private func getPreviewHeight() -> CGFloat {
        let size = widgetData["size"] as? String ?? "medium"
        return getWidgetPreviewRowHeightForSize(widgetSizeSystemFormat: nil, widgetSizeStringFormat: size)
    }
}

struct CircularIconButton: View {
    let iconName: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 44, height: 44)
                
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
