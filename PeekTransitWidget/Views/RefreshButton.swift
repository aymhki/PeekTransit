import SwiftUI
import WidgetKit
import AppIntents


struct RefreshButtonCircle: View {
    let diameter: CGFloat
    let isDisabled: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isDisabled ? Color(UIColor.systemGray3) : Color(UIColor.systemBlue))
            
            Image(systemName: "arrow.clockwise")
                .font(.system(size: diameter * 0.5, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: diameter, height: diameter)
    }
}


struct RefreshHitboxLabel: View {
    let family: WidgetFamily
    let containerSize: CGSize
    let isDisabled: Bool
    let borderColor: Color
    
    private var hitboxSize: CGSize {
        switch family {
        case .systemMedium:
            return CGSize(width: containerSize.width * 0.25, height: containerSize.height)
        case .systemSmall:
            return CGSize(width: containerSize.width, height: containerSize.height * 0.25)
        default:
            let side = getRefreshButtonDiameter(for: family) + getRefreshButtonInset(for: family) * 2
            return CGSize(width: side, height: side)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Rectangle()
                .fill(Color.black.opacity(0.001))
            
            RefreshButtonCircle(diameter: getRefreshButtonDiameter(for: family), isDisabled: isDisabled)
                .padding(getRefreshButtonInset(for: family))
        }
        .frame(width: hitboxSize.width, height: hitboxSize.height)
        .contentShape(Rectangle())
        .overlay(
            Rectangle()
                .stroke(borderColor, lineWidth: 1)
                .opacity(getShowRefreshButtonHitboxBorder() ? 1 : 0)
        )
    }
}


struct RefreshToggleStyle: ToggleStyle {
    let family: WidgetFamily
    let containerSize: CGSize
    let isCoolingDown: Bool
    let borderColor: Color
    let lastUpdatedContent: ((Bool) -> AnyView)?
    
    func makeBody(configuration: Configuration) -> some View {
        let isBusy = configuration.isOn
        
        return RefreshHitboxLabel(
            family: family,
            containerSize: containerSize,
            isDisabled: isBusy || isCoolingDown,
            borderColor: borderColor
        )
        .overlay(alignment: .bottomTrailing) {
            if let lastUpdatedContent = lastUpdatedContent {
                lastUpdatedContent(isBusy)
                    .frame(width: max(containerSize.width - 16, 0), alignment: .center)
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
            }
        }
    }
}


struct RefreshButtonOverlay: View {
    let widgetId: String?
    let family: WidgetFamily
    let isLoading: Bool
    let isCoolingDown: Bool
    let forPreview: Bool
    let borderColor: Color
    let containerSize: CGSize
    let lastUpdatedContent: ((Bool) -> AnyView)?
    
    private var interactiveWidgetId: String? {
        guard !forPreview, let widgetId = widgetId, !widgetId.isEmpty else {
            return nil
        }
        
        return widgetId
    }
    
    private var staticLabel: some View {
        RefreshHitboxLabel(
            family: family,
            containerSize: containerSize,
            isDisabled: isLoading || isCoolingDown,
            borderColor: borderColor
        )
    }
    
    var body: some View {
        Group {
            if #available(iOS 17.0, *) {
                if let interactiveWidgetId = interactiveWidgetId {
                    Toggle(isOn: isLoading, intent: RefreshTimelineIntent(widgetId: interactiveWidgetId)) {
                        EmptyView()
                    }
                    .toggleStyle(
                        RefreshToggleStyle(
                            family: family,
                            containerSize: containerSize,
                            isCoolingDown: isCoolingDown,
                            borderColor: borderColor,
                            lastUpdatedContent: lastUpdatedContent
                        )
                    )
                    .disabled(isCoolingDown)
                } else {
                    staticLabel
                }
            } else {
                staticLabel
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
}


extension View {
    @ViewBuilder
    func refreshInvalidatable(_ isEnabled: Bool) -> some View {
        if #available(iOS 17.0, *) {
            if isEnabled {
                self
                    .invalidatableContent()
                    .contentTransition(.identity)
            } else {
                self
            }
        } else {
            self
        }
    }
}
