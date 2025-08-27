import Intents
import WidgetKit
import SwiftUI

struct TimelineRelevance {
    static func createRelevance() -> TimelineEntryRelevance {
        return TimelineEntryRelevance(
            score: 100,
            duration: 60
        )
    }
}
