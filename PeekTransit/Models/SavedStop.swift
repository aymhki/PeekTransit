import Foundation
import SwiftUI

struct SavedStop: Identifiable, Codable, Equatable {
    let id: String
    let stopData: Stop
    
    init(stopData: Stop) {
        self.id = "\(stopData.number)"
        self.stopData = stopData
    }
    
    static func == (lhs: SavedStop, rhs: SavedStop) -> Bool {
        return lhs.id == rhs.id
    }
}

