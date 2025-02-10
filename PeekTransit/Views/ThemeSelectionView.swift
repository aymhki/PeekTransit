
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

struct ThemePreviewCard: View {
    let theme: StopViewTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                
                VStack(alignment: .leading) {
                    Text(theme.rawValue)
                        .font(.title3)
                    
                    Text(theme.description)
                        .font(.body)
                }
                .padding()
                
                PreviewContent(theme: theme)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
            .stopViewTheme(theme, text: "")
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PreviewContent: View {
    let theme: StopViewTheme
    
    var body: some View {
        VStack (alignment: .leading, spacing: 10) {
            HStack  {
                Text("671")
                    .stopViewTheme(theme, text: "")
                
                
                Text("Prairie Point")
                    .stopViewTheme(theme, text: "")
                
                Spacer()
                
                Text(getLateStatusTextString())
                    .stopViewTheme(theme, text: getLateStatusTextString())
                
                
                Text("1 min.")
                    .stopViewTheme(theme, text: "")
                
            }
            .padding(.horizontal, 16)
            .stopViewTheme(theme, text: "")
            
            HStack  {
                Text("B")
                    .stopViewTheme(theme, text: "")
                
                
                Text("Downtown")
                    .stopViewTheme(theme, text: "")
                
                Spacer()
                Text(getEarlyStatusTextString())
                    .stopViewTheme(theme, text: getEarlyStatusTextString())
                
                
                Text("11:15 AM")
                    .stopViewTheme(theme, text: "")
            }
            .padding(.horizontal, 16)
            .stopViewTheme(theme, text: "")
            
            HStack {
                Text("47")
                    .stopViewTheme(theme, text: "")
                
                
                Text("U of M")
                    .stopViewTheme(theme, text: "")
                
                Spacer()
                
                Text(getCancelledStatusTextString())
                    .stopViewTheme(theme, text: getCancelledStatusTextString())
            }
            .padding(.horizontal, 16)
            .stopViewTheme(theme, text: "")
        
        }
        .stopViewTheme(theme, text: "")
        
    }
}

