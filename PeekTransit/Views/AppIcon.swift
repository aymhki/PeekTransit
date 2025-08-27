import SwiftUI


struct AppIcon: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Image("AppIconForLaunchScreen")
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .preferredColorScheme(colorScheme == .dark ? .dark : .light)
    }
}

