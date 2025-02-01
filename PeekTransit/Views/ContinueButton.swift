import SwiftUI

struct ContinueButton: View {
    let title: String
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        let buttonHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 80 : 50

        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDisabled ? Color.gray : Color.blue)
                    .opacity(isDisabled ? 0.6 : 1)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
            }
        }
        .disabled(isDisabled)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .frame(height: buttonHeight)
    }
}

