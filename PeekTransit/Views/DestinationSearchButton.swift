import SwiftUI
import MapKit
import Combine

struct DestinationSearchButton: View {
    @Binding var isSearching: Bool
    @State private var buttonWidth: CGFloat = 230
    @State private var buttonPosition: CGFloat = 0
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isSearching = true
            }
        }) {
            HStack {
                Image(systemName: "bus.fill")
                    .font(.caption)
                Text("Don't know which bus to take?")
                    .font(.caption)
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(.blue)
            .clipShape(Capsule())
            .shadow(radius: 3)
        }
    }
}
