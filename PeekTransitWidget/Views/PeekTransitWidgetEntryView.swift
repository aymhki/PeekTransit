import WidgetKit
import SwiftUI
import Intents
import Combine
import Foundation

struct PeekTransitWidgetEntryView<T: BaseEntry>: View {
    var entry: T
    @Environment(\.widgetFamily) var family
    
    private var currentTheme: StopViewTheme {
        if let savedTheme = SharedDefaults.userDefaults?.string(forKey: settingsUserDefaultsKeys.sharedStopViewTheme),
           let theme = StopViewTheme(rawValue: savedTheme) {
            return theme
        }
        return .default
    }
    
    private func isWidgetFullyLoaded(widgetData: [String: Any], scheduleData: [String]?) -> Bool {
        let scheduleDataSize = scheduleData?.count ?? 0
        var totalNumberOfVariantsInStops = 0
        let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(widgetSizeSystemFormat: family, widgetSizeStringFormat: nil)
        
        if scheduleDataSize > 0 {
            if let widgetStops = widgetData["stops"] as? [[String: Any]] {
                for stopIndex in widgetStops.prefix(maxStops).indices {
                    let stop = widgetStops[stopIndex]
                    
                    let variants = stop["selectedVariants"]
                    
                    totalNumberOfVariantsInStops += (variants as? [[String: Any]])?.count ?? 0
                }
            }
        }
        
        let noVariantsSelected = widgetData["noSelectedVariants"] as? Bool ?? false
        
        return (scheduleDataSize >= totalNumberOfVariantsInStops || noVariantsSelected)
    }
    
    private func AreAllSelectedVariantsInScheduleData(widgetData: [String: Any], scheduleData: [String]?) -> Bool {
        let scheduleDataSize = scheduleData?.count ?? 0
        var selectedVariantsSimplified: Set<String> = []
        var availableScheduleVariantsSimplified: Set<String> = []
        
        if scheduleDataSize > 0 {
            if let widgetStops = widgetData["stops"] as? [[String: Any]] {
                for stopIndex in widgetStops.indices {
                    let stop = widgetStops[stopIndex]
                    
                    let variants = stop["selectedVariants"]
                    
                    for variant in variants as? [[String: Any]] ?? [] {
                        guard let variantKey = variant["key"] as? String,
                              let variantName = variant["name"] as? String else {
                            continue
                        }
                        
                        selectedVariantsSimplified.insert("\(variantKey)\(getCompositKeyLinkerForDictionaries())\(variantName)")
                    }
                }
            }
            
            for scheduleString in scheduleData ?? [] {
                let components = scheduleString.components(separatedBy: getScheduleStringSeparator())
                if components.count >= 2 {
                    let variantKey = components[0]
                    let variantName = components[1]
                    availableScheduleVariantsSimplified.insert("\(variantKey)\(getCompositKeyLinkerForDictionaries())\(variantName)")
                }
            }
            
            return selectedVariantsSimplified.isSubset(of: availableScheduleVariantsSimplified)
        }
        
        

        return false
    }
    
    private func getFilledScheduleData(widgetData: [String: Any], scheduleData: [String]?) -> [String]? {
                
        if AreAllSelectedVariantsInScheduleData(widgetData: widgetData, scheduleData: scheduleData) {
            return scheduleData
        }
        
        var filledScheduleData: [String] = scheduleData ?? []
        var selectedVariantsSimplified: Set<String> = []
        var availableScheduleVariantsSimplified: Set<String> = []

        if let widgetStops = widgetData["stops"] as? [[String: Any]] {
            for stopIndex in widgetStops.indices {
                let stop = widgetStops[stopIndex]
                
                let variants = stop["selectedVariants"]
                
                for variant in variants as? [[String: Any]] ?? [] {
                    guard let variantKey = variant["key"] as? String,
                          let variantName = variant["name"] as? String else {
                        continue
                    }
                    
                    selectedVariantsSimplified.insert("\(variantKey)\(getCompositKeyLinkerForDictionaries())\(variantName)")
                }
            }
        }

        for scheduleString in scheduleData ?? [] {
            let components = scheduleString.components(separatedBy: getScheduleStringSeparator())
            if components.count >= 2 {
                let variantKey = components[0]
                let variantName = components[1]
                availableScheduleVariantsSimplified.insert("\(variantKey)\(getCompositKeyLinkerForDictionaries())\(variantName)")
            }
        }

        for selectedVariant in selectedVariantsSimplified {
            if !availableScheduleVariantsSimplified.contains(selectedVariant) {
                let components = selectedVariant.components(separatedBy: "-")
                if components.count >= 2 {
                    filledScheduleData.append("\(components[0])\(getScheduleStringSeparator())\(components[1])\(getScheduleStringSeparator())\(getOKStatusTextString())\(getScheduleStringSeparator())\(getTimePeriodAllowedForNextBusRoutes())hrs+")
                }
            }
        }
        
        return filledScheduleData
        
    }
    
