import SwiftUI


struct WidgetErrorView: View {
    let message: String
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.title3)
            Text(message)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .foregroundColor(.red)
    }
}
