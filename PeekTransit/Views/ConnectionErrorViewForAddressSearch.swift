import SwiftUI

struct ConnectionErrorViewForAddressSearch: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.title)
            Text(message)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }
}

