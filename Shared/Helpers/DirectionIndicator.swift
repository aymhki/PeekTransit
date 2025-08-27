import SwiftUI



struct DirectionIndicator: View {
    let direction: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(getColor())
            
            Image(systemName: getIconName())
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private func getColor() -> Color {
        switch direction.lowercased() {
        case "southbound":
            return Color.green
        case "northbound":
            return Color.orange
        case "eastbound":
            return Color.pink
        case "westbound":
            return Color.blue
        default:
            return Color.gray
        }
    }
    
    private func getIconName() -> String {
        switch direction.lowercased() {
        case "southbound":
            return "arrow.down"
        case "northbound":
            return "arrow.up"
        case "eastbound":
            return "arrow.right"
        case "westbound":
            return "arrow.left"
        default:
            return "mappin"
        }
    }
}
