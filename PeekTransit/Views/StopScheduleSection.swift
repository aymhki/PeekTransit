import SwiftUI

struct StopScheduleSection: View {
    let stop: Stop
    let variants: [Variant]
    let selectedVariants: [Variant]
    let maxVariants: Int
    let onVariantSelect: (Variant) -> Void
    
    private func isVariantSelected(_ variant: Variant) -> Bool {
        selectedVariants.contains { selectedVariant in
            selectedVariant.key  == variant.key &&
            selectedVariant.name == variant.name
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(stop.name)
                        .font(.headline)
                    Text("#\(stop.number)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(selectedVariants.count)/\(maxVariants)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(variants, id: \.self) { variant in
                    
                    let variantKeyPieces = variant.key.split(separator: getVariantKeySeperator())
                    let finalVariantNumber = variantKeyPieces.first.map { String($0) } ?? variant.key
                    let finalFinalVariantNumber = finalVariantNumber.replacingOccurrences(of: "BLUE", with: "B")
                    
                    Button(action: {
                        onVariantSelect(variant)
                    }) {
                        HStack {
                            CircularCheckbox(isSelected: isVariantSelected(variant))
                                .padding(.trailing, 8)
                            
                            HStack(spacing: 16) {
                                Text(finalFinalVariantNumber)
                                    .font(.system(.body, design: .monospaced))
                                    .bold()
                                
                                Text(variant.name)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(1)
                                
                                Spacer()
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(selectedVariants.count >= maxVariants && !isVariantSelected(variant))
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGroupedBackground))
        )
    }
}

