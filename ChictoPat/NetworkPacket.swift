//
//  NetworkPacket.swift
//  ChictoPat
//
//  Created by Aaaaaaa a on 10/15/26.
//

import Foundation

enum PacketType: String, Codable {
    case join
    case chat
    case leave
    case roomDestroyed
    case drawing
}

struct NetworkPacket: Codable {
    let type: PacketType
    var chatMessage: ChatMessage? = nil
    var participantID: UUID? = nil
    var participantName: String? = nil
    var eventTimestamp: Date? = nil
    var drawingData: Data? = nil
}
