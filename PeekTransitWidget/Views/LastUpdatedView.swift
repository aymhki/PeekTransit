import SwiftUI


struct LastUpdatedView: View {
    let updatedAt: Date
    let size: String
    
    var body: some View {
        let fontSizeToUse = getLastSeenFontSizeForWidgetSize(widgetSizeSystemFormat: nil, widgetSizeStringFormat: size)
        Text("Last updated at \(formattedTime)")
            .font(.system(size:  fontSizeToUse))
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: updatedAt)
    }
}
