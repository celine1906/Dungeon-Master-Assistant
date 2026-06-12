//
//  ServerManager.swift
//  DungeonAssistantAPP
//
//  Created by Nicholas Tristandi on 12/06/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ServerManager: ObservableObject {
    @Published var isServerRunning = false
    @Published var serverStatus: String = "Not Started"

    private var serverProcess: Process?
    private let projectPath: String

    init() {
        // Calculate project path relative to app bundle
        let bundlePath = Bundle.main.bundlePath
        // bundlePath is like: /Users/.../DungeonAssistantAPP/Build/Products/Debug/DungeonAssistantAPP.app

        // Navigate up to find the project root
        // Go up from .app -> Debug -> Products -> Build -> DungeonAssistantAPP -> parent (project root)
        var path = URL(fileURLWithPath: bundlePath)

        // During development, app is in DerivedData, so we need different logic
        // Check if we're in development or production
        if bundlePath.contains("DerivedData") {
            // Development: find "Challenge 1 NLP" folder
            while !path.lastPathComponent.contains("Challenge 1 NLP") && path.path != "/" {
                path.deleteLastPathComponent()
            }
            self.projectPath = path.path
        } else {
            // Production: assume script is next to .app (or use UserDefaults)
            path.deleteLastPathComponent()
            self.projectPath = path.path
        }

        print("[ServerManager] Project path: \(projectPath)")
    }

    // MARK: - Start Server

    func startServer() {
        guard serverProcess == nil else {
            print("[ServerManager] Server already running")
            return
        }

        serverStatus = "Starting..."

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")

        // Commands to execute
        let commands = """
        cd '\(projectPath)' && \
        source nlpvenv/bin/activate && \
        uvicorn main:app --host 127.0.0.1 --port 8000 --reload > /dev/null 2>&1 &
        """

        process.arguments = ["-c", commands]

        do {
            try process.run()
            serverProcess = process
            serverStatus = "Running"

            // Wait a moment then check health
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await checkServerHealth()
            }

            print("[ServerManager] Server started successfully")
        } catch {
            print("[ServerManager] Failed to start server: \(error)")
            serverStatus = "Failed to start"
        }
    }

    // MARK: - Stop Server

    func stopServer() {
        // Kill any process on port 8000
        let killProcess = Process()
        killProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
        killProcess.arguments = ["-c", "lsof -ti:8000 | xargs kill -9 2>/dev/null || true"]

        do {
            try killProcess.run()
            killProcess.waitUntilExit()
            serverProcess = nil
            isServerRunning = false
            serverStatus = "Stopped"
            print("[ServerManager] Server stopped")
        } catch {
            print("[ServerManager] Failed to stop server: \(error)")
        }
    }

    // MARK: - Health Check

    func checkServerHealth() async {
        guard let url = URL(string: "http://127.0.0.1:8000/health") else {
            isServerRunning = false
            return
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            isServerRunning = (statusCode == 200)
            serverStatus = isServerRunning ? "Running" : "Not responding"

            print("[ServerManager] Health check: \(isServerRunning ? "✅ OK" : "❌ Failed")")
        } catch {
            isServerRunning = false
            serverStatus = "Not running"
            print("[ServerManager] Health check failed: \(error)")
        }
    }

    // MARK: - Auto-start on App Launch

    func startServerIfNeeded() async {
        await checkServerHealth()

        if !isServerRunning {
            print("[ServerManager] Server not running, starting...")
            startServer()
        } else {
            print("[ServerManager] Server already running")
        }
    }
}
