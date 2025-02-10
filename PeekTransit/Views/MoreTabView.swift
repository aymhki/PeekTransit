import SwiftUI

struct MoreTabView: View {
    @AppStorage(settingsUserDefaultsKeys.defaultTab) private var defaultTab: Int = 0
    
    var body: some View {
        NavigationView {
            List {
                Section("Variables") {
                    NavigationLink(destination: ThemeSelectionView()) {
                        SettingsRow(
                            icon: "paintbrush.fill",
                            iconColor: .purple,
                            text: "Change App & Widget Theme"
                        )
                    }
                    
                    HStack {
                        SettingsRow(
                            icon: "apps.iphone",
                            iconColor: .blue,
                            text: "Default Tab"
                        )
                        
                        Spacer()
                        
                        Picker("", selection: $defaultTab) {
                            ForEach(DefaultTab.allCases) { tab in
                                Label(tab.name, systemImage: tab.icon)
                                    .tag(tab.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section("Legal") {
                    
                    NavigationLink(destination: Text("Terms of Service")) {
                        SettingsRow(
                            icon: "doc.on.doc.fill",
                            iconColor: .blue,
                            text: "Terms of Service"
                        )
                    }
                    
                    NavigationLink(destination: Text("Privacy")) {
                        SettingsRow(
                            icon: "doc.on.doc.fill",
                            iconColor: .blue,
                            text: "Terms of Service"
                        )
                    }
                    
                    NavigationLink(destination: Text("Credits")) {
                        SettingsRow(
                            icon: "person.2.fill",
                            iconColor: .indigo,
                            text: "Credits"
                        )
                    }
                }
                
                Section("Info") {
                    NavigationLink(destination: Text("Author")) {
                        SettingsRow(
                            icon: "person.fill",
                            iconColor: .red,
                            text: "Author"
                        )
                    }
                }
            }
            .navigationTitle("More")
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text(text)
                .font(.system(.body))
        }
    }
}

