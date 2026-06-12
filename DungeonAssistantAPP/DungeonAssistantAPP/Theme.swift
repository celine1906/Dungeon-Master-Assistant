//
//  Theme.swift
//  DungeonAssistantAPP
//
//  Created by Nicholas Tristandi on 11/06/26.
//


import SwiftUI

enum Theme {

    // MARK: - Palette

    enum Color {
        // Backgrounds
        static let surface      = SwiftUI.Color(red: 0.11, green: 0.09, blue: 0.06)
        static let surfaceRaised = SwiftUI.Color(red: 0.14, green: 0.11, blue: 0.08)
        static let surfaceCard  = SwiftUI.Color(red: 0.18, green: 0.14, blue: 0.10)
        static let bar          = SwiftUI.Color(red: 0.13, green: 0.10, blue: 0.07)

        // User bubble
        static let userBubble   = SwiftUI.Color(red: 0.28, green: 0.20, blue: 0.12)
        static let userText     = SwiftUI.Color(red: 0.95, green: 0.90, blue: 0.78)

        // Assistant text
        static let bodyText     = SwiftUI.Color(red: 0.80, green: 0.74, blue: 0.60)
        static let heading      = SwiftUI.Color(red: 0.88, green: 0.80, blue: 0.62)
        static let muted        = SwiftUI.Color(red: 0.50, green: 0.44, blue: 0.30)
        static let dim          = SwiftUI.Color(red: 0.45, green: 0.40, blue: 0.30)

        // Accents
        static let gold         = SwiftUI.Color(red: 0.72, green: 0.58, blue: 0.30)
        static let goldBright   = SwiftUI.Color(red: 0.82, green: 0.65, blue: 0.35)
        static let border       = SwiftUI.Color(red: 0.38, green: 0.30, blue: 0.18)
        static let borderCard   = SwiftUI.Color(red: 0.42, green: 0.34, blue: 0.20)
        static let divider      = SwiftUI.Color(red: 0.32, green: 0.26, blue: 0.16)

        // Status
        static let online       = SwiftUI.Color(red: 0.35, green: 0.72, blue: 0.45)
        static let offline      = SwiftUI.Color(red: 0.78, green: 0.32, blue: 0.28)
        static let unknown      = SwiftUI.Color(red: 0.40, green: 0.36, blue: 0.28)
        
        // Red Border

        // Scenario type badges
        static func scenarioType(_ type: String) -> SwiftUI.Color {
            switch type.lowercased() {
            case "combat":        return SwiftUI.Color(red: 0.78, green: 0.25, blue: 0.25)
            case "social":        return SwiftUI.Color(red: 0.28, green: 0.58, blue: 0.45)
            case "investigation": return SwiftUI.Color(red: 0.35, green: 0.48, blue: 0.72)
            case "exploration":   return SwiftUI.Color(red: 0.60, green: 0.48, blue: 0.28)
            case "puzzle":        return SwiftUI.Color(red: 0.55, green: 0.52, blue: 0.35)
            case "discovery":     return SwiftUI.Color(red: 0.48, green: 0.58, blue: 0.42)
            default:              return SwiftUI.Color(red: 0.55, green: 0.45, blue: 0.30)
            }
        }
    }

    // MARK: - Typography

    enum Font {
        
        static let body       = SwiftUI.Font.system(size: 15 + 3, design: .serif)
        static let bodySmall  = SwiftUI.Font.system(size: 13 + 3, design: .serif)
        static let heading    = SwiftUI.Font.system(size: 16 + 3, weight: .semibold, design: .serif)
        static let title      = SwiftUI.Font.system(size: 20 + 3, weight: .bold, design: .serif)
        static let caption    = SwiftUI.Font.system(size: 11 + 3, design: .monospaced)
        static let badge      = SwiftUI.Font.system(size: 10 + 3, weight: .bold, design: .monospaced)
        static let meta       = SwiftUI.Font.system(size: 11 + 3, design: .monospaced)
    }

    // MARK: - Layout

    enum Layout {
        static let bubbleMaxWidth: CGFloat = 0.65
        static let cornerRadius: CGFloat = 10
        static let cardCorner: CGFloat = 8
        static let spacing: CGFloat = 16
        static let cardPadding: CGFloat = 14
    }
}
