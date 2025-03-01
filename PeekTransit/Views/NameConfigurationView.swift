import SwiftUI

struct NameConfigurationStep: View {
    @Binding var widgetName: String
    let defaultName: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Name Your Widget")
                    .font(.title2)
                    .bold()
                
                Text("Give your widget a name or use the default name generated for you.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Widget Name", text: $widgetName)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3),
                                lineWidth: 1
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemBackground))
                            )
                    )
                    .onAppear() {
                        widgetName = defaultName
                    }
                    .frame(maxWidth: 300)
                
                Text("Default name: \(defaultName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(radius: 2)
            )
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
}
