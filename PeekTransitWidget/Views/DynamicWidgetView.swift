import SwiftUI
import WidgetKit


struct DynamicWidgetView: View {
    let widgetData: [String: Any]
    let scheduleData: [String]?
    let size: WidgetFamily
    let updatedAt: Date
    let fullyLoaded: Bool
    let forPreview: Bool
    
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
    
    var body: some View {
        Group {
            if let widgetData = widgetData as? [String: Any] {
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
                                
                                    
                            if ((!fullyLoaded || scheduleData == nil || widgetData.isEmpty || scheduleData?.isEmpty ?? false) && !forPreview) {
                                Text("Please wait or opne the app to refresh")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.horizontal)
                                
                            } 
                            
                            if (widgetData["showLastUpdatedStatus"] as? Bool ?? true) {
                                if (size != .accessoryRectangular) {
                                    if (size != .systemMedium || (scheduleData)?.count ?? 0 <= 3) {
                                        Spacer(minLength: 2)
                                    }
                                }
                                
                                if (size != .accessoryRectangular) {
                                    LastUpdatedView(updatedAt: updatedAt, size: size == .systemSmall ? "small" : size == .systemMedium ? "medium" : size == .systemLarge ? "large" : "lockscreen")
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    LastUpdatedView(updatedAt: updatedAt, size: size == .systemSmall ? "small" : size == .systemMedium ? "medium" : size == .systemLarge ? "large" : "lockscreen")
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea(.all)
                }
            } else {
                Text("Select the widget configuration to start")
                    .foregroundColor(.blue)
                    .padding(.horizontal)
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
    }
    

    
    @ViewBuilder
    private var content: some View {
        selectedStopsView
    }
    
    
    @ViewBuilder
    private var selectedStopsView: some View {
        if let stops = widgetData["stops"] as? [[String: Any]] {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(stops.prefix(maxStops)).indices, id: \.self) { stopIndex in
                    let stop = stops[stopIndex]
                    let stopNumber = stop["number"] as? Int ?? 0
                    let multipleEntriesPerVariant = widgetData["multipleEntriesPerVariant"] as? Bool ?? true
                    let destinationUrl = createStopURL(stopNumber: stopNumber) ?? URL(string: "peektransit://")!
                    Link(destination: destinationUrl ) {
                        if (size == .accessoryRectangular || size == .systemSmall) {
                            WidgetStopView(stop: stop, scheduleData: scheduleData, size: size, fullyLoaded: fullyLoaded, forPreview: forPreview, multipleEntriesPerVariant: multipleEntriesPerVariant, showLastUpdatedStatus: widgetData["showLastUpdatedStatus"] as? Bool ?? true)
                                .widgetURL(destinationUrl)
                        } else {
                            WidgetStopView(stop: stop, scheduleData: scheduleData, size: size, fullyLoaded: fullyLoaded, forPreview: forPreview, multipleEntriesPerVariant: multipleEntriesPerVariant, showLastUpdatedStatus: widgetData["showLastUpdatedStatus"] as? Bool ?? true)
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


