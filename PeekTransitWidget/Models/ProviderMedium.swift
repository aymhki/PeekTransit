import WidgetKit
import SwiftUI
import Intents
import Combine
import Foundation


struct ProviderMedium: IntentTimelineProvider {
    typealias Entry = SimpleEntryMedium
    
    func placeholder(in context: Context) -> SimpleEntryMedium {
        SimpleEntryMedium(date: Date(), configuration: ConfigurationMediumIntent())
    }
    
    
    func getSnapshot(for configuration: ConfigurationMediumIntent, in context: Context, completion: @escaping (SimpleEntryMedium) -> Void) {
        Task {
            if let widgetId = configuration.widgetConfig?.identifier,
               let widget = WidgetHelper.getWidgetFromDefaults(withId: widgetId) {
                
                var finalWidgetData = widget.widgetData
                
                if widget.widgetData["isClosestStop"] as? Bool == true {
                    if let location = await LocationManager.shared.getCurrentLocation() {
                        let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: true)
                        if let stops = nearbyStops, !stops.isEmpty {
                            let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                                widgetSizeSystemFormat: .systemMedium,
                                widgetSizeStringFormat: nil
                            )
                            finalWidgetData["stops"] = Array(stops.prefix(maxStops))
                            let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData, isClosestStop: true)
                            finalWidgetData = updatedWidgetData
                            
                            completion(SimpleEntryMedium(
                                date: Date(),
                                configuration: configuration,
                                widgetData: finalWidgetData,
                                scheduleData: schedule
                            ))
                        } else {
                            finalWidgetData["noStopsFound"] = true
                            completion(SimpleEntryMedium(
                                date: Date(),
                                configuration: configuration,
                                widgetData: finalWidgetData,
                                scheduleData: nil
                            ))
                        }
                    }
                } else {
                    let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData)
                    completion(SimpleEntryMedium(
                        date: Date(),
                        configuration: configuration,
                        widgetData: updatedWidgetData,
                        scheduleData: schedule
                    ))
                }
            } else {
                completion(SimpleEntryMedium(date: Date(), configuration: configuration))
            }
        }
    }
    
    func getTimeline(for configuration: ConfigurationMediumIntent, in context: Context, completion: @escaping (Timeline<SimpleEntryMedium>) -> Void) {
        Task {
            let widgetId = configuration.widgetConfig?.identifier
            let widget = widgetId.flatMap { WidgetHelper.getWidgetFromDefaults(withId: $0) }
            var widgetData = widget?.widgetData
            
            if widget?.widgetData["isClosestStop"] as? Bool == true {
                if let location = await LocationManager.shared.getCurrentLocation() {
                    let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: true)
                    if let stops = nearbyStops, !stops.isEmpty {
                        let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                            widgetSizeSystemFormat: .systemMedium,
                            widgetSizeStringFormat: nil
                        )
                        widgetData?["stops"] = Array(stops.prefix(maxStops))
                        let (_, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(widgetData ?? [:], isClosestStop: true)
                        widgetData = updatedWidgetData
                    } else {
                        widgetData?["noStopsFound"] = true
                    }
                }
            }
            
            let timeline = await WidgetHelper.createTimeline(
                currentDate: Date(),
                configuration: configuration,
                widgetData: widgetData
            ) { date, config, data, schedule in
                SimpleEntryMedium(
                    date: date,
                    configuration: config as! ConfigurationMediumIntent,
                    widgetData: data,
                    scheduleData: schedule
                )
            }
            
            completion(timeline)
        }
    }
}
