import SwiftUI

struct AppIcon: View {
    var body: some View {
        if let iconFileName = Bundle.main.iconFileName,
           let uiImage = UIImage(named: iconFileName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}
