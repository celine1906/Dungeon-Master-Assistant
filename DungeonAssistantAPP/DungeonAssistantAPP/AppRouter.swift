//
//  AppRouter.swift
//  DungeonAssistantAPP
//
//  Created by Nicholas Tristandi on 12/06/26.
//


import SwiftUI
import Combine
 
enum AppScreen {
    case start
    case chapterPicker
    case intro(chapter: Chapter)   // <- NEW: DM read-aloud before chat
    case chat(chapter: Chapter)
}
 
@MainActor
class AppRouter: ObservableObject {
    @Published var current: AppScreen = .start
 
    func show(_ screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.4)) {
            current = screen
        }
    }
}
