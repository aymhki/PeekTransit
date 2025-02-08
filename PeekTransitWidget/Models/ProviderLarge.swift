import WidgetKit
import SwiftUI
import Intents
import Combine
import Foundation


struct ProviderLarge: IntentTimelineProvider {
    typealias Entry = SimpleEntryLarge
    
    func placeholder(in context: Context) -> SimpleEntryLarge {
        SimpleEntryLarge(date: Date(), configuration: ConfigurationLargeIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationLargeIntent, in context: Context, completion: @escaping (SimpleEntryLarge) -> Void) {
        Task {
            if let widgetId = configuration.widgetConfig?.identifier,
               let widget = WidgetHelper.getWidgetFromDefaults(withId: widgetId) {
                
                var finalWidgetData = widget.widgetData
                
                if widget.widgetData["isClosestStop"] as? Bool == true {
                    if let location = await LocationManager.shared.getCurrentLocation() {
                        let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: true)
                        
                        
                        if let stops = nearbyStops, !stops.isEmpty {
                            let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                                widgetSizeSystemFormat: .systemLarge,
                                widgetSizeStringFormat: nil
                            )
                            finalWidgetData["stops"] = await WidgetHelper.getFilteredStopsForWidget(stops, maxStops: maxStops)
                            let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData, isClosestStop: true)
                            finalWidgetData = updatedWidgetData
                            
                            completion(SimpleEntryLarge(
                                date: Date(),
                                configuration: configuration,
                                widgetData: finalWidgetData,
                                scheduleData: schedule
                            ))
                        } else {
                            finalWidgetData["noStopsFound"] = true
                            completion(SimpleEntryLarge(
                                date: Date(),
                                configuration: configuration,
                                widgetData: finalWidgetData,
                                scheduleData: nil
                            ))
                        }
                    }
                } else {
                    let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData)
                    completion(SimpleEntryLarge(
                        date: Date(),
                        configuration: configuration,
                        widgetData: updatedWidgetData,
                        scheduleData: schedule
                    ))
                }
            } else {
                completion(SimpleEntryLarge(date: Date(), configuration: configuration))
            }
        }
    }
    
    func getTimeline(for configuration: ConfigurationLargeIntent, in context: Context, completion: @escaping (Timeline<SimpleEntryLarge>) -> Void) {
        Task {
            let widgetId = configuration.widgetConfig?.identifier
            let widget = widgetId.flatMap { WidgetHelper.getWidgetFromDefaults(withId: $0) }
            var widgetData = widget?.widgetData
            
            if widget?.widgetData["isClosestStop"] as? Bool == true {
                if let location = await LocationManager.shared.getCurrentLocation() {
                    let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: true)
                    if let stops = nearbyStops, !stops.isEmpty {
                        let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                            widgetSizeSystemFormat: .systemLarge,
                            widgetSizeStringFormat: nil
                        )
                        widgetData?["stops"] = await WidgetHelper.getFilteredStopsForWidget(stops, maxStops: maxStops)
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
                SimpleEntryLarge(
                    date: date,
                    configuration: config as! ConfigurationLargeIntent,
                    widgetData: data,
                    scheduleData: schedule
                )
            }
            
            completion(timeline)
        }
    }
}
