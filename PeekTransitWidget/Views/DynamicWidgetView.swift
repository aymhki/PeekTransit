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
    
    private var cachedData: ([String: Any]?, [String]?, Date?)? {
        if let widgetId = widgetData["id"] as? String {
            return WidgetHelper.getCachedEntry(forId: widgetId)
        }
        return nil
    }

    private var widgetDataToUse: [String: Any] {
        if !widgetData.isEmpty && scheduleData != nil && !scheduleData!.isEmpty && fullyLoaded {
            return widgetData
        }
        
        if let (cachedWidgetData, _, _) = cachedData, (cachedWidgetData != nil ), !cachedWidgetData!.isEmpty {
            return cachedWidgetData ?? widgetData
        }
        
        return widgetData
    }

    private var scheduleDataToUse: [String] {
        if let currentData = scheduleData, !currentData.isEmpty, fullyLoaded {
            return currentData
        }
        
        if let (_, cachedScheduleData, _) = cachedData, let data = cachedScheduleData, !data.isEmpty {
            return data
        }
        
        return scheduleData ?? []
    }

    private var updatedAtToUse: Date {
        if !mightUseCacheData {
            if let dataTimestamp = widgetData["refreshDataDate"] as? Double {
                return Date(timeIntervalSince1970: dataTimestamp)
            }
            
            return updatedAt
        }
        
        if let (_, _, lastUpdated) = cachedData, let date = lastUpdated {
            return date
        }
        
        return updatedAt
    }

    private var showRefreshButton: Bool {
        guard size == .systemSmall || size == .systemMedium || size == .systemLarge else {
            return false
        }
        
        return (widgetData["showRefreshButton"] as? Bool) ?? (widgetDataToUse["showRefreshButton"] as? Bool) ?? false
    }
    
    private var widgetIdForRefresh: String? {
        return widgetData["id"] as? String
    }
    
    private var refreshButtonIsInteractive: Bool {
        guard showRefreshButton, !forPreview, let widgetId = widgetIdForRefresh, !widgetId.isEmpty else {
            return false
        }
        
        if #available(iOS 17.0, *) {
            return true
        }
        
        return false
    }
    
    private var refreshOwnsLastUpdatedText: Bool {
        return refreshButtonIsInteractive && (widgetDataToUse["showLastUpdatedStatus"] as? Bool ?? true)
    }
    
    private var isRefreshCoolingDown: Bool {
        guard refreshButtonIsInteractive, let widgetId = widgetIdForRefresh else {
            return false
        }
        
        return WidgetRefreshState.isCoolingDown(widgetId, now: updatedAt)
    }
    
    private var lastUpdatedReservedSpace: CGFloat {
        if showRefreshButton && (size == .systemSmall || size == .systemMedium) {
            return getRefreshButtonReservedSpace(for: size)
        }
        
        return 0
    }
    
    private var bottomContentPadding: CGFloat {
        return (showRefreshButton && size == .systemLarge) ? 28 : 8
    }
    
    private var refreshLastUpdatedContent: ((Bool) -> AnyView)? {
        guard refreshOwnsLastUpdatedText else {
            return nil
        }
        
        return { loading in
            self.refreshLastUpdatedView(isLoading: loading)
        }
    }
    
    private func refreshLastUpdatedView(isLoading: Bool) -> AnyView {
        return AnyView(
            LastUpdatedView(
                updatedAt: updatedAtToUse,
                size: size == .systemSmall ? "small" : size == .systemMedium ? "medium" : "large",
                isLoading: isLoading,
                usingCached: mightUseCacheData,
                forPreview: false,
                reservedTrailingSpace: lastUpdatedReservedSpace
            )
        )
    }
    
    private var mightUseCacheData: Bool {
        return (scheduleData == nil || scheduleData!.isEmpty || widgetData.isEmpty) && !forPreview
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
                        } else {
                            Color.clear.edgesIgnoringSafeArea(.all)
                            OptionalBlurView(showBlur: true)
                        }
                        
                        
                        VStack(alignment: .leading, spacing: 4) {
                            
                            if (size == .accessoryRectangular) {
                                content
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 8)
                            } else {
                                content
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .refreshInvalidatable(refreshButtonIsInteractive)
                            }
                            
                            if (widgetDataToUse.isEmpty || scheduleDataToUse.isEmpty) && (cachedData == nil || (cachedData!.0?.isEmpty ?? true) || (cachedData!.1?.isEmpty ?? true)) && !forPreview {
                                Text("Open app")
                                    .foregroundStyle(.primary)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.horizontal)
                                    .padding(.vertical)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            
                            if (widgetDataToUse["showLastUpdatedStatus"] as? Bool ?? true) {
                                if (size != .accessoryRectangular) {
                                    if (size != .systemMedium || scheduleDataToUse.count <= 3) {
                                        Spacer(minLength: 2)
                                    }
                                }
                                
                                if (size != .accessoryRectangular) {
                                    LastUpdatedView(updatedAt: updatedAtToUse, size: size == .systemSmall ? "small" : size == .systemMedium ? "medium" : size == .systemLarge ? "large" : "lockscreen", isLoading: isLoading,  usingCached: mightUseCacheData, forPreview: forPreview, reservedTrailingSpace: lastUpdatedReservedSpace)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .opacity(refreshOwnsLastUpdatedText ? 0 : 1)
                                } else {
                                    LastUpdatedView(updatedAt: updatedAtToUse, size: size == .systemSmall ? "small" : size == .systemMedium ? "medium" : size == .systemLarge ? "large" : "lockscreen", isLoading: isLoading, usingCached: mightUseCacheData, forPreview: forPreview, reservedTrailingSpace: lastUpdatedReservedSpace)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .opacity(refreshOwnsLastUpdatedText ? 0 : 1)
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 8, leading: 8, bottom: bottomContentPadding, trailing: 8))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea(.all)
                        
                        if showRefreshButton {
                            RefreshButtonOverlay(
                                widgetId: widgetIdForRefresh,
                                family: size,
                                isLoading: isLoading,
                                isCoolingDown: isRefreshCoolingDown,
                                forPreview: forPreview,
                                borderColor: currentTheme == .classic ? Color(hex: "#EB8634", brightness: 300, saturation: 50) : Color.primary,
                                containerSize: geometry.size,
                                lastUpdatedContent: refreshLastUpdatedContent
                            )
                        }
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
                } else {
                    Color.clear.edgesIgnoringSafeArea(.all)
                    OptionalBlurView(showBlur: true)
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
                .bold()
        
        
            Text("P. T.: Hold on the wallpaper to customize your lockscreen then tap here twice to edit")
                .foregroundColor(.blue)
                .font(.system(size: 10))
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

    
    @ViewBuilder
    private var content: some View {
        selectedStopsView
    }
    
    
    @ViewBuilder
    private var selectedStopsView: some View {
        
        if let stops = widgetDataToUse["stops"] as? [Stop] {
            let stopsToShow: [Stop] = Array(stops.prefix(maxStops))
            let allowedVariantCounts = getAllowedVariantCountsPerStop(
                selectedCounts: stopsToShow.map { $0.selectedVariants.count },
                totalAllowed: getTotalVariantsAllowedInWidget(
                    multipleEntriesPerVariant: widgetDataToUse["multipleEntriesPerVariant"] as? Bool ?? true,
                    widgetSizeSystemFormat: size,
                    widgetSizeStringFormat: nil
                )
            )
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(stopsToShow.enumerated()), id: \.offset) { stopIndex, stop in
                    //let stop = stops[stopIndex]
                    let stopNumber = stop.number
                    let multipleEntriesPerVariant = widgetDataToUse["multipleEntriesPerVariant"] as? Bool ?? true
                    let maxVariantsToShow = stopIndex < allowedVariantCounts.count ? allowedVariantCounts[stopIndex] : 0
                    let destinationUrl = createStopURL(stopNumber: stopNumber) ?? URL(string: "peektransit://")!
                    
                    if (size == .accessoryRectangular || size == .systemSmall) {
                        WidgetStopView(stop: stop, scheduleData: scheduleDataToUse, size: size, fullyLoaded: fullyLoaded, forPreview: forPreview, multipleEntriesPerVariant: multipleEntriesPerVariant, showLastUpdatedStatus: widgetDataToUse["showLastUpdatedStatus"] as? Bool ?? true, maxVariantsToShow: maxVariantsToShow)
                            .widgetURL(destinationUrl)
                    } else {
                        Link(destination: destinationUrl ) {
                            WidgetStopView(stop: stop, scheduleData: scheduleDataToUse, size: size, fullyLoaded: fullyLoaded, forPreview: forPreview, multipleEntriesPerVariant: multipleEntriesPerVariant, showLastUpdatedStatus: widgetDataToUse["showLastUpdatedStatus"] as? Bool ?? true, maxVariantsToShow: maxVariantsToShow)
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


@available(iOSApplicationExtension 16.0, *)
struct OptionalBlurView: View {
    @Environment(\.widgetFamily) var family

    var showBlur: Bool

        
    
    var body: some View {
        if showBlur {
            blurView
        } else {
            EmptyView()
        }
    }
    
    var blurView: some View {
        AccessoryWidgetBackground()
            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10), style: .continuous))
            .edgesIgnoringSafeArea(.all)
    }
    
}
