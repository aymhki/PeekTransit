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
            let widgetId = configuration.widgetConfig?.identifier
            
            if let widgetId = widgetId,
               let cachedData = WidgetHelper.getCachedEntry(forId: widgetId) {
                completion(SimpleEntryMedium(
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
                                    widgetSizeSystemFormat: .systemMedium,
                                    widgetSizeStringFormat: nil
                                )
                                finalWidgetData["stops"] = await WidgetHelper.getFilteredStopsForWidget(stops, maxStops: maxStops, widgetData: widget.widgetData)
                                let (schedule, updatedWidgetData) = await WidgetHelper.getScheduleForWidget(finalWidgetData, isClosestStop: true)
                                finalWidgetData = updatedWidgetData
                                
                                // Cache successful result
                                WidgetHelper.cacheEntry(id: widgetId, data: finalWidgetData)
                                
                                completion(SimpleEntryMedium(
                                    date: Date(),
                                    configuration: configuration,
                                    widgetData: finalWidgetData,
                                    scheduleData: schedule,
                                    isLoading: false
                                ))
                            }
                        } else {
                            completion(SimpleEntryMedium(
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
                        
                        completion(SimpleEntryMedium(
                            date: Date(),
                            configuration: configuration,
                            widgetData: updatedWidgetData,
                            scheduleData: schedule,
                            isLoading: false
                        ))
                    }
                } catch {
                    completion(SimpleEntryMedium(
                        date: Date(),
                        configuration: configuration,
                        widgetData: finalWidgetData,
                        isLoading: false,
                        errorMessage: "Failed to fetch data"
                    ))
                }
            } else {
                completion(SimpleEntryMedium(
                    date: Date(),
                    configuration: configuration,
                    isLoading: false
                    
                ))
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
                    let nearbyStops = try? await TransitAPI.shared.getNearbyStops(userLocation: location, forShort: getGlobalAPIForShortUsage())
                    if let stops = nearbyStops, !stops.isEmpty {
                        let maxStops = WidgetHelper.getMaxSopsAllowedForWidget(
                            widgetSizeSystemFormat: .systemMedium,
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
                SimpleEntryMedium(
                    date: date,
                    configuration: config as! ConfigurationMediumIntent,
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
