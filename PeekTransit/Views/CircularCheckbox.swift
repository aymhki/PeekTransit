import SwiftUI

struct CircularCheckbox: View {
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                .frame(width: 24, height: 24)
            
            if isSelected {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 20, height: 20)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 24, height: 24)
    }
}
