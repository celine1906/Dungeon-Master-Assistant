//
//  Models.swift
//  D&D DM's Assistant
//
//  Created by Regina Celine Adiwinata on 09/06/26.
//

//import Foundation
//
//// API Req
//struct QueryRequest: Codable {
//    let query: String
//    let k_fetch: Int
//    let k_final: Int
//}
// 
//// Old format: answer is a string
//struct QueryResponse: Codable {
//    let answer: String
//}
//
//// New format: structured response
//struct QueryResponseNew: Codable {
//    let response_type: String
//    let scenarios: [Scenario]?
//    let answer: String?
//    let canonical: Bool?
//    let source_chunks: [String]?
//}
// 
//struct Scenario: Codable, Identifiable {
//    var id: String { title }
//    let title: String
//    let type: String
//    let location: String
//    let description: String
//    let consequences: [String]
//    let canonical: Bool
//    let source_chunks: [String]
//}
//
//enum ResponseType {
//    case scenario(scenarios: [Scenario])
//    case knowledge(answer: String, canonical: Bool, source_chunks: [String])
//    case outOfScope
//}
// 
//struct ChatEntry: Identifiable {
//    let id = UUID()
//    let query: String
//    let responseType: ResponseType
//    let duration: Double
//    let timestamp: Date
//}


import Foundation

// MARK: - API Request

struct QueryRequest: Codable {
    let query: String
    let kFetch: Int
    let kFinal: Int
    let mode: String  // "fast" or "smart"

    enum CodingKeys: String, CodingKey {
        case query
        case kFetch = "k_fetch"
        case kFinal = "k_final"
        case mode
    }
}

// MARK: - API Response (wraps the raw answer string from FastAPI)

struct QueryResponse: Codable {
    let answer: String
}

// MARK: - Parsed JSON inside the answer string

struct ParsedResponse: Codable {
    let responseType: String
    let scenarios: [Scenario]?
    let answer: String?
    let canonical: Bool?
    let sourceChunks: [String]?

    enum CodingKeys: String, CodingKey {
        case responseType = "response_type"
        case scenarios
        case answer
        case canonical
        case sourceChunks = "source_chunks"
    }
}

// MARK: - Scenario

struct Scenario: Codable, Identifiable {
    var id: String { title }
    let title: String
    let type: String
    let location: String
    let description: String
    let consequences: [String]
    let canonical: Bool
    let sourceChunks: [String]

    enum CodingKeys: String, CodingKey {
        case title, type, location, description
        case consequences, canonical
        case sourceChunks = "source_chunks"
    }
}

// MARK: - UI Display Types

enum ResponseType {
    case scenario([Scenario])
    case knowledge(answer: String, canonical: Bool, sources: [String])
    case outOfScope
    case error(String)
}

struct ChatEntry: Identifiable {
    let id: UUID
    let query: String
    let response: ResponseType
    let duration: Double
    let timestamp: Date
    var revision: Int

    init(
        id: UUID = UUID(),
        query: String,
        response: ResponseType,
        duration: Double,
        timestamp: Date,
        revision: Int = 0
    ) {
        self.id = id
        self.query = query
        self.response = response
        self.duration = duration
        self.timestamp = timestamp
        self.revision = revision
    }
}

// MARK: - Chapter

struct Chapter: Identifiable {
    let id: Int
    let title: String
    let sourcebook: String
    let description: String

    static let all: [Chapter] = [
        Chapter(
            id: 1,
            title: "The Joy of Extradimensional Spaces",
            sourcebook: "Candlekeep Mysteries",
            description: "A wizard's mansion trapped in a pocket dimension, haunted by puzzles and dark secrets."
        ),
        Chapter(
            id: 2,
            title: "Mazfroth's Mighty Digressions",
            sourcebook: "Candlekeep Mysteries",
            description: "Coming soon"
        ),
        Chapter(
            id: 3,
            title: "Book of the Raven",
            sourcebook: "Candlekeep Mysteries",
            description: "Coming soon"
        )
    ]
}
