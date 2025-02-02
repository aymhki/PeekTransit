import Intents

class IntentHandler: INExtension, ConfigurationIntentHandling {
    
    func provideWidgetConfigOptionsCollection(for intent: ConfigurationIntent, with completion: @escaping (INObjectCollection<WidgetConfig>?, Error?) -> Void) {
        
        let widgetConfigs: [WidgetConfig] = [
            WidgetConfig(identifier: "id1", display: "name1"),
            WidgetConfig(identifier: "id2", display: "name2")
        ]
        
        
        let collection = INObjectCollection<WidgetConfig>(items: widgetConfigs)
        
        
        completion(collection, nil)
        
        
    }
    
    
}
