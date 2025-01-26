//
//  Item.swift
//  PeekTransit
//
//  Created by Ayman Agamy on 2025-01-25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
