import SwiftUI


struct ContentBackgroundColor: View {
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.12, green: 0.12, blue: 0.12) : Color(red: 0.96, green: 0.94, blue: 0.90)
    }
    
    var body: some View {
        backgroundColor
    }
}
