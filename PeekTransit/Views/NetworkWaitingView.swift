import SwiftUI

struct NetworkWaitingView: View {
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Waiting for connection...")
                .foregroundColor(.secondary)
            
//            Button("Retry") {
//                onRetry()
//            }
//            .buttonStyle(.bordered)
        }
    }
}
