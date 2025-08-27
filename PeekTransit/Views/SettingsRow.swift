import SwiftUI

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .font(.subheadline)
            
            Text(text)
                .foregroundColor(.primary)
                .font(.subheadline)
        }
    }
}
