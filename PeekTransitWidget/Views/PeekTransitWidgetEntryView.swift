import WidgetKit
import SwiftUI
import Intents
import Combine
import Foundation

struct PeekTransitWidgetEntryView<T: BaseEntry>: View {
    var entry: T
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var widgetRenderingMode

    
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
            if let widgetStops = widgetData["stops"] as? [Stop] {
                for stopIndex in widgetStops.prefix(maxStops).indices {
                    let stop = widgetStops[stopIndex]
                    
                    let variants = stop.selectedVariants
                    
                    totalNumberOfVariantsInStops += (variants as? [Variant])?.count ?? 0
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
            if let widgetStops = widgetData["stops"] as? [Stop] {
                for stopIndex in widgetStops.indices {
                    let stop = widgetStops[stopIndex]
                    
                    let variants = stop.selectedVariants
                    
                    for variant in variants as? [Variant] ?? [] {
                        guard let variantKey = variant.key as? String,
                              let variantName = variant.name as? String else {
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

        if let widgetStops = widgetData["stops"] as? [Stop] {
            for stopIndex in widgetStops.indices {
                let stop = widgetStops[stopIndex]
                
                let variants = stop.selectedVariants
                
                for variant in variants as? [Variant] ?? [] {
                    guard let variantKey = variant.key as? String,
                          let variantName = variant.name as? String else {
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
            
            
            if ( (widgetData["size"] as? String == "medium" && family == .systemMedium) || (widgetData["size"] as? String == "large" && family == .systemLarge) || (widgetData["size"] as? String == "small" && family == .systemSmall) || (widgetData["size"] as? String == "lockscreen" && family == .accessoryRectangular) ) {
                
                let filledScheduleData = getFilledScheduleData(widgetData: widgetData, scheduleData: entry.scheduleData)
                
                
                if (isWidgetFullyLoaded(widgetData: widgetData, scheduleData: filledScheduleData))  {
                    DynamicWidgetView(
                        widgetData: widgetData,
                        scheduleData: filledScheduleData,
                        size: family,
                        updatedAt: entry.date,
                        fullyLoaded: true,
                        forPreview: false,
                        isLoading: entry.isLoading
                    )
                    .accentedWidget()
                    .widgetAccentable()
                    
                    
                } else {
                    DynamicWidgetView(
                        widgetData: widgetData,
                        scheduleData: filledScheduleData,
                        size: family,
                        updatedAt: entry.date,
                        fullyLoaded: false,
                        forPreview: false,
                        isLoading: entry.isLoading
                    )
                    .accentedWidget()
                    .widgetAccentable()
                    
                    
                }
                
            } else {
                if (family != .accessoryRectangular) {
                    if(family != .systemSmall) {
                        defaultNoConfigSelectedView
                    } else {
                        smallNoConfigSelectedView
                    }
                } else {
                    lockscreenNoConfigSelectedView
                }
            }
            
            
            } else if let error = entry.errorMessage {
                WidgetErrorView(message: error)
                    .accentedWidget()
                    .widgetAccentable()
            } else {
                if (family != .accessoryRectangular) {
                    if(family != .systemSmall) {
                        defaultNoConfigSelectedView
                    } else {
                        smallNoConfigSelectedView
                    }
                } else {
                    lockscreenNoConfigSelectedView
                }
            
        }
    }
    
    

    var lockscreenNoConfigSelectedView: some View {
        HStack {
            
            
        Image(systemName: getGlobalBusIconSystemImageName())
            .foregroundColor(.blue)
            .font(.system(size: 10))
            .bold()
        
    
    
        Text("P. T.: Hold on the wallpaper to customize your lockscreen then tap here twice to edit")
            .foregroundColor(.blue)
            .font(.system(size: 10) )
            .bold()
        
            
            
        }
        .padding(.horizontal, 1)
        .accentedWidget()
        .widgetAccentable()
    }
    
    
    var smallNoConfigSelectedView: some View {
        VStack {
            Spacer(minLength: 4)
            
            HStack {
                
                Image(systemName: getGlobalBusIconSystemImageName())
                    .font(.system(size: 12 ) )
                    .bold()
                
                Text("Peek Transit")
                    .font(.system(size: 12 ) )
                    .bold()
                
            }
            .padding(.horizontal)
            
            
            Spacer(minLength: 4)
            
            
            Text("Hold to edit and tap to select a widget configuration to start")
                .foregroundColor(.blue)
                .padding(.horizontal)
                .font(.system(size: 12 ) )
                .bold()
            
            Spacer(minLength: 4)
        }
        .accentedWidget()
        .widgetAccentable()
    }
    
    
    var defaultNoConfigSelectedView: some View {
        VStack (alignment: .center) {
            Spacer()
            
            HStack {
                Image(systemName: getGlobalBusIconSystemImageName())
                    .bold()
                
                
                Text("Peek Transit")
                    .bold()
            }
            .padding(.horizontal)
            
            Spacer()
            
            Text("Hold to edit and tap to select a widget configuration to start")
                .foregroundColor(.blue)
                .padding(.horizontal)
                .font(.subheadline )
                .bold()
            
            Spacer()
        }
        .accentedWidget()
        .widgetAccentable()
    }
    
}

