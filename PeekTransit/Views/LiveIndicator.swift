import SwiftUI

struct LiveIndicator: View {
    @State private var isAnimating = false
    let isAnimatingEnabled: Bool
    
    init(isAnimating: Bool) {
        self.isAnimatingEnabled = isAnimating
    }
    
    var body: some View {
        ZStack {
            if isAnimatingEnabled {
                
                Circle()
                    .fill(Color.red.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 6 : 1)
                    .opacity(isAnimating ? 0 : 0.9)
                    .animation(
                        .easeOut(duration: 3)
                        .repeatForever(autoreverses: false)
                        .delay(3),
                        value: isAnimating
                    )
            }
        
            Circle()
                .fill(isAnimatingEnabled ? Color.red : Color.accentColor)
                .frame(width: 8, height: 8)
        }
        .frame(width: 24, height: 24)
        .onAppear {
            isAnimating = isAnimatingEnabled
        }
        .onChange(of: isAnimatingEnabled) { newValue in
            isAnimating = newValue
        }
    }
}


