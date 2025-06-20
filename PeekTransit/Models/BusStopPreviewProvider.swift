import SwiftUI

struct BusStopPreviewProvider: UIViewControllerRepresentable {
    let stop: Stop
    
    func makeUIViewController(context: Context) -> UIViewController {
        let hostingController = UIHostingController(
            rootView: BusStopView(stop: stop, isDeepLink: false)
                .environmentObject(ThemeManager.shared)
        )
        hostingController.view.backgroundColor = .clear
        return hostingController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
