import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? 0
        guard !subviews.isEmpty else { return .zero }
        
        var totalHeight: CGFloat = 0
        var currentLineWidth: CGFloat = 0
        var currentLineHeight: CGFloat = 0
        var isFirstItem = true
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let needsNewLine = !isFirstItem && (currentLineWidth + spacing + size.width > containerWidth)
            
            if needsNewLine {
                totalHeight += currentLineHeight
                
                if totalHeight > 0 {
                    totalHeight += spacing
                }

                currentLineWidth = size.width
                currentLineHeight = size.height
            } else {
                if !isFirstItem {
                    currentLineWidth += spacing
                }
                currentLineWidth += size.width
                currentLineHeight = max(currentLineHeight, size.height)
            }
            
            isFirstItem = false
        }
        
        totalHeight += currentLineHeight
        
        return CGSize(width: containerWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        
        var currentX = bounds.minX
        var currentY = bounds.minY
        var currentLineHeight: CGFloat = 0
        var isFirstItemInLine = true
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            let needsNewLine = !isFirstItemInLine && (currentX + spacing + size.width > bounds.maxX)
            
            if needsNewLine {
                currentY += currentLineHeight + spacing
                currentX = bounds.minX
                currentLineHeight = 0
                isFirstItemInLine = true
            }
            
            if !isFirstItemInLine {
                currentX += spacing
            }
            
            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            
            currentX += size.width
            currentLineHeight = max(currentLineHeight, size.height)
            isFirstItemInLine = false
        }
    }
}

