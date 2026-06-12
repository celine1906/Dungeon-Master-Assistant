import Testing
import Foundation
@testable import DungeonAssistantAPP

struct DungeonAssistantAPPTests {

    @Test func testServerQueryAndDecode() async throws {
        let client = await RAGClient()
        print("Starting testServerQueryAndDecode...")
        
        // Let's test health check
        await client.checkHealth()
        let isConnected = await client.isConnected
        print("Connected state: \(String(describing: isConnected))")
        
        // Let's test sending a query
        await client.sendQuery(query: "Who is Matreous?")
        let history = await client.chatHistory
        print("Chat history count: \(history.count)")
        
        if let last = history.last {
            print("Last entry response: \(last.response)")
            switch last.response {
            case .error(let msg):
                #expect(Bool(false), "Failed with error: \(msg)")
            case .knowledge(let answer, let canonical, let sources):
                print("Knowledge answer: \(answer), canonical: \(canonical), sources: \(sources)")
                #expect(!answer.isEmpty)
            case .scenario(let scenarios):
                print("Scenarios count: \(scenarios.count)")
                #expect(!scenarios.isEmpty)
            case .outOfScope:
                print("Out of scope")
            }
        } else {
            #expect(Bool(false), "History is empty")
        }
    }

}

