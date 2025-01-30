import SwiftUI

struct VariantBadge: View {
    let route: [String: Any]
    let variant: [String: Any]
    
    private var variantNumber: String {
        if let key = variant["key"] as? String {
            return key.split(separator: "-")[0].description
        }
        return ""
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(variantNumber)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.3))
        .cornerRadius(8)
    }
}
