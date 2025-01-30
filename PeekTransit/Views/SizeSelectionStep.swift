import SwiftUI

struct SizeSelectionStep: View {
    @Binding var selectedSize: String
    @State private var isLoading = true
    
    private let availableSizes = [
        "small",
        "medium",
        "large",
        "lockscreen"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Select Widget Size")
                .font(.title2)
                .padding(.top)
            
            Picker("Widget Size", selection: $selectedSize) {
                ForEach(availableSizes, id: \.self) { size in
                    Text(size.capitalized)
                        .tag(size)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            ZStack {
                if isLoading {
                    ProgressView("Loading preview...")
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(radius: 2)
                    
                    Text("Size: \(selectedSize)")
                        .font(.headline)
                }
                .opacity(isLoading ? 0 : 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .padding()
            
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
}
