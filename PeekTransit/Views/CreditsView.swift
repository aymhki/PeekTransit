import SwiftUI

struct CreditsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
            
                
                VStack (spacing: 0) {
                    Text("App design inspired by:\n")
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Ryan Ramchandar")
                        .foregroundColor(.blue)
                        .underline()
                        .onTapGesture {
                            if let url = URL(string: "https://x.com/ryanramchandar") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                Text("Built using SwiftUI and Winnipeg Transit API")
                    .foregroundColor(.primary)
            }
            .padding()
        }
        .navigationTitle("Credits")
    }
}
