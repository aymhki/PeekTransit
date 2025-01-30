import SwiftUI

struct StopScheduleSection: View {
    let stop: [String: Any]
    let variants: [VariantSelectionStep.UniqueVariant]
    let selectedVariants: [[String: Any]]
    let maxVariants: Int
    let onVariantSelect: (VariantSelectionStep.UniqueVariant) -> Void
    
    private func isVariantSelected(_ variant: VariantSelectionStep.UniqueVariant) -> Bool {
        selectedVariants.contains { selectedVariant in
            selectedVariant["key"] as? String == variant.key &&
            selectedVariant["name"] as? String == variant.name
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(stop["name"] as? String ?? "Unknown Stop")
                        .font(.headline)
                    Text("#\(stop["number"] as? Int ?? 0)")
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
                    Button(action: {
                        onVariantSelect(variant)
                    }) {
                        HStack {
                            CircularCheckbox(isSelected: isVariantSelected(variant))
                                .padding(.trailing, 8)
                            
                            HStack(spacing: 16) {
                                Text(variant.key)
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

