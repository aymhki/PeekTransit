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
            
            WidgetCenter.shared.reloadAllTimelines()
            let collection = INObjectCollection(items: widgetConfigs)
            return collection
            
        } else {
            
            return INObjectCollection(items: [])
        }
    }
    
    func provideWidgetConfigOptionsCollection(for intent: ConfigurationLargeIntent, with completion: @escaping (INObjectCollection<WidgetConfig>?, Error?) -> Void) {
        
        completion(getCollection(sizeGiven: "large"), nil)
    }
    
    
    func provideWidgetConfigOptionsCollection(for intent: ConfigurationMediumIntent, with completion: @escaping (INObjectCollection<WidgetConfig>?, Error?) -> Void) {
        
        completion(getCollection(sizeGiven: "medium"), nil)
    }
    
    
    func provideWidgetConfigOptionsCollection(for intent: ConfigurationSmallIntent, with completion: @escaping (INObjectCollection<WidgetConfig>?, Error?) -> Void) {
        
        completion(getCollection(sizeGiven: "small"), nil)
        
    }
    
    
    func provideWidgetConfigOptionsCollection(for intent: ConfigurationLockscreenIntent, with completion: @escaping (INObjectCollection<WidgetConfig>?, Error?) -> Void) {
        completion(getCollection(sizeGiven: "lockscreen"), nil)
        
    }
    
}
