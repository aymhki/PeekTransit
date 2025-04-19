import SwiftUI
import WidgetKit

struct WidgetStopView: View {
    let stop: [String: Any]
    let scheduleData: [String]?
    let size: WidgetFamily
    let stopNamePrefixSize = getStopNameMaxPrefixLengthForWidget()
    let fullyLoaded: Bool
    let forPreview: Bool
    let multipleEntriesPerVariant: Bool
    let showLastUpdatedStatus: Bool

    private var currentTheme: StopViewTheme {
        if let savedTheme = SharedDefaults.userDefaults?.string(forKey: settingsUserDefaultsKeys.sharedStopViewTheme),
           let theme = StopViewTheme(rawValue: savedTheme) {
            return theme
        }
        return .default
    }
    
    private var maxSchedules: Int {
        if (multipleEntriesPerVariant) {
            return getMaxVariantsAllowedForMultipleEntries(widgetSizeSystemFormat: size, widgetSizeStringFormat: nil)
        } else {
            return  getMaxVariantsAllowed(widgetSizeSystemFormat: size, widgetSizeStringFormat: nil)
        }
    }

    
    
    var body: some View {
        

        
        VStack(alignment: .leading, spacing: 4) {
            let stopName = stop["name"] as? String ?? "Unknown"
            let stopNumber = stop["number"] as? Int ?? 0
            let stopNamePrefix = "\(stopName.prefix(stopNamePrefixSize))..."
            

            if ( size != .accessoryRectangular && ( !(size == .systemSmall && !multipleEntriesPerVariant) || size == .systemSmall && (scheduleData)?.count ?? 0 <= 1)  && fullyLoaded) {
                if (size == .systemSmall) {
                    Text("• \(stopName.count > stopNamePrefixSize ? stopNamePrefix : stopName) - \(stopNumber == 0 ? getWidgetTextPlaceholder() : String(stopNumber) )")
                        .widgetTheme(currentTheme, text: "stop", size: size, inPreview: forPreview)
                        .padding(.top, 2)
                } else if (size == .systemLarge) {
                    Text("• \(stopName.count > stopNamePrefixSize ? stopNamePrefix : stopName) - \(stopNumber == 0 ? getWidgetTextPlaceholder() : String(stopNumber) )")
                        .widgetTheme(currentTheme, text: "stop", size: size, inPreview: forPreview)
                        .padding(.top, 2)
                } else {
                    Text("• \(stopName.count > stopNamePrefixSize ? stopNamePrefix : stopName) - \(stopNumber == 0 ? getWidgetTextPlaceholder() : String(stopNumber) )")
                        .widgetTheme(currentTheme, text: "stop", size: size, inPreview: forPreview)
                        .padding(.bottom, 1)
                        .padding(.top, 8)
                }
                

            }
            
            if ((size == .systemLarge || size == .systemSmall || (scheduleData)?.count ?? 0 < 3 ) && fullyLoaded && size != .accessoryRectangular) {
                Spacer()
            }
            
            
            
            if let variants = stop["selectedVariants"] as? [[String: Any]] {
                

                
                ForEach(variants.prefix(maxSchedules).indices, id: \.self) { variantIndex in
                    if let key = variants[variantIndex]["key"] as? String,
                       let schedules = scheduleData,
                       let variantName = variants[variantIndex]["name"] as? String {
                        
                        let matchingSchedules = schedules.filter { scheduleString in
                            let components = scheduleString.components(separatedBy: getScheduleStringSeparator())
                            return components.count >= 2 &&
                                   components[0] == key &&
                                   components[1] == variantName
                        }
                        
                        let schedulesToShow = multipleEntriesPerVariant ? matchingSchedules.prefix(2) : matchingSchedules.prefix(1)
                        
                        ForEach(Array(schedulesToShow.enumerated()), id: \.element) { (scheduleIndex, schedule) in
                            if (size == .systemSmall || size == .accessoryRectangular) {
                                BusScheduleRow(schedule: schedule, size: size, fullyLoaded: fullyLoaded, forPreview: forPreview)
                                    .padding(.bottom, showLastUpdatedStatus ? 4 : 6)
                            } else if (size == .systemLarge) {
                                BusScheduleRow(schedule: schedule, size: size, fullyLoaded: fullyLoaded, forPreview: forPreview)
                                    .padding(.horizontal, 2)
                            } else if (size == .systemMedium) {
                                BusScheduleRow(schedule: schedule, size: size, fullyLoaded: fullyLoaded, forPreview: forPreview)
                                    .padding(.horizontal, 2)
                                    .padding(.bottom, (variantIndex < variants.prefix(maxSchedules).count - 1 || scheduleIndex < schedulesToShow.count - 1) ? 3 : 0)
                            } else if (size == .accessoryRectangular) {
                                BusScheduleRow(schedule: schedule, size: size, fullyLoaded: fullyLoaded, forPreview: forPreview)
                            } else if (size == .systemSmall) {
                                BusScheduleRow(schedule: schedule, size: size, fullyLoaded: fullyLoaded, forPreview: forPreview)
                            }
                            
                            if (((size == .systemLarge || size == .systemSmall || ((scheduleData)?.count ?? 0 < 3)) && size != .accessoryRectangular) && fullyLoaded) {
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .if(currentTheme == .classic && size != .accessoryRectangular) { view in
            view.background(.black)
        }
    }

}




