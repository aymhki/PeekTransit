import SwiftUI

struct MoreTabView: View {
    @AppStorage(settingsUserDefaultsKeys.defaultTab) private var defaultTab: Int = 0

    private var contentView: some View {
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
                            HStack(spacing: 12) {
                                Image(systemName: tab.icon)
                                Text(tab.name)
                            }
                            .tag(tab.rawValue)
                        
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            Section("Legal") {
                
                NavigationLink(destination: TermsAndPrivacyView()) {
                    SettingsRow(
                        icon: "doc.on.doc.fill",
                        iconColor: .blue,
                        text: "Terms of Service & Privacy"
                    )
                }

                
                NavigationLink(destination: CreditsView()) {
                    SettingsRow(
                        icon: "person.2.fill",
                        iconColor: .indigo,
                        text: "Credits"
                    )
                }
            }
            
            Section("Info") {
                NavigationLink(destination: AboutView()) {
                    SettingsRow(
                        icon: "info.circle",
                        iconColor: .red,
                        text: "About"
                    )
                }
            }
        }
        .navigationTitle("More")
    }
    
    var body: some View {

        if isLargeDevice() {
            NavigationView {
                contentView
            }
        } else {
            NavigationStack {
                contentView
            }
        }
    }
}

