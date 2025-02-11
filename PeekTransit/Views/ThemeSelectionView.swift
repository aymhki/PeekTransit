
import SwiftUI

struct ThemeSelectionView: View {
    @State private var selectedTheme: StopViewTheme
    private let sharedDefaults = SharedDefaults.userDefaults
    @EnvironmentObject private var themeManager: ThemeManager

    
    init() {
        let savedTheme = SharedDefaults.userDefaults?.string(forKey: settingsUserDefaultsKeys.sharedStopViewTheme) ?? StopViewTheme.default.rawValue
        _selectedTheme = State(initialValue: StopViewTheme(rawValue: savedTheme) ?? .default)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Select a Theme")
                    .font(.title.bold())
                    .padding([.top, .bottom])
                
                Text("Note: This preview is only for color, font, and theme changes. The layout, size, and spacing between text elements will be different in the bus stop page and the widget elements")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                ForEach(StopViewTheme.allCases, id: \.id) { theme in
                    ThemePreviewCard(
                        theme: theme,
                        isSelected: themeManager.currentTheme == theme,
                        action: {
                            themeManager.updateTheme(theme)
                        }
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Stop View Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}

