import SwiftUI
import AppIntents

@available(iOS 17.0, *)
struct RefreshButton: View {
    var body: some View {
        Button(intent: RefreshTimelineIntent()) {
            Image(systemName: "arrow.clockwise")
        }
        .tint(.accentColor)
        .buttonStyle(.borderedProminent)
        .clipShape(Circle())
        .controlSize(.small)
        .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
    }
}
