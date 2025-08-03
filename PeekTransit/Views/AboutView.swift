import SwiftUI



struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 120), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            
            
            
            VStack(spacing: 24) {
                Spacer(minLength: 30)
                
                AppIcon()
                
                VStack(spacing: 8) {
                    Text("Peek Transit")
                        .font(.title2.bold())
                    Text("by Ayman Agamy")
                        .foregroundColor(.secondary)
                    Text("agamyahk@myumanitoba")
                        .foregroundColor(.secondary)
                    Text("Version \(appVersion) (\(buildNumber))")
                        .foregroundColor(.secondary)
                }
                
                LazyVGrid(columns: columns, spacing: 20) {
                    Link(destination: URL(string: "mailto:agamyahk@myumanitoba.ca")!) {
                        LinkItem(iconSystemName: "envelope.fill", text: "Email")
                    }
                    
                    
                    Link(destination: URL(string: "https://github.com/aymhki")!) {
                        LinkItem(imageName: "GithubIconSVG", text: "GitHub")
                    }
                }
                .padding(.horizontal)
                
                Text("User ID: \(UIDevice.current.identifierForVendor?.uuidString ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("About")
    }
}
