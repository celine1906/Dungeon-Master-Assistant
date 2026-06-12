//
//  ContentView.swift
//  D&D DM's Assistant
//
//  Created by Regina Celine Adiwinata on 09/06/26.
//

import SwiftUI

// Root view with navigation
struct ContentView: View {
    var body: some View {
        NavigationStack {
            StartScreen()
                .navigationTransition(.automatic)
        }
    }
}

#Preview {
    ContentView()
}
