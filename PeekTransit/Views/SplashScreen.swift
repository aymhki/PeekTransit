import SwiftUI

struct SplashScreenView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding(.bottom, 10)
            
            Text("Welcome to Peek Transit")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Location Access")
                    .font(.headline)
                
                Text("This app needs access to your location to:")
                    .font(.subheadline)
                
                VStack(alignment: .leading, spacing: 10) {
                    BulletPoint(text: "Find nearby bus stops")
                    BulletPoint(text: "Show real-time bus schedules")
                    BulletPoint(text: "Display your location on the map")
                }
                
                Text("Privacy Note")
                    .font(.headline)
                    .padding(.top)
                
                Text("We do not collect, store, or share any personal information or location data. Your location is only used to show nearby stops in real-time.")
                    .font(.subheadline)
            }
            .padding()
            
            Button(action: onContinue) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .font(.subheadline)
            Text(text)
                .font(.subheadline)
        }
    }
}
