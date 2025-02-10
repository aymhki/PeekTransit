import SwiftUI

@main
struct PeekTransitWidgetBundle: WidgetBundle {

    var body: some Widget {
        PeekTransitSmallWidget()
        PeekTransitMediumWidget()
        PeekTransitLargeWidget()
        PeekTransitLockscreenWidget()
    }
}

