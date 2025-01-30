import SwiftUI
import MapKit


struct RetroBoard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(.black.opacity(0.1))
                    .overlay(
                        GeometryReader { geometry in
                            Path { path in
                                for y in stride(from: 0, to: geometry.size.height, by: 2) {
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                                }
                            }
                            .stroke(.black.opacity(0.05))
                        }
                    )
            )
            .overlay(
                GeometryReader { geometry in
                    Path { path in
                        let gridSize: CGFloat = 4
                        for x in stride(from: 0, to: geometry.size.width, by: gridSize) {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                        }
                        for y in stride(from: 0, to: geometry.size.height, by: gridSize) {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                    }
                    .stroke(.black.opacity(0.05), lineWidth: 0.5)
                }
            )
    }
}
