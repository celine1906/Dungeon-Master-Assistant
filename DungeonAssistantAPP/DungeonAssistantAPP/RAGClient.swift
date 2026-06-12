//
//  RAGClient.swift
//  D&D DM's Assistant
//
//  Created by Regina Celine Adiwinata on 09/06/26.
//


//import Foundation
//import Combine
// 
//class RAGClient: ObservableObject {
//    @Published var chatHistory: [ChatEntry] = []
//    @Published var isLoading: Bool = false
//    @Published var statusMessage: String = "Ready"
//    @Published var isConnected: Bool? = nil
//    @Published var elapsedSeconds: Double = 0
//    @Published var lastDuration: Double? = nil
//    @Published var errorMessage: String? = nil
// 
//    private var timerTask: Task<Void, Never>? = nil
//    private var startTime: Date? = nil
//    private var pendingEntryIndex: Int? = nil
// 
//    var baseURL: String = "http://127.0.0.1:8000"
// 
//    private func startTimer() {
//        startTime = Date()
//        elapsedSeconds = 0
//        timerTask?.cancel()
//        timerTask = Task {
//            while !Task.isCancelled {
//                try? await Task.sleep(nanoseconds: 100_000_000)
//                guard let start = startTime else { return }
//                await MainActor.run { elapsedSeconds = Date().timeIntervalSince(start) }
//            }
//        }
//    }
// 
//    private func stopTimer() {
//        timerTask?.cancel()
//        timerTask = nil
//        if let start = startTime { lastDuration = Date().timeIntervalSince(start) }
//        startTime = nil
//    }
// 
//    func checkHealth() async {
//        await MainActor.run { isLoading = true; statusMessage = "Checking connection..." }
//        guard let url = URL(string: "\(baseURL)/health") else {
//            await MainActor.run { isConnected = false; statusMessage = "Invalid URL"; isLoading = false }
//            return
//        }
//        do {
//            let (_, httpResponse) = try await URLSession.shared.data(from: url)
//            let code = (httpResponse as? HTTPURLResponse)?.statusCode ?? 0
//            await MainActor.run {
//                isConnected = code == 200
//                statusMessage = code == 200 ? "Server connected" : "Server responded \(code)"
//                isLoading = false
//            }
//        } catch {
//            await MainActor.run { isConnected = false; statusMessage = "Cannot reach server"; isLoading = false }
//        }
//    }
// 
//    func sendQuery(query: String) async {
//        // Append placeholder entry langsung (user chat visible immediately)
//        let placeholderEntry = ChatEntry(
//            query: query,
//            responseType: .knowledge(answer: "", canonical: false, source_chunks: []),
//            duration: 0,
//            timestamp: Date()
//        )
//        
//        await MainActor.run {
//            chatHistory.append(placeholderEntry)
//            pendingEntryIndex = chatHistory.count - 1
//            isLoading = true
//            errorMessage = nil
//            statusMessage = "Retrieving..."
//        }
//        
//        startTimer()
// 
//        guard let url = URL(string: "\(baseURL)/query") else {
//            stopTimer()
//            await MainActor.run { statusMessage = "Invalid URL"; isLoading = false }
//            return
//        }
// 
//        do {
//            let body = QueryRequest(query: query, k_fetch: 20, k_final: 5)
//            var request = URLRequest(url: url)
//            request.httpMethod = "POST"
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            request.httpBody = try JSONEncoder().encode(body)
//            request.timeoutInterval = 120
// 
//            let (data, httpResponse) = try await URLSession.shared.data(for: request)
//            let code = (httpResponse as? HTTPURLResponse)?.statusCode ?? 0
//            stopTimer()
//            let duration = lastDuration ?? 0
// 
//            if code == 200 {
//                let decoded = try JSONDecoder().decode(QueryResponse.self, from: data)
//                let answerString = decoded.answer
//                
//                print("🔍 RAW ANSWER LENGTH: \(answerString.count)")
//                print("🔍 FIRST 200 CHARS: \(answerString.prefix(200))")
//                
//                var responseType: ResponseType = .outOfScope
//                
//                // Try to parse answer string as new format JSON
//                if let answerData = answerString.data(using: .utf8) {
//                    // First, try to see if it's valid JSON at all
//                    if let jsonObject = try? JSONSerialization.jsonObject(with: answerData) {
//                        print("✅ VALID JSON STRUCTURE")
//                        if let dict = jsonObject as? [String: Any] {
//                            print("✅ DICT KEYS: \(dict.keys.sorted())")
//                            if let type = dict["response_type"] as? String {
//                                print("✅ RESPONSE TYPE: \(type)")
//                            }
//                            if let scenarios = dict["scenarios"] as? [[String: Any]] {
//                                print("✅ SCENARIOS COUNT: \(scenarios.count)")
//                            }
//                        }
//                    } else {
//                        print("❌ NOT VALID JSON")
//                    }
//                    
//                    do {
//                        let newFormat = try JSONDecoder().decode(QueryResponseNew.self, from: answerData)
//                        print("✅ DECODED SUCCESSFULLY: type=\(newFormat.response_type)")
//                        
//                        switch newFormat.response_type {
//                        case "scenario":
//                            if let scenarios = newFormat.scenarios, !scenarios.isEmpty {
//                                print("✅ FOUND \(scenarios.count) SCENARIOS")
//                                for (i, s) in scenarios.enumerated() {
//                                    print("  ✅ Scenario \(i+1): \(s.title)")
//                                }
//                                responseType = .scenario(scenarios: scenarios)
//                            } else {
//                                print("⚠️ NO SCENARIOS FOUND")
//                            }
//                        case "answer":
//                            if let answer = newFormat.answer, let canonical = newFormat.canonical, let sourceChunks = newFormat.source_chunks {
//                                responseType = .knowledge(answer: answer, canonical: canonical, source_chunks: sourceChunks)
//                                print("✅ DECODED KNOWLEDGE RESPONSE")
//                            }
//                        default:
//                            print("⚠️ UNKNOWN RESPONSE TYPE: \(newFormat.response_type)")
//                        }
//                    } catch {
//                        print("❌ DECODING FAILED!")
//                        print("❌ ERROR: \(error)")
//                        if let decodingError = error as? DecodingError {
//                            switch decodingError {
//                            case .typeMismatch(let type, let context):
//                                print("❌ TYPE MISMATCH: Expected \(type)")
//                                print("❌ PATH: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
//                                print("❌ CONTEXT: \(context.debugDescription)")
//                            case .valueNotFound(let type, let context):
//                                print("❌ VALUE NOT FOUND: \(type)")
//                                print("❌ PATH: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
//                            case .keyNotFound(let key, let context):
//                                print("❌ KEY NOT FOUND: \(key.stringValue)")
//                                print("❌ PATH: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
//                            case .dataCorrupted(let context):
//                                print("❌ DATA CORRUPTED")
//                                print("❌ PATH: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
//                            @unknown default:
//                                print("❌ UNKNOWN ERROR")
//                            }
//                        }
//                        // Fallback: treat entire answer as knowledge response
//                        responseType = .knowledge(answer: answerString, canonical: false, source_chunks: [])
//                    }
//                } else {
//                    print("❌ FAILED TO CONVERT STRING TO DATA")
//                }
// 
//                // Replace placeholder entry with actual response
//                let responseEntry = ChatEntry(query: query, responseType: responseType, duration: duration, timestamp: Date())
//                await MainActor.run {
//                    if let index = pendingEntryIndex, index < chatHistory.count {
//                        chatHistory[index] = responseEntry
//                    }
//                    isConnected = true
//                    statusMessage = "Done in \(String(format: "%.1f", duration))s"
//                    isLoading = false
//                    pendingEntryIndex = nil
//                }
//            } else {
//                let raw = String(data: data, encoding: .utf8) ?? "unknown error"
//                print("⚠️ HTTP ERROR \(code): \(raw.prefix(200))")
//                let responseEntry = ChatEntry(query: query, responseType: .knowledge(answer: "Server error \(code): \(raw)", canonical: false, source_chunks: []), duration: duration, timestamp: Date())
//                await MainActor.run {
//                    if let index = pendingEntryIndex, index < chatHistory.count {
//                        chatHistory[index] = responseEntry
//                    }
//                    statusMessage = "Server error \(code)"
//                    isLoading = false
//                    pendingEntryIndex = nil
//                }
//            }
//        } catch {
//            stopTimer()
//            print("🔥 REQUEST FAILED: \(error.localizedDescription)")
//            let errorEntry = ChatEntry(query: query, responseType: .knowledge(answer: "Request failed: \(error.localizedDescription)", canonical: false, source_chunks: []), duration: 0, timestamp: Date())
//            await MainActor.run {
//                if let index = pendingEntryIndex, index < chatHistory.count {
//                    chatHistory[index] = errorEntry
//                }
//                errorMessage = error.localizedDescription
//                statusMessage = "Request failed"
//                isLoading = false
//                pendingEntryIndex = nil
//            }
//        }
//    }
//}
//
import Foundation
import Combine

