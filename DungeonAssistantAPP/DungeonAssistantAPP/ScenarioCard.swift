//
//  ScenarioCard.swift
//  D&D DM's Assistant
//
//  Created by Regina Celine Adiwinata on 09/06/26.
//
//
//import SwiftUI
//
//struct ScenarioCard: View {
//    let scenario: Scenario
// 
//    var typeColor: Color {
//        switch scenario.type.lowercased() {
//        case "combat":       return Color(red: 0.78, green: 0.25, blue: 0.25)
//        case "social":       return Color(red: 0.28, green: 0.58, blue: 0.45)
//        case "investigation":return Color(red: 0.35, green: 0.48, blue: 0.72)
//        case "exploration":  return Color(red: 0.60, green: 0.48, blue: 0.28)
//        case "puzzle":       return Color(red: 0.55, green: 0.52, blue: 0.35)
//        case "discovery":    return Color(red: 0.48, green: 0.58, blue: 0.42)
//        default:             return Color(red: 0.55, green: 0.45, blue: 0.30)
//        }
//    }
// 
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
// 
//            // Header
//            VStack(alignment: .leading, spacing: 4) {
//                Text(scenario.title)
//                    .font(.system(size: 14, weight: .semibold, design: .serif))
//                    .foregroundStyle(Color(red: 0.95, green: 0.88, blue: 0.72))
//                    .lineLimit(2)
//                
//                HStack(spacing: 4) {
//                    Text(scenario.type.uppercased())
//                        .font(.system(size: 9, weight: .bold, design: .monospaced))
//                        .foregroundStyle(typeColor)
//                        .padding(.horizontal, 5).padding(.vertical, 2)
//                        .background(typeColor.opacity(0.12))
//                        .clipShape(RoundedRectangle(cornerRadius: 3))
//                    
//                    if !scenario.canonical {
//                        Text("HOMEBREW")
//                            .font(.system(size: 9, weight: .bold, design: .monospaced))
//                            .foregroundStyle(Color(red: 0.72, green: 0.58, blue: 0.30))
//                            .padding(.horizontal, 5).padding(.vertical, 2)
//                            .background(Color(red: 0.72, green: 0.58, blue: 0.30).opacity(0.12))
//                            .clipShape(RoundedRectangle(cornerRadius: 3))
//                    }
//                    Spacer()
//                }
//            }
// 
//            // Description
//            Text(scenario.description)
//                .font(.system(size: 12, design: .serif))
//                .foregroundStyle(Color(red: 0.80, green: 0.74, blue: 0.60))
// 
//            // Consequences if available
//            if !scenario.consequences.isEmpty {
//                Divider().background(Color(red: 0.40, green: 0.34, blue: 0.24))
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("CONSEQUENCES")
//                        .font(.system(size: 9, weight: .bold, design: .monospaced))
//                        .foregroundStyle(Color(red: 0.55, green: 0.48, blue: 0.32))
//                    
//                    ForEach(scenario.consequences, id: \.self) { c in
//                        HStack(alignment: .top, spacing: 4) {
//                            Text("›")
//                                .foregroundStyle(Color(red: 0.72, green: 0.58, blue: 0.30))
//                            Text(c)
//                                .font(.system(size: 11, design: .serif))
//                                .foregroundStyle(Color(red: 0.72, green: 0.68, blue: 0.58))
//                        }
//                    }
//                }
//            }
// 
//            // Sources
//            if !scenario.source_chunks.isEmpty {
//                Divider().background(Color(red: 0.40, green: 0.34, blue: 0.24))
//                HStack(spacing: 3) {
//                    Image(systemName: "book.closed")
//                        .font(.system(size: 9))
//                    Text(scenario.source_chunks.joined(separator: "  ·  "))
//                        .font(.system(size: 9, design: .monospaced))
//                        .lineLimit(1)
//                }
//                .foregroundStyle(Color(red: 0.45, green: 0.40, blue: 0.30))
//            }
//        }
//        .padding(11)
//        .background(Color(red: 0.18, green: 0.14, blue: 0.10))
//        .overlay(
//            RoundedRectangle(cornerRadius: 8)
//                .stroke(Color(red: 0.42, green: 0.34, blue: 0.20), lineWidth: 1)
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//    }
//}

//
//  ScenarioCard.swift
//  D&D DM's Assistant
//
//  A single scenario option displayed in the 3-column grid.
//

import SwiftUI

struct ScenarioCard: View {
    let scenario: Scenario

    private var typeColor: Color {
        Theme.Color.scenarioType(scenario.type)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            description
            if !scenario.consequences.isEmpty {
                consequences
            }
            if !scenario.sourceChunks.isEmpty {
                sources
            }
        }
        .padding(Theme.Layout.cardPadding)
        .background(Theme.Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Layout.cardCorner)
                .stroke(Theme.Color.borderCard, lineWidth: 1)
        )
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(scenario.title)
                .font(Theme.Font.heading)
                .foregroundStyle(Theme.Color.userText)
                .lineLimit(2)

            HStack(spacing: 6) {
                Badge(label: scenario.type.uppercased(), color: typeColor)
                if !scenario.canonical {
                    Badge(label: "HOMEBREW", color: Theme.Color.gold)
                }
                Spacer()
            }
        }
    }

    private var description: some View {
        Text(scenario.description)
            .font(Theme.Font.bodySmall)
            .foregroundStyle(Theme.Color.bodyText)
    }

    private var consequences: some View {
        Group {
            Divider().background(Theme.Color.divider)
            VStack(alignment: .leading, spacing: 4) {
                Text("CONSEQUENCES")
                    .font(Theme.Font.badge)
                    .foregroundStyle(Theme.Color.muted)

                ForEach(scenario.consequences, id: \.self) { item in
                    HStack(alignment: .top, spacing: 5) {
                        Text("\u{203A}")
                            .foregroundStyle(Theme.Color.gold)
                        Text(item)
                            .font(Theme.Font.bodySmall)
                            .foregroundStyle(Theme.Color.bodyText)
                    }
                }
            }
        }
    }

    private var sources: some View {
        Group {
            Divider().background(Theme.Color.divider)
            HStack(spacing: 4) {
                Image(systemName: "book.closed")
                    .font(.system(size: 10))
                Text(scenario.sourceChunks.joined(separator: "  |  "))
                    .font(Theme.Font.meta)
                    .lineLimit(1)
            }
            .foregroundStyle(Theme.Color.dim)
        }
    }
}

// MARK: - Reusable Badge

private struct Badge: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(Theme.Font.badge)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        ScenarioCard(scenario: Scenario(
            title: "Search the Bookshelves",
            type: "Investigation",
            location: "M3 - Library",
            description: "Players search the dusty shelves for hidden journals.",
            consequences: ["Find Fistandia's journal", "Trigger dust trap"],
            canonical: true,
            sourceChunks: ["room_m3_library"]
        ))
        ScenarioCard(scenario: Scenario(
            title: "Talk to the Imp",
            type: "Social",
            location: "M3 - Library",
            description: "The imp offers cryptic hints about the mansion.",
            consequences: [],
            canonical: true,
            sourceChunks: ["npc_imp"]
        ))
        ScenarioCard(scenario: Scenario(
            title: "Force Open the Cabinet",
            type: "Exploration",
            location: "M3 - Library",
            description: "Strength check to break the lock.",
            consequences: ["Noise alerts creatures"],
            canonical: false,
            sourceChunks: []
        ))
    }
    .padding()
    .background(Theme.Color.surface)
}
