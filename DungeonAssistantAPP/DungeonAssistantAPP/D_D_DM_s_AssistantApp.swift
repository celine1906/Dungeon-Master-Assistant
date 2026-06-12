//
//  D_D_DM_s_AssistantApp.swift
//  D&D DM's Assistant
//
//  Created by Regina Celine Adiwinata on 09/06/26.
//

import SwiftUI


// Entry point
@main
struct D_D_DM_s_AssistantApp: App {
    @StateObject private var serverManager = ServerManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(serverManager)
        }
    }
}
