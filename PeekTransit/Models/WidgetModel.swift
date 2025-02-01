

struct WidgetModel: Codable, Identifiable  {
    let id: String
    let widgetData: [String: Any]
    
    init(widgetData: [String: Any]) {
        self.id = "\(widgetData["id"] as? String ?? "No Id Found")"
        self.widgetData = widgetData
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

