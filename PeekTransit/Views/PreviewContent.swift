import SwiftUI

struct PreviewContent: View {
    let theme: StopViewTheme
    
    var body: some View {
        VStack (alignment: .leading, spacing: 10) {
            HStack  {
                Text("671")
                    .stopViewTheme(theme, text: "")
                
                
                Text("Prairie Point")
                    .stopViewTheme(theme, text: "")
                
                Spacer()
                
                Text(getLateStatusTextString())
                    .stopViewTheme(theme, text: getLateStatusTextString())
                
                
                Text("1 min.")
                    .stopViewTheme(theme, text: "")
                
            }
            .padding(.horizontal, 16)
            .stopViewTheme(theme, text: "")
            
            HStack  {
                Text("B")
                    .stopViewTheme(theme, text: "")
                
                
                Text("Downtown")
                    .stopViewTheme(theme, text: "")
                
                Spacer()
                Text(getEarlyStatusTextString())
                    .stopViewTheme(theme, text: getEarlyStatusTextString())
                
                
                Text("11:15 AM")
                    .stopViewTheme(theme, text: "")
            }
            .padding(.horizontal, 16)
            .stopViewTheme(theme, text: "")
            
            HStack {
                Text("47")
                    .stopViewTheme(theme, text: "")
                
                
                Text("U of M")
                    .stopViewTheme(theme, text: "")
                
                Spacer()
                
                Text(getCancelledStatusTextString())
                    .stopViewTheme(theme, text: getCancelledStatusTextString())
            }
            .padding(.horizontal, 16)
            .stopViewTheme(theme, text: "")
        
        }
        .stopViewTheme(theme, text: "")
        
    }
}

