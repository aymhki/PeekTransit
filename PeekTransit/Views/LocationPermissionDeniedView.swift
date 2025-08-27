import SwiftUI

struct LocationPermissionDeniedView: View {
    @State private var showSettingsAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Location Access Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Peek Transit needs your location to show nearby transit stops")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showSettingsAlert = true
            }) {
                Text("Enable Location Access")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(radius: 10)
        )
        .padding()
        .alert("Open Settings?", isPresented: $showSettingsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
        } message: {
            Text("You'll need to enable location access in Settings to use PeekTransit.")
        }
    }
}

