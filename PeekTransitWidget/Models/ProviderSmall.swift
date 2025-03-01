import WidgetKit
import SwiftUI
import Intents
import Combine
import Foundation


struct ProviderSmall: IntentTimelineProvider {
    typealias Entry = SimpleEntrySmall
    
    func placeholder(in context: Context) -> SimpleEntrySmall {
        SimpleEntrySmall(date: Date(), configuration: ConfigurationSmallIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationSmallIntent, in context: Context, completion: @escaping (SimpleEntrySmall) -> Void) {
        Task {
            let widgetId = configuration.widgetConfig?.identifier
            
            // First return cached data with loading state
            if let widgetId = widgetId,
               let cachedData = WidgetHelper.getCachedEntry(forId: widgetId) {
                completion(SimpleEntrySmall(
                    date: Date(),
                    configuration: configuration,
                    widgetData: cachedData,
                    isLoading: true
                ))
            }
            
            // Then fetch new data
            if let widgetId = widgetId,
               let widget = WidgetHelper.getWidgetFromDefaults(withId: widgetId) {
                
                var finalWidgetData = widget.widgetData
                
                do {
                    if widget.widgetData["isClosestStop"] as? Bool == true {
                        if let location = await LocationManager.shared.getCurrentLocation() {
                            let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: getGlobalAPIForShortUsage())
                            if let stops = nearbyStops, !stops.isEmpty {
                                let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                                    widgetSizeSystemFormat: .systemSmall,
                                    widgetSizeStringFormat: nil
                                )
                                finalWidgetData["stops"] = await WidgetHelper.getFilteredStopsForWidget(stops, maxStops: maxStops, widgetData: widget.widgetData)
                                let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData, isClosestStop: true)
                                finalWidgetData = updatedWidgetData
                                
                                // Cache successful result
                                WidgetHelper.cacheEntry(id: widgetId, data: finalWidgetData)
                                
                                completion(SimpleEntrySmall(
                                    date: Date(),
                                    configuration: configuration,
                                    widgetData: finalWidgetData,
                                    scheduleData: schedule,
                                    isLoading: false
                                ))
                            }
                        } else {
                            completion(SimpleEntrySmall(
                                date: Date(),
                                configuration: configuration,
                                widgetData: finalWidgetData,
                                isLoading: false,
                                errorMessage: "Location access required"
                            ))
                        }
                    } else {
                        let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData)
                        
                        // Cache successful result
                        WidgetHelper.cacheEntry(id: widgetId, data: updatedWidgetData)
                        
                        completion(SimpleEntrySmall(
                            date: Date(),
                            configuration: configuration,
                            widgetData: updatedWidgetData,
                            scheduleData: schedule,
                            isLoading: false
                        ))
                    }
                } catch {
                    completion(SimpleEntrySmall(
                        date: Date(),
                        configuration: configuration,
                        widgetData: finalWidgetData,
                        isLoading: false,
                        errorMessage: "Failed to fetch data"
                    ))
                }
            } else {
                completion(SimpleEntrySmall(
                    date: Date(),
                    configuration: configuration,
                    isLoading: false
                    
                ))
            }
        }
    }
    
    func getTimeline(for configuration: ConfigurationSmallIntent, in context: Context, completion: @escaping (Timeline<SimpleEntrySmall>) -> Void) {
        Task {
            let widgetId = configuration.widgetConfig?.identifier
            let widget = widgetId.flatMap { WidgetHelper.getWidgetFromDefaults(withId: $0) }
            var widgetData = widget?.widgetData
            
            if widget?.widgetData["isClosestStop"] as? Bool == true {
                if let location = await LocationManager.shared.getCurrentLocation() {
                    let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: getGlobalAPIForShortUsage())
                    if let stops = nearbyStops, !stops.isEmpty {
                        let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                            widgetSizeSystemFormat: .systemSmall,
                            widgetSizeStringFormat: nil
                        )
                        widgetData?["stops"] = await WidgetHelper.getFilteredStopsForWidget(stops, maxStops: maxStops, widgetData: widget?.widgetData)
                        let (_, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(widgetData ?? [:], isClosestStop: true)
                        widgetData = updatedWidgetData
                    }
                }
            }
            
            let timeline = await WidgetHelper.createTimeline(
                currentDate: Date(),
                configuration: configuration,
                widgetData: widgetData
            ) { date, config, data, schedule in
                SimpleEntrySmall(
                    date: date,
                    configuration: config as! ConfigurationSmallIntent,
                    widgetData: data,
                    scheduleData: schedule
                )
            }
            
            let nextUpdate = Calendar.current.date(byAdding: .second, value: getRefreshWidgetTimelineAfterHowManySeconds(), to: Date())!
               let timelineWithShorterUpdate = Timeline(
                   entries: timeline.entries,
                   policy: .after(nextUpdate)
               )
               
               completion(timelineWithShorterUpdate)
        }
    }
}
