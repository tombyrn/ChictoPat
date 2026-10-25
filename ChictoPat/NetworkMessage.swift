//
//  NetworkMessage.swift
//  ChictoPat
//
//  Created by Aaaaaaa a on 10/5/26.
//

import Foundation

enum NetworkMessage {
    // encode message as [length][content]
    static func encode<T: Encodable>(_ message: T) throws -> Data {
        let jsonData = try JSONEncoder().encode(message)
        
        let length = UInt32(jsonData.count)
        var lengthData = Data()
        
        lengthData.append(UInt8((length >> 24) & 0xFF))
        lengthData.append(UInt8((length >> 16) & 0xFF))
        lengthData.append(UInt8((length >> 8) & 0xFF))
        lengthData.append(UInt8(length & 0xFF))
        
        return lengthData + jsonData
    }
}
