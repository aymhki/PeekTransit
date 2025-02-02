import SwiftUI



struct WidgetRowView: View {
    let widgetData: [String: Any]
    
    var body: some View {
        Group {
                Text("\(widgetData["name"] ?? "Wtv for now")")
        }
    }
    
}
