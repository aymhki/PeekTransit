import Foundation
import SwiftUI

struct SavedStop: Identifiable, Codable, Equatable {
    let id: String
    let stopData: [String: Any]
    
    init(stopData: [String: Any]) {
        if let number = stopData["number"] as? Int {
            self.id = "\(number)"
        } else {
            self.id = UUID().uuidString
        }
        self.stopData = stopData
    }
    
    // Required for Codable conformance since [String: Any] isn't naturally Codable
    enum CodingKeys: String, CodingKey {
        case id
        case stopData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        
        // Decode the dictionary as [String: AnyCodable]
        let anyContainer = try container.decode([String: AnyCodable].self, forKey: .stopData)
        stopData = anyContainer.mapValues { $0.value }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        
        // Encode the dictionary using AnyCodable
        let codableDict = stopData.mapValues { AnyCodable($0) }
        try container.encode(codableDict, forKey: .stopData)
    }
    
    static func == (lhs: SavedStop, rhs: SavedStop) -> Bool {
        return lhs.id == rhs.id
    }
}

