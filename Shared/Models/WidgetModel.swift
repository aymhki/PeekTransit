

struct WidgetModel: Codable, Identifiable  {
    let id: String
    let widgetData: [String: Any]
    
    init(widgetData: [String: Any]) {
        self.id = "\(widgetData["id"] as? String ?? "No Id Found")"
        // self.widgetData = widgetData
        self.widgetData = WidgetDataMigrator.migrateWidgetDataIfNeeded(widgetData)

        
    }
    
    var name: String {
        return widgetData["name"] as? String ?? "Unnamed Widget" 
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case widgetData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        
        let codableDict = try container.decode([String: AnyCodable].self, forKey: .widgetData)
        widgetData = codableDict.mapValues { $0.value }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        let codableDict = widgetData.mapValues { AnyCodable($0) }
        try container.encode(codableDict, forKey: .widgetData)
        
    }
}

class WidgetDataMigrator {
    static func migrateWidgetDataIfNeeded(_ widgetData: [String: Any]) -> [String: Any] {
        var migratedData = widgetData
        
        if let stops = widgetData["stops"] as? [[String: Any]] {
            let migratedStops = stops.map { Stop(from: $0) }
            migratedData["stops"] = migratedStops
        }
        
        if let selectedStops = widgetData["selectedStops"] as? [[String: Any]] {
            let migratedStops = selectedStops.map { Stop(from: $0) }
            migratedData["selectedStops"] = migratedStops
        }
        
        if let preferredStops = widgetData["preferredStops"] as? [[String: Any]] {
            let migratedStops = preferredStops.map { Stop(from: $0) }
            migratedData["preferredStops"] = migratedStops
        }
        
        if let variants = widgetData["variants"] as? [[String: Any]] {
            let migratedVariants = variants.map { Variant(from: $0) }
            migratedData["variants"] = migratedVariants
        }
        
        if let selectedVariants = widgetData["selectedVariants"] as? [[String: Any]] {
            let migratedVariants = selectedVariants.map { Variant(from: $0) }
            migratedData["selectedVariants"] = migratedVariants
        }
        
        for (key, value) in widgetData {
            if let dict = value as? [String: Any] {
                if dict["number"] != nil && dict["street"] != nil {
                    migratedData[key] = Stop(from: dict)
                }
                else if dict["key"] != nil && dict["name"] != nil && dict["effective-from"] != nil {
                    migratedData[key] = Variant(from: dict)
                }
            }
        }
        
        return migratedData
    }
}

