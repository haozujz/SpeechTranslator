//
//  Item.swift
//  SpeechTranslator
//
//  Created by Joseph Zhu on 7/10/2024.
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
