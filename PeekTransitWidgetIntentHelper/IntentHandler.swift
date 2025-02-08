import Intents
import os
import WidgetKit


class IntentHandler: INExtension, ConfigurationLargeIntentHandling, ConfigurationSmallIntentHandling, ConfigurationLockscreenIntentHandling, ConfigurationMediumIntentHandling {
    
    func getCollection(sizeGiven: String) -> INObjectCollection<WidgetConfig>{
        
        if let sharedDefaults = SharedDefaults.userDefaults,
           let data = sharedDefaults.data(forKey: SharedDefaults.widgetsKey),
           let savedWidgets = try? JSONDecoder().decode([WidgetModel].self, from: data) {
            
            let widgetConfigs = savedWidgets.compactMap { widget -> WidgetConfig? in
                guard let id = widget.widgetData["id"] as? String,
                      let name = widget.widgetData["name"] as? String,
                      let size = widget.widgetData["size"] as? String,
                      sizeGiven == size
                      else {
                        return nil
                      }
                
                return WidgetConfig(identifier: id, display: name)
            }
            
            let collection = INObjectCollection(items: widgetConfigs)
            return collection
            
        } else {
            
            return INObjectCollection(items: [])
        }
    }
    
    func provideWidgetConfigOptionsCollection(for intent: ConfigurationLargeIntent, with completion: @escaping (INObjectCollection<WidgetConfig>?, Error?) -> Void) {
            
        let collection = getCollection(sizeGiven: "large")
        
        if collection.allItems.isEmpty {
            let error = NSError(domain: "com.PeekTransit.PeekTransitWidget", code: 404, userInfo: [NSLocalizedDescriptionKey: "No widget configurations found for this size. Create one in the app, then come back here to try again."])
            completion(nil, error)
        } else {
            completion(collection, nil)
        }
    }
    
    
    func provideWidgetConfigOptionsCollection(for intent: ConfigurationMediumIntent, with completion: @escaping (INObjectCollection<WidgetConfig>?, Error?) -> Void) {
        
        let collection = getCollection(sizeGiven: "medium")
        
        if collection.allItems.isEmpty {
            let error = NSError(domain: "com.PeekTransit.PeekTransitWidget", code: 404, userInfo: [NSLocalizedDescriptionKey: "No widget configurations found for this size. Create one in the app, then come back here to try again."])
            completion(nil, error)
        } else {
            completion(collection, nil)
        }
    }
    
    
    func provideWidgetConfigOptionsCollection(for intent: ConfigurationSmallIntent, with completion: @escaping (INObjectCollection<WidgetConfig>?, Error?) -> Void) {
        
        let collection = getCollection(sizeGiven: "small")
        
        if collection.allItems.isEmpty {
            let error = NSError(domain: "com.PeekTransit.PeekTransitWidget", code: 404, userInfo: [NSLocalizedDescriptionKey: "No widget configurations found for this size. Create one in the app, then come back here to try again."])
            completion(nil, error)
        } else {
            completion(collection, nil)
        }
        
    }
    
    
    func provideWidgetConfigOptionsCollection(for intent: ConfigurationLockscreenIntent, with completion: @escaping (INObjectCollection<WidgetConfig>?, Error?) -> Void) {
        let collection = getCollection(sizeGiven: "lockscreen")
        
        if collection.allItems.isEmpty {
            let error = NSError(domain: "com.PeekTransit.PeekTransitWidget", code: 404, userInfo: [NSLocalizedDescriptionKey: "No widget configurations found for this size. Create one in the app, then come back here to try again."])
            completion(nil, error)
        } else {
            completion(collection, nil)
        }
    }
    
}
