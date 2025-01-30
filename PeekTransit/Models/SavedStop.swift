import Foundation

struct SavedStop: Codable, Identifiable {
    let id: String
    let stopData: [String: Any]
    
    init(stopData: [String: Any]) {
        self.id = "\(stopData["number"] as? Int ?? 0)"
        self.stopData = stopData
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case stopData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        
        let codableDict = try container.decode([String: AnyCodable].self, forKey: .stopData)
        stopData = codableDict.mapValues { $0.value }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
                let codableDict = stopData.mapValues { AnyCodable($0) }
        try container.encode(codableDict, forKey: .stopData)
    }
}
