import SwiftUI

struct StopLoadErrorView: View {
    let error: Error?
    let onRetry: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .padding(.bottom, 10)
                
                Text("Error Loading Stop")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(error?.localizedDescription ?? "Could not load stop information")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry")
                    }
                    .frame(minWidth: 120)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top, 20)
            }
            .padding()
            .navigationBarItems(trailing: Button("Close") {
                onClose()
            })
        }
    }
}
