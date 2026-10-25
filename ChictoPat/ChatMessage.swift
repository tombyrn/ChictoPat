//
//  Message.swift
//  ChictoPat
//
//  Created by Aaaaaaa a on 10/5/26.
//

import Foundation

struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let senderID: UUID
    let senderName: String
    let text: String
    let timestamp: Date
    
    var drawingData: Data? = nil // nil for text messages
}
