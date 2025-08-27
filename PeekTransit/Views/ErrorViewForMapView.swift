import SwiftUI
import Foundation
import MapKit

struct ErrorViewForMapView: View {
    let error: Error
    let onRetry: () -> Void
    
    var body: some View {
        VStack {
            Text("Error loading stops")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.subheadline)
            Button("Retry", action: onRetry)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground).opacity(1))
        .cornerRadius(8)
    }
}
