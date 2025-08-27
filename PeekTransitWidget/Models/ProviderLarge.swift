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
            let widgetId = configuration.widgetConfig?.identifier
            
            if let widgetId = widgetId,
               let cachedData = WidgetHelper.getCachedEntry(forId: widgetId) {
                completion(SimpleEntryLarge(
                    date: Date(),
                    configuration: configuration,
                    widgetData: cachedData.0,
                    scheduleData: cachedData.1,
                    isLoading: true
                ))
            }
            
            if let widgetId = widgetId,
               let widget = WidgetHelper.getWidgetFromDefaults(withId: widgetId) {
                
                var finalWidgetData = widget.widgetData
                
                do {
                    if widget.widgetData["isClosestStop"] as? Bool == true {
                        if let location = await WidgetLocationManager.shared.getCurrentLocation() {
                            let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: getGlobalAPIForShortUsage())
                            if let stops = nearbyStops, !stops.isEmpty {
                                let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                                    widgetSizeSystemFormat: .systemLarge,
                                    widgetSizeStringFormat: nil
                                )
                                finalWidgetData["stops"] = await WidgetHelper.getFilteredStopsForWidget(stops, maxStops: maxStops, widgetData: widget.widgetData)
                                let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData, isClosestStop: true)
                                finalWidgetData = updatedWidgetData
                                
                                if !finalWidgetData.isEmpty, schedule != nil, let schedule = schedule, !schedule.isEmpty {
                                    WidgetHelper.cacheEntry(id: widgetId, widgetData: finalWidgetData, scheduleData: schedule, lastUpdatedTime: Date())
                                }
                                
                                completion(SimpleEntryLarge(
                                    date: Date(),
                                    configuration: configuration,
                                    widgetData: finalWidgetData,
                                    scheduleData: schedule,
                                    isLoading: false
                                ))
                            }
                        } else {
                            completion(SimpleEntryLarge(
                                date: Date(),
                                configuration: configuration,
                                widgetData: finalWidgetData,
                                isLoading: false,
                                errorMessage: "Location access required"
                            ))
                        }
                    } else {
                        let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData)
                        
                        if !finalWidgetData.isEmpty, schedule != nil, let schedule = schedule, !schedule.isEmpty {
                            WidgetHelper.cacheEntry(id: widgetId, widgetData: updatedWidgetData, scheduleData: schedule, lastUpdatedTime: Date())
                        }
                        
                        completion(SimpleEntryLarge(
                            date: Date(),
                            configuration: configuration,
                            widgetData: updatedWidgetData,
                            scheduleData: schedule,
                            isLoading: false
                        ))
                    }
                } catch {
                    completion(SimpleEntryLarge(
                        date: Date(),
                        configuration: configuration,
                        widgetData: finalWidgetData,
                        isLoading: false,
                        errorMessage: "Failed to fetch data"
                    ))
                }
            } else {
                completion(SimpleEntryLarge(
                    date: Date(),
                    configuration: configuration,
                    isLoading: false
                    
                ))
            }
        }
    }
    
    func getTimeline(for configuration: ConfigurationLargeIntent, in context: Context, completion: @escaping (Timeline<SimpleEntryLarge>) -> Void) {
        Task {
            let widgetId = configuration.widgetConfig?.identifier
            let widget = widgetId.flatMap { WidgetHelper.getWidgetFromDefaults(withId: $0) }
            var widgetData = widget?.widgetData
            
            if widget?.widgetData["isClosestStop"] as? Bool == true {
                if let location = await WidgetLocationManager.shared.getCurrentLocation() {
                    let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: getGlobalAPIForShortUsage())
                    if let stops = nearbyStops, !stops.isEmpty {
                        let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                            widgetSizeSystemFormat: .systemLarge,
                            widgetSizeStringFormat: nil
                        )
                        widgetData?["stops"] = await WidgetHelper.getFilteredStopsForWidget(stops, maxStops: maxStops, widgetData: widget?.widgetData)
                        let (_, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(widgetData ?? [:], isClosestStop: true)
                        widgetData = updatedWidgetData
                    }
                }
            }
            
            let timeline = await WidgetHelper.createTimeline(
                widgetId: widgetId ?? nil,
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
