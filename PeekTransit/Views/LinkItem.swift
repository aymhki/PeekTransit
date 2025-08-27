import SwiftUI


struct LinkItem: View {
    let iconSystemName: String?
    let imageName: String?
    let text: String
    
    init(iconSystemName: String? = nil, imageName: String? = nil, text: String) {
        self.iconSystemName = iconSystemName
        self.imageName = imageName
        self.text = text
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if let systemName = iconSystemName {
                Image(systemName: systemName)
                    .font(.system(size: 30))
                    .frame(height: 30)
            } else if let imageName = imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            
            Text(text)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(.primary)
    }
}

