import SwiftUI


struct ErrorViewForAddressSearch: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Error")
                .font(.headline)
            Text(message)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                onDismiss()
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }
}

