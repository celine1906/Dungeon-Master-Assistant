//
//  ChatEntryView.swift
//  D&D DM's Assistant
//
//  Created by Regina Celine Adiwinata on 09/06/26.
//

//import SwiftUI
//
//struct ChatEntryView: View {
//    let entry: ChatEntry
// 
//    var timeString: String {
//        let f = DateFormatter()
//        f.timeStyle = .short
//        return f.string(from: entry.timestamp)
//    }
// 
//    var body: some View {
//        VStack(alignment: .leading, spacing: 14) {
// 
//            // Query bubble - right aligned, max 50% width
//            GeometryReader { proxy in
//                HStack(spacing: 0) {
//                    Spacer(minLength: 0)
//                    VStack(alignment: .trailing, spacing: 4) {
//                        Text(entry.query)
//                            .font(.system(size: 13, design: .serif))
//                            .foregroundStyle(Color(red: 0.95, green: 0.90, blue: 0.78))
//                            .padding(.horizontal, 12).padding(.vertical, 8)
//                            .background(Color(red: 0.28, green: 0.20, blue: 0.12))
//                            .clipShape(RoundedRectangle(cornerRadius: 10))
//                            .lineLimit(nil)
//                            .fixedSize(horizontal: false, vertical: true)
//                        Text("\(timeString)  ·  \(String(format: "%.1f", entry.duration))s")
//                            .font(.system(size: 10, design: .monospaced))
//                            .foregroundStyle(Color(red: 0.45, green: 0.40, blue: 0.30))
//                    }
//                    .frame(maxWidth: proxy.size.width * 0.5, alignment: .trailing)
//                }
//                .frame(maxWidth: .infinity)
//            }
//            .frame(maxWidth: .infinity)
//            
//            // Response based on type (skip if placeholder/empty)
//            switch entry.responseType {
//            case .scenario(let scenarios):
//                scenarioResponse(scenarios)
//                
//            case .knowledge(let answer, let canonical, let sourceChunks):
//                if !answer.isEmpty {
//                    knowledgeResponse(answer, canonical: canonical, sourceChunks: sourceChunks)
//                }
//                
//            case .outOfScope:
//                knowledgeResponse("I don't know. The information is outside the available adventure context.", canonical: false, sourceChunks: [])
//            }
//        }
//        .frame(maxWidth: .infinity)
//    }
//    
//    @ViewBuilder
//    private func scenarioResponse(_ scenarios: [Scenario]) -> some View {
//        VStack(alignment: .leading, spacing: 8) {
//            // Location header
//            HStack(spacing: 6) {
//                Image(systemName: "scroll")
//                    .font(.system(size: 11))
//                let locationLabel = scenarios.first?.location.uppercased() ?? "LOCATION"
//                Text(locationLabel)
//                    .font(.system(size: 11, weight: .bold, design: .monospaced))
//                Spacer()
//                Text("\(scenarios.count) scenarios")
//                    .font(.system(size: 10, design: .monospaced))
//            }
//            .foregroundStyle(Color(red: 0.60, green: 0.50, blue: 0.32))
//            
//            // 3-column grid
//            LazyVGrid(columns: [
//                GridItem(.flexible()),
//                GridItem(.flexible()),
//                GridItem(.flexible())
//            ], spacing: 12) {
//                ForEach(scenarios) { scenario in
//                    ScenarioCard(scenario: scenario)
//                }
//            }
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//    }
//    
//    @ViewBuilder
//    private func knowledgeResponse(_ answer: String, canonical: Bool, sourceChunks: [String]) -> some View {
//        GeometryReader { proxy in
//            HStack(spacing: 0) {
//                VStack(alignment: .leading, spacing: 10) {
//                    Text(answer)
//                        .font(.system(size: 13, design: .serif))
//                        .foregroundStyle(Color(red: 0.80, green: 0.74, blue: 0.60))
//                        .padding(12)
//                        .background(Color(red: 0.14, green: 0.11, blue: 0.08))
//                        .clipShape(RoundedRectangle(cornerRadius: 8))
//                        .lineLimit(nil)
//                        .fixedSize(horizontal: false, vertical: true)
//                    
//                    // Source chunks if available
//                    if !sourceChunks.isEmpty {
//                        HStack(spacing: 4) {
//                            Image(systemName: "book.closed")
//                                .font(.system(size: 10))
//                            Text(sourceChunks.joined(separator: "  ·  "))
//                                .font(.system(size: 10, design: .monospaced))
//                        }
//                        .foregroundStyle(Color(red: 0.45, green: 0.40, blue: 0.30))
//                        .lineLimit(nil)
//                        .fixedSize(horizontal: false, vertical: true)
//                    }
//                }
//                .frame(maxWidth: proxy.size.width * 0.5, alignment: .leading)
//                
//                Spacer(minLength: 0)
//            }
//            .frame(maxWidth: .infinity)
//        }
//        .frame(maxWidth: .infinity)
//    }
//}
//

//
//  ChatEntryView.swift
//  D&D DM's Assistant
//
//  Displays one query-response pair in the chat scroll.
//  Query = right-aligned bubble. Response = left-aligned content.
//

import SwiftUI

