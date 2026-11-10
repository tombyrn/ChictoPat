//
//  AppTheme.swift
//  ChictoPat
//
//  Created by Aaaaaaa a on 11/2/26.
//

import Foundation

import SwiftUI

enum AppTheme {
    static let background = Color(hex: 0xDCE8F5)
    static let panel = Color(hex: 0xF4F7FC)

    static let blue = Color(hex: 0x3979C6)
    static let lightBlue = Color(hex: 0x8FC5F4)
    static let darkBlue = Color(hex: 0x24558F)

    static let border = Color(hex: 0x7796B8)
    static let text = Color(hex: 0x1C2D42)

    static let ownMessage = Color(hex: 0xD4E8FC)
    static let otherMessage = Color(hex: 0xFFFFFF)

    static let pink = Color(hex: 0xF28DB5)
    
    static let buttonFace = Color(hex: 0xE5EDF7)
}

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