@MainActor
class RAGClient: ObservableObject {

    // MARK: - Published State

    @Published var chatHistory: [ChatEntry] = []
    @Published var historyRevision = 0
    @Published var isLoading = false
    @Published var statusMessage = "Ready"
    @Published var isConnected: Bool? = nil
    @Published var elapsedSeconds: Double = 0
    @Published var mode: String = "low"  // "fast" (Ollama) or "smart" (Groq)

    // MARK: - Config

    var baseURL = "http://127.0.0.1:8000"

    // MARK: - Private

    private var timerTask: Task<Void, Never>?
    private var startTime: Date?
    private var lastDuration: Double = 0

    /// Dedicated session so we don't share global URLSession state.
    private let urlSession: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 120
        cfg.timeoutIntervalForResource = 300
        return URLSession(configuration: cfg)
    }()

    // MARK: - Health Check

    func checkHealth() async {
        isLoading = true
        statusMessage = "Checking connection..."

        guard let url = URL(string: "\(baseURL)/health") else {
            isConnected = false
            statusMessage = "Invalid URL"
            isLoading = false
            return
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            isConnected = code == 200
            statusMessage = code == 200 ? "Connected" : "Server error \(code)"
        } catch {
            isConnected = false
            statusMessage = "Cannot reach server"
        }

        isLoading = false
    }

    // MARK: - Send Query

    func sendQuery(query: String) async {
        // Show user message immediately; keep a stable id so SwiftUI updates the same row.
        let entryId = UUID()
        let placeholder = ChatEntry(
            id: entryId,
            query: query,
            response: .knowledge(answer: "", canonical: false, sources: []),
            duration: 0,
            timestamp: Date()
        )
        let entryIndex = chatHistory.count
        publishHistory(chatHistory + [placeholder])

        isLoading = true
        statusMessage = "Retrieving..."
        startTimer()

        // Only isLoading is reset in defer; stopTimer is called explicitly
        // before replaceEntry so lastDuration is accurate.
        defer { isLoading = false }

        guard let url = URL(string: "\(baseURL)/query") else {
            stopTimer()
            replaceEntry(at: entryIndex, entryId: entryId, query: query, response: .error("Invalid URL"))
            return
        }

        do {
            let body = QueryRequest(query: query, kFetch: 20, kFinal: 5, mode: mode)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)

            print("[RAGClient] Sending query to \(url): \(query) [mode: \(mode)]")
            let (data, httpResponse) = try await urlSession.data(for: request)
            let code = (httpResponse as? HTTPURLResponse)?.statusCode ?? 0
            print("[RAGClient] HTTP \(code), body length=\(data.count)")

            guard code == 200 else {
                let raw = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("[RAGClient] Server error: \(raw)")
                stopTimer()
                replaceEntry(at: entryIndex, entryId: entryId, query: query, response: .error("Server error \(code): \(raw)"))
                statusMessage = "Server error \(code)"
                return
            }

            let decoded = try JSONDecoder().decode(QueryResponse.self, from: data)
            print("[RAGClient] Raw answer (\(decoded.answer.count) chars): \(decoded.answer.prefix(200))")

            let responseType = parseResponse(decoded.answer)
            stopTimer()                                  // set lastDuration before saving entry
            replaceEntry(at: entryIndex, entryId: entryId, query: query, response: responseType)
            isConnected = true
            statusMessage = "Done in \(String(format: "%.1f", lastDuration))s"

        } catch {
            print("[RAGClient] Request error: \(error)")
            stopTimer()
            replaceEntry(at: entryIndex, entryId: entryId, query: query, response: .error(error.localizedDescription))
            statusMessage = "Request failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Response Parsing

    private func parseResponse(_ raw: String) -> ResponseType {
        print("[RAGClient] parseResponse called with \(raw.count) chars")
        let cleaned = extractJSON(from: raw)
        print("[RAGClient] extractJSON produced: \(cleaned.prefix(200))")

        // If we couldn't extract any JSON, fall back to showing the raw text.
        guard !cleaned.isEmpty else {
            print("[RAGClient] cleaned is empty – raw was: \(raw.prefix(200))")
            return .error("The server returned an empty response.")
        }

        guard let data = cleaned.data(using: .utf8) else {
            return .knowledge(answer: raw.trimmingCharacters(in: .whitespacesAndNewlines),
                              canonical: false, sources: [])
        }

        guard let parsed = try? JSONDecoder().decode(ParsedResponse.self, from: data) else {
            // Not valid JSON – show the raw text as the answer.
            print("[RAGClient] JSON decode failed; showing raw text")
            let fallback = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return .knowledge(answer: fallback.isEmpty ? "(no answer)" : fallback,
                              canonical: false, sources: [])
        }

        print("[RAGClient] Decoded response_type=\(parsed.responseType)")

        switch parsed.responseType {
        case "scenario":
            if let scenarios = parsed.scenarios, !scenarios.isEmpty {
                print("[RAGClient] \(scenarios.count) scenarios returned")
                return .scenario(scenarios)
            }
            // Scenario JSON came back but with no scenarios; show the raw JSON.
            return .knowledge(answer: cleaned, canonical: false, sources: [])

        case "answer":
            let answer = parsed.answer?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            print("[RAGClient] answer field: '\(answer.prefix(100))'")
            if !answer.isEmpty {
                return .knowledge(
                    answer: answer,
                    canonical: parsed.canonical ?? false,
                    sources: parsed.sourceChunks ?? []
                )
            }
            // 'answer' field was empty – show full JSON so user sees something.
            return .knowledge(answer: cleaned, canonical: false, sources: [])

        default:
            print("[RAGClient] Unknown response_type: \(parsed.responseType)")
            return .outOfScope
        }
    }

    /// Strip markdown / thinking blocks and isolate the JSON object.
    /// Handles Qwen3 <think> blocks, markdown code fences, and leading/trailing noise.
    private func extractJSON(from text: String) -> String {
        var cleaned = text

        // Remove <think>…</think> blocks (Qwen3 may emit these even with think:false).
        // Use a regex so we strip the ENTIRE block, not just after the closing tag.
        if let regex = try? NSRegularExpression(pattern: "<think>[\\s\\S]*?</think>",
                                                options: []) {
            let range = NSRange(cleaned.startIndex..., in: cleaned)
            cleaned = regex.stringByReplacingMatches(in: cleaned, range: range,
                                                     withTemplate: "")
        }

        // Fallback: if a lone </think> remains (open tag was truncated), drop everything before it.
        let thinkClose = "</" + "think" + ">"
        if let thinkEnd = cleaned.range(of: thinkClose) {
            cleaned = String(cleaned[thinkEnd.upperBound...])
        }

        // Strip markdown code fences.
        cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        cleaned = cleaned.replacingOccurrences(of: "```", with: "")

        // Extract from first { to last }.
        guard let first = cleaned.firstIndex(of: "{"),
              let last  = cleaned.lastIndex(of: "}") else {
            return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return String(cleaned[first...last]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Helpers

    private func publishHistory(_ history: [ChatEntry]) {
        objectWillChange.send()
        chatHistory = history
        historyRevision += 1
    }

    private func replaceEntry(at index: Int, entryId: UUID, query: String, response: ResponseType) {
        guard index < chatHistory.count else { return }
        var updated = chatHistory
        updated[index] = ChatEntry(
            id: entryId,
            query: query,
            response: response,
            duration: lastDuration,
            timestamp: Date(),
            revision: updated[index].revision + 1
        )
        publishHistory(updated)
    }

    private func startTimer() {
        startTime = Date()
        elapsedSeconds = 0
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard let self, let start = startTime else { return }
                elapsedSeconds = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        if let start = startTime {
            lastDuration = Date().timeIntervalSince(start)
        }
        startTime = nil
    }
}

