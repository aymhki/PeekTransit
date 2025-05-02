import SwiftUI

struct NameConfigurationStep: View {
    @Binding var widgetName: String
    let defaultName: String
    let editingWidget: Bool
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
                    .disableAutocorrection(true)
                    .autocorrectionDisabled(true)
                    .autocapitalization(.none)
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
                        if (!editingWidget) {
                            widgetName = defaultName
                        }
                    }
                    .frame(maxWidth: 300)
                

                
                if (editingWidget && widgetName != defaultName) {
                    
                    Button(action: {
                        widgetName = defaultName
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill( (!editingWidget || widgetName == defaultName) ? Color.gray : Color.blue)
                                .opacity((!editingWidget || widgetName == defaultName) ? 0.6 : 1)
                            
                            Text("Set the widget name to be the default name")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                        }
                    }
                    .disabled((!editingWidget || widgetName == defaultName))
                    .padding(.horizontal)
                    .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 120 : 90)
                    
                }
                
                Text("Default name: \(defaultName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                
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
