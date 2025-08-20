import SwiftUI

struct BusStopPreviewProvider: UIViewControllerRepresentable {
    let stop: Stop

    
    func makeUIViewController(context: Context) -> UIViewController {
        let themeManager = ThemeManager.shared
        
        let hostingController = UIHostingController(
            rootView: BusStopView(stop: stop, isDeepLink: false)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
        )
        
        hostingController.view.backgroundColor = UIColor.systemBackground
        
        return hostingController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
