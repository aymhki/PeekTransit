import SwiftUI


struct LastUpdatedView: View {
    let updatedAt: Date
    let size: String

    
    var body: some View {
        let fontSizeToUse = getLastSeenFontSizeForWidgetSize(widgetSizeSystemFormat: nil, widgetSizeStringFormat: size)
        
        if (size == "lockscreen" || size == "small") {
            Text("Updated at \(formattedTime)")
                .font(.system(size:  fontSizeToUse))
        } else {
            Text("Last updated at \(formattedTime)")
                .font(.system(size:  fontSizeToUse))
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: updatedAt)
    }
}
