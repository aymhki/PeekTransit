import SwiftUI
import WidgetKit


struct DynamicWidgetView: View {
    let widgetData: [String: Any]
    let scheduleData: [String]?
    let size: WidgetFamily
    let updatedAt: Date
    let fullyLoaded: Bool
    let forPreview: Bool
    let isLoading: Bool
    
    private var currentTheme: StopViewTheme {
        if let savedTheme = SharedDefaults.userDefaults?.string(forKey: settingsUserDefaultsKeys.sharedStopViewTheme),
           let theme = StopViewTheme(rawValue: savedTheme) {
            return theme
        }
        return .default
    }
    
    
    private func createStopURL(stopNumber: Int) -> URL? {
        var components = URLComponents()
        components.scheme = "peektransit"
        components.host = "stop"
        components.queryItems = [
            URLQueryItem(name: "number", value: String(stopNumber))
        ]
        return components.url
    }
    
    private var scheduleDataToUse: [String] {
        if let scheduleData = scheduleData, !scheduleData.isEmpty, fullyLoaded {
            return scheduleData
        } else {
            if let widgetId = widgetDataToUse["id"] as? String, let (_, cachedScheduleData, _) = WidgetHelper.getCachedEntry(forId: widgetId) {
                return cachedScheduleData ?? scheduleData ?? []
            } else {
                return scheduleData ?? []
            }
        }
    }
    
    private var mightUseCacheData: Bool {
        (!fullyLoaded || scheduleData == nil || scheduleData!.isEmpty || widgetData.isEmpty) && !forPreview
    }
    
    private var updatedAtToUse: Date {
        if mightUseCacheData {
            if let widgetId = widgetDataToUse["id"] as? String, let (_, _, lastUpdatedToUse) = WidgetHelper.getCachedEntry(forId: widgetId) {
                return lastUpdatedToUse ?? updatedAt
            } else {
                return updatedAt
            }
        } else {
            return updatedAt
        }
    }
    
    private var widgetDataToUse: [String: Any] {
        if !widgetData.isEmpty,  let scheduleData = scheduleData, !scheduleData.isEmpty, fullyLoaded {
            return widgetData
        } else {
            if let widgetId = widgetData["id"] as? String, let (cachedWidgetData, _, _) = WidgetHelper.getCachedEntry(forId: widgetId) {
                return cachedWidgetData ?? widgetData
            } else {
                return widgetData
            }
        }
    }
    
    var body: some View {
        if ( (widgetData["size"] as? String == "medium" && size == .systemMedium) || (widgetData["size"] as? String == "large" && size == .systemLarge) || (widgetData["size"] as? String == "small" && size == .systemSmall) || (widgetData["size"] as? String == "lockscreen" && size == .accessoryRectangular) ) {
            
            Group {
                
                
                GeometryReader { geometry in
                    ZStack {
                        if (size != .accessoryRectangular) {
                            switch currentTheme {
                            case .classic:
                                Color.black
                                    .edgesIgnoringSafeArea(.all)
                            case .modern:
                                Color(.secondarySystemGroupedBackground)
                                    .edgesIgnoringSafeArea(.all)
                            }
                        }
                        
                        
                        
                        VStack(alignment: .leading, spacing: 4) {
                            
                            content
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            
                            if ((!fullyLoaded || scheduleDataToUse == nil || widgetDataToUse.isEmpty || scheduleDataToUse.isEmpty) && !forPreview) {
                                Text("Open app")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.horizontal)
                                    .padding(.vertical)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.caption)
                            }
                            
                            if (widgetDataToUse["showLastUpdatedStatus"] as? Bool ?? true) {
                                if (size != .accessoryRectangular) {
                                    if (size != .systemMedium || scheduleDataToUse.count <= 3) {
                                        Spacer(minLength: 2)
                                    }
                                }
                                
                                if (size != .accessoryRectangular) {
                                    LastUpdatedView(updatedAt: updatedAtToUse, size: size == .systemSmall ? "small" : size == .systemMedium ? "medium" : size == .systemLarge ? "large" : "lockscreen", isLoading: isLoading,  usingCached: mightUseCacheData)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    LastUpdatedView(updatedAt: updatedAtToUse, size: size == .systemSmall ? "small" : size == .systemMedium ? "medium" : size == .systemLarge ? "large" : "lockscreen", isLoading: isLoading, usingCached: mightUseCacheData)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea(.all)
                        
                    }
                }
                
                
            }
            .widgetBackground(backgroundView: Group {
                if (size != .accessoryRectangular) {
                    switch currentTheme {
                    case .classic:
                        Color.black
                    case .modern:
                        Color(.secondarySystemGroupedBackground)
                    }
                }
            })
        } else {
            
            if (size != .accessoryRectangular) {
                if(size != .systemSmall) {
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
            
        
        
            Text("P. T.: Hold on the wallpaper to customize your lockscreen then tap here twice to edit")
                .foregroundColor(.blue)
                .font(.system(size: 10) )
            
            
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

    
    @ViewBuilder
    private var content: some View {
        selectedStopsView
    }
    
    
    @ViewBuilder
    private var selectedStopsView: some View {
        
        if let stops = widgetDataToUse["stops"] as? [[String: Any]] {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(stops.prefix(maxStops)).indices, id: \.self) { stopIndex in
                    let stop = stops[stopIndex]
                    let stopNumber = stop["number"] as? Int ?? 0
                    let multipleEntriesPerVariant = widgetDataToUse["multipleEntriesPerVariant"] as? Bool ?? true
                    let destinationUrl = createStopURL(stopNumber: stopNumber) ?? URL(string: "peektransit://")!
                    Link(destination: destinationUrl ) {
                        if (size == .accessoryRectangular || size == .systemSmall) {
                            WidgetStopView(stop: stop, scheduleData: scheduleDataToUse, size: size, fullyLoaded: fullyLoaded, forPreview: forPreview, multipleEntriesPerVariant: multipleEntriesPerVariant, showLastUpdatedStatus: widgetDataToUse["showLastUpdatedStatus"] as? Bool ?? true)
                                .widgetURL(destinationUrl)
                        } else {
                            WidgetStopView(stop: stop, scheduleData: scheduleDataToUse, size: size, fullyLoaded: fullyLoaded, forPreview: forPreview, multipleEntriesPerVariant: multipleEntriesPerVariant, showLastUpdatedStatus: widgetDataToUse["showLastUpdatedStatus"] as? Bool ?? true)
                        }
                    }
                    
                    
                    if ( stopIndex < stops.prefix(maxStops).count - 1 && size != .accessoryRectangular && size != .systemSmall && fullyLoaded )
                    {
                        Divider()
                    }
                }
            }
        }
    }
    
    private var maxStops: Int {
        return getMaxSopsAllowed(widgetSizeSystemFormat: size, widgetSizeStringFormat: nil)
    }
    
    private var maxSchedules: Int {
        return getMaxVariantsAllowed(widgetSizeSystemFormat: size, widgetSizeStringFormat: nil)
    }
}


