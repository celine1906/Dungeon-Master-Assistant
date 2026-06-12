//
//  StartScreen.swift
//  DungeonAssistantAPP
//
//  Created by Nicholas Tristandi on 11/06/26.
//

import SwiftUI

  struct StartScreen: View {
      @StateObject private var serverManager = ServerManager()
      @EnvironmentObject var router: AppRouter

      var body: some View {
          ZStack {
              // Background
              Image("background")
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .opacity(0.2)
                  .ignoresSafeArea()

              // Start Button
              VStack {
                  Spacer()

                  Image("pngwing.com")
                      .resizable()
                      .frame(width: 600, height: 90)
                  
                  Text("Welcome, Dungeon Master.\n")
                      .font(.system(size: 37, weight: .semibold, design: .serif))
                      .foregroundStyle(Theme.Color.heading)
                      .padding(.bottom, 4)

                  Text("Running Candlekeep Mysteries is easier with a second pair of eyes.\nEvery room, every NPC, every clue, and every consequence inside Candlekeep Mysteries Spaces ready when you need it.")
                      .font(Theme.Font.body)
                      .foregroundStyle(Theme.Color.bodyText)
                      .multilineTextAlignment(.center)
                      .lineSpacing(4)
                      .padding(.bottom, 12)

                  Text("Hidden puzzles, the lurking dangers, the threads that tie it all together.\nYou don't have to memorize every page to run it well.")
                      .font(Theme.Font.body)
                      .foregroundStyle(Theme.Color.muted)
                      .multilineTextAlignment(.center)
                      .lineSpacing(4)
                      .padding(.bottom, 12)

                  Text("Ask about a room before your players walk in.\nAsk what happens when they make the unexpected choice.\nThe adventure answers back drawn from the text itself, nothing invented.")
                      .font(Theme.Font.body)
                      .foregroundStyle(Theme.Color.muted)
                      .multilineTextAlignment(.center)
                      .lineSpacing(4)
                      .padding(.bottom, 12)

                  Text("\n\nThe table is yours. The archives are open.")
                      .font(.system(size: 14, weight: .semibold, design: .serif))
                      .foregroundStyle(Theme.Color.muted)
                      .multilineTextAlignment(.center)

                  // Server status indicator
                  if !serverManager.isServerRunning {
                      HStack(spacing: 8) {
                          ProgressView()
                              .scaleEffect(0.6)
                          Text(serverManager.serverStatus)
                              .font(.system(size: 12, design: .serif))
                              .foregroundStyle(Theme.Color.muted)
                      }
                      .padding(.bottom, 8)
                  }

                  // Start button
                  Button(action: {
                      Task {
                          await serverManager.startServerIfNeeded()
                          // Navigate after server starts
                          try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 sec
                          router.show(.chapterPicker)
                      }
                  }) {
                      Text("Start Your Adventure")
                          .font(.system(size: 20, weight: .bold, design: .serif))
                          .foregroundStyle(Theme.Color.goldBright)
                          .frame(width: 275, height: 60)
                          .background(Theme.Color.userBubble)
                          .clipShape(RoundedRectangle(cornerRadius: 12))
                          .opacity(0.79)
                          .overlay(
                              RoundedRectangle(cornerRadius: 12)
                                  .stroke(Theme.Color.border, lineWidth: 2)
                          )
                  }
                  .buttonStyle(.plain)
                  .disabled(!serverManager.isServerRunning && serverManager.serverStatus == "Starting...")

                  Spacer()
              }
          }
          .background(Theme.Color.surface)
          .task {
              // Check server on screen appear
              await serverManager.checkServerHealth()
          }
      }
  }

#Preview {
    StartScreen()
        .environmentObject(AppRouter())
}
