import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? 0
        var totalHeight: CGFloat = 0
        var currentLineWidth: CGFloat = 0
        var currentLineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentLineWidth + size.width > containerWidth {
                totalHeight += currentLineHeight + spacing
                currentLineWidth = size.width
                currentLineHeight = size.height
            } else {
                currentLineWidth += size.width + spacing
                currentLineHeight = max(currentLineHeight, size.height)
            }
        }
        
        totalHeight += currentLineHeight
        return CGSize(width: containerWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var currentLineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > bounds.maxX {
                currentY += currentLineHeight + spacing
                currentX = bounds.minX
                currentLineHeight = 0
            }
            
            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            
            currentX += size.width + spacing
            currentLineHeight = max(currentLineHeight, size.height)
        }
    }
}
