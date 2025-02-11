import SwiftUI

@main
struct PeekTransitWidgetBundle: WidgetBundle {
    
    init() {
        _ = WidgetUpdateManager.shared
    }

    var body: some Widget {
        PeekTransitSmallWidget()
        PeekTransitMediumWidget()
        PeekTransitLargeWidget()
        PeekTransitLockscreenWidget()
    }
}

