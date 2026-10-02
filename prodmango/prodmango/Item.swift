//
//  Item.swift
//  prodmango
//
//  Created by Leon Conway on 24/08/2026.
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
