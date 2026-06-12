//
//  RootView.swift
//  DungeonAssistantAPP
//
//  Created by Nicholas Tristandi on 12/06/26.
//


import SwiftUI

struct RootView: View {
   @StateObject private var router = AppRouter()

   var body: some View {
       Group {
           switch router.current {
           case .start:
               StartScreen()
           case .chapterPicker:
               ChapterPickerView()
           case .intro(let chapter):
               ChapterIntroView(chapter: chapter)   // <- NEW
           case .chat(let chapter):
               MainView(chapter: chapter)
           }
       }
       .environmentObject(router)
       .transition(.opacity)
       .animation(.easeInOut(duration: 0.4), value: UUID())
   }
}