struct ChatEntryView: View {
    let entry: ChatEntry

    private var timeLabel: String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return "\(fmt.string(from: entry.timestamp))  |  \(String(format: "%.1f", entry.duration))s"
    }

    var body: some View {
        // Vertical stack: query on top, response below
        VStack(alignment: .leading, spacing: 14) {
            queryBubble
            responseBubble
        }
    }

    // MARK: - Query (right-aligned, capped width)

    private var queryBubble: some View {
        HStack {
            Spacer(minLength: 40)
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.query)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.userText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.Color.userBubble)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))

                Text(timeLabel)
                    .font(Theme.Font.meta)
                    .foregroundStyle(Theme.Color.dim)
            }
        }
    }

    // MARK: - Response (left-aligned, type-dependent)

    @ViewBuilder
    private var responseBubble: some View {
        switch entry.response {
        case .scenario(let scenarios):
            ScenarioResponseView(scenarios: scenarios)

        case .knowledge(let answer, _, let sources):
            if !answer.isEmpty {
                KnowledgeBubble(answer: answer, sources: sources)
            } else if entry.revision > 0 {
                // A real response came back but answer was empty — show something.
                ErrorBubble(message: "The Chronicler returned an empty answer. Check the server logs.")
            }
            // revision == 0 is the loading placeholder — show nothing while waiting.

        case .outOfScope:
            KnowledgeBubble(
                answer: "I don't have information about that. Try asking something related to the adventure.",
                sources: []
            )

        case .error(let message):
            ErrorBubble(message: message)
        }
    }

}

// MARK: - Knowledge Bubble

private struct KnowledgeBubble: View {
    let answer: String
    let sources: [String]

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(answer)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.bodyText)
                    .padding(14)
                    .background(Theme.Color.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardCorner))

                if !sources.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 11))
                        Text(sources.joined(separator: "  |  "))
                            .font(Theme.Font.meta)
                    }
                    .foregroundStyle(Theme.Color.dim)
                }
            }
            .frame(maxWidth: 800, alignment: .leading)
            Spacer(minLength: 40)
        }
    }
}

// MARK: - Error Bubble

private struct ErrorBubble: View {
    let message: String

    var body: some View {
        HStack {
            Label(message, systemImage: "exclamationmark.triangle")
                .font(Theme.Font.bodySmall)
                .foregroundStyle(Theme.Color.offline)
                .padding(14)
                .background(Theme.Color.offline.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardCorner))
                .frame(maxWidth: 500, alignment: .leading)
            Spacer(minLength: 40)
        }
    }
}

// MARK: - Scenario Response (location header + card grid)

private struct ScenarioResponseView: View {
    let scenarios: [Scenario]

    private var locationLabel: String {
        scenarios.first?.location.uppercased() ?? "UNKNOWN"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Location header
            HStack(spacing: 6) {
                Image(systemName: "scroll")
                    .font(.system(size: 12))
                Text(locationLabel)
                    .font(Theme.Font.badge)
                Spacer()
                Text("\(scenarios.count) scenarios")
                    .font(Theme.Font.meta)
            }
            .foregroundStyle(Theme.Color.gold)

            // Card grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(scenarios) { scenario in
                    ScenarioCard(scenario: scenario)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Knowledge") {
    ChatEntryView(entry: ChatEntry(
        query: "Who is Matreous?",
        response: .knowledge(
            answer: "Matreous is a mage who studies extradimensional spaces. He is found in the Candlekeep library.",
            canonical: true,
            sources: ["room_m1_foyer", "npc_matreous"]
        ),
        duration: 8.2,
        timestamp: Date()
    ))
    .padding()
    .background(Theme.Color.surface)
}

#Preview("Scenario") {
    ChatEntryView(entry: ChatEntry(
        query: "Players try to burn the library",
        response: .scenario([
            Scenario(title: "Flames Among the Tomes", type: "Combat", location: "M3 - Library", description: "The fire spreads quickly through the dry books.", consequences: ["Books destroyed"], canonical: false, sourceChunks: ["room_m3"]),
            Scenario(title: "Imp Intervention", type: "Social", location: "M3 - Library", description: "The imp screams and tries to stop the players.", consequences: ["Imp hostile"], canonical: true, sourceChunks: ["npc_imp"]),
            Scenario(title: "Hidden Passage Revealed", type: "Discovery", location: "M3 - Library", description: "The flames reveal a hidden door behind the shelves.", consequences: ["New room access"], canonical: false, sourceChunks: []),
        ]),
        duration: 24.1,
        timestamp: Date()
    ))
    .padding()
    .background(Theme.Color.surface)
}

#Preview("Out of Scope") {
    ChatEntryView(entry: ChatEntry(
        query: "Who is Prabowo?",
        response: .outOfScope,
        duration: 3.1,
        timestamp: Date()
    ))
    .padding()
    .background(Theme.Color.surface)
}

#Preview("Error") {
    ChatEntryView(entry: ChatEntry(
        query: "What is in M2?",
        response: .error("Server unreachable. Is Ollama running?"),
        duration: 0,
        timestamp: Date()
    ))
    .padding()
    .background(Theme.Color.surface)
}
