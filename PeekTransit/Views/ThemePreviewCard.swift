import SwiftUI

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
