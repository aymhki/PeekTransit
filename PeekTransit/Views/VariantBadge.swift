import SwiftUI

struct VariantBadge: View {
    let variant: Variant
    let showFullVariantKey: Bool
    let showVariantName: Bool
    
    private var variantNumber: String {
        if showFullVariantKey {
            return variant.key
        } else {
            return variant.key.split(separator: "-")[0].description
        }
    }
    
    private var finalTextToShow: String {
        if showVariantName {
            return "\(variantNumber) - \(variant.name)"
        } else {
            return variantNumber
        }
    }
    
    var body: some View {
        if variant.textColor != nil  && variant.backgroundColor != nil  && variant.borderColor != nil {
            HStack(spacing: 4) {
                Text(finalTextToShow)
                    .fontWeight(.bold)
                    .font(.caption)
                    .foregroundColor(variant.textColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(variant.backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(variant.borderColor ?? Color.clear, lineWidth: 1)
            )
            
        } else {
            HStack(spacing: 4) {
                Text(finalTextToShow)
                    .fontWeight(.bold)
                    .font(.caption)
                
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor)
            .cornerRadius(8)
        }
    }
}