    var body: some View {

        if let widgetData = entry.widgetData {
           let filledScheduleData = getFilledScheduleData(widgetData: widgetData, scheduleData: entry.scheduleData)
                
            
            
            if widgetData["noStopsFound"] as? Bool == true {
                
                if (family != .accessoryRectangular) {
                    Text("Could not fetch nearby bus stops \(String(format: "(within %.0fm)", getStopsDistanceRadius())), please wait a few minutes or move closer to a bus stop.")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                } else {
                    Text("Could not nearby fetch stops \(String(format: "(%.0fm)", getStopsDistanceRadius())), please wait...")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                    
                    
            } else if (isWidgetFullyLoaded(widgetData: widgetData, scheduleData: filledScheduleData))  {
                DynamicWidgetView(
                    widgetData: widgetData,
                    scheduleData: filledScheduleData,
                    size: family,
                    updatedAt: entry.date,
                    fullyLoaded: true,
                    forPreview: false
                )


            } else {
                DynamicWidgetView(
                    widgetData: widgetData,
                    scheduleData: filledScheduleData,
                    size: family,
                    updatedAt: entry.date,
                    fullyLoaded: false,
                    forPreview: false
                )

            }
        } else {
            if (family != .accessoryRectangular) {
                if(family != .systemSmall) {
                    VStack (alignment: .center) {
                        Spacer()
                        
                        Text("Peek Transit")
                            .padding(.horizontal)
                            .bold()
                        
                        Spacer()
                        
                        Text("Hold to edit and tap to select a widget configuration to start")
                            .foregroundColor(.blue)
                            .padding(.horizontal)
                            .font(.system(size: 12 ) )
                        
                        Spacer()
                    }
                } else {
                    VStack {
                        Spacer(minLength: 4)
                        
                        Text("Peek Transit")
                            .padding(.horizontal)
                            .font(.system(size: 12 ) )
                            .bold()
                        
                        
                        Spacer(minLength: 4)
                        
                        
                        Text("Hold to edit and tap select a widget configuration to start")
                            .foregroundColor(.blue)
                            .padding(.horizontal)
                            .font(.system(size: 10 ) )
                        
                        Spacer(minLength: 4)
                    }
                }
            } else {
                Text("Peek Transit: Tap in edit to select a config to start")
                    .foregroundColor(.blue)
                    .padding(.horizontal)
                    .font(.system(size: 10, design: .monospaced ) )
            }
        }
    }
    
}



//#if DEBUG
//struct PreviewEntry: BaseEntry {
//    let date: Date
//    let scheduleData: [String]?
//    let widgetData: [String: Any]?
//    
//    init(date: Date, scheduleData: [String]?, widgetData: [String: Any]?) {
//        self.date = date
//        self.scheduleData = scheduleData
//        self.widgetData = widgetData
//    }
//}
//
//struct PeekTransitWidgetEntryView_Previews: PreviewProvider {
//    static let mockScheduleData = [
//        "671_Downtown_LATE_10 min.",
//        "671_Downtown_LATE_12 59 PM",
//        "751_University_LATE_2:03 AM",
//        "161_Osborne_EARLY_12:59 PM",
//        "47_Downtown_EARLY_5 min."
//    ].map { $0.replacingOccurrences(of: "_", with: getScheduleStringSeparator()) }
//    
//    static let mockStops: [[String: Any]] = [
//        [
//            "number": 10234,
//            "name": "Westbound Graham at Donald",
//            "selectedVariants": [
//                ["key": "671", "name": "Downtown"],
//                ["key": "751", "name": "University"]
//            ]
//        ],
//        [
//            "number": 10456,
//            "name": "Northbound Osborne at River",
//            "selectedVariants": [
//                ["key": "161", "name": "Osborne"],
//                ["key": "47", "name": "Downtown"]
//            ]
//        ]
//    ]
//    
//    static let mockWidgetData: [String: Any] = [
//        "size": "medium",
//        "id": "preview-id",
//        "createdAt": ISO8601DateFormatter().string(from: Date()),
//        "isClosestStop": false,
//        "name": "Preview Widget",
//        "timeFormat": "12h",
//        "showLastUpdatedStatus": true,
//        "noSelectedVariants": false,
//        "multipleEntriesPerVariant": true,
//        "stops": mockStops,
//        "type": "multi_stop"
//    ]
//    
//    static var previews: some View {
//        Group {
//            PeekTransitWidgetEntryView(entry: PreviewEntry(
//                date: Date(),
//                scheduleData: mockScheduleData,
//                widgetData: mockWidgetData
//            ))
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//            .previewDisplayName("Small Widget")
//            
//            PeekTransitWidgetEntryView(entry: PreviewEntry(
//                date: Date(),
//                scheduleData: mockScheduleData,
//                widgetData: mockWidgetData
//            ))
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
//            .previewDisplayName("Medium Widget")
//            
//            PeekTransitWidgetEntryView(entry: PreviewEntry(
//                date: Date(),
//                scheduleData: mockScheduleData,
//                widgetData: mockWidgetData
//            ))
//            .previewContext(WidgetPreviewContext(family: .systemLarge))
//            .previewDisplayName("Large Widget")
//            
//            PeekTransitWidgetEntryView(entry: PreviewEntry(
//                date: Date(),
//                scheduleData: mockScheduleData,
//                widgetData: mockWidgetData
//            ))
//            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
//            .previewDisplayName("Lock Screen Widget")
//        }
//    }
//}
//#endif
