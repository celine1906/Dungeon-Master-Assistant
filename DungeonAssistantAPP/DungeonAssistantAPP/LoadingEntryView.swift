//
//  LoadingEntryView.swift
//  D&D DM's Assistant
//
//  Created by Regina Celine Adiwinata on 09/06/26.


//
//import SwiftUI
//
//struct LoadingEntryView: View {
//    @State private var isAnimating = false
//    let elapsedSeconds: Double
//    
//    var body: some View {
//        GeometryReader { proxy in
//            HStack(spacing: 0) {
//                VStack(alignment: .leading, spacing: 12) {
//                    // Animated dots
//                    HStack(spacing: 4) {
//                        ForEach(0..<3, id: \.self) { index in
//                            Circle()
//                                .fill(Color(red: 0.72, green: 0.58, blue: 0.30))
//                                .frame(width: 6, height: 6)
//                                .offset(y: isAnimating && (index % 3 == 0) ? -4 : 0)
//                                .animation(
//                                    Animation.easeInOut(duration: 0.6)
//                                        .repeatForever()
//                                        .delay(Double(index) * 0.1),
//                                    value: isAnimating
//                                )
//                        }
//                        Text("The Chronicler consults the archives...")
//                            .font(.system(size: 12, design: .serif))
//                            .foregroundStyle(Color(red: 0.50, green: 0.42, blue: 0.28))
//                    }
//                    
//                    // Timer
//                    Text("Elapsed: \(String(format: "%.1f", elapsedSeconds))s")
//                        .font(.system(size: 10, design: .monospaced))
//                        .foregroundStyle(Color(red: 0.45, green: 0.40, blue: 0.30))
//                }
//                .padding(12)
//                .background(Color(red: 0.14, green: 0.11, blue: 0.08))
//                .clipShape(RoundedRectangle(cornerRadius: 8))
//                .frame(maxWidth: proxy.size.width * 0.5, alignment: .leading)
//                
//                Spacer(minLength: 0)
//            }
//            .frame(maxWidth: .infinity)
//        }
//        .frame(maxWidth: .infinity)
//        .onAppear {
//            isAnimating = true
//        }
//    }
//}
//
//#Preview {
//    LoadingEntryView(elapsedSeconds: 2.5)
//}

import SwiftUI

struct LoadingEntryView: View {
    let elapsedSeconds: Double
    @State private var isAnimating = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                // Animated dots + flavor text
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Theme.Color.gold)
                            .frame(width: 6, height: 6)
                            .offset(y: isAnimating ? -4 : 0)
                            .animation(
                                .easeInOut(duration: 0.5)
                                    .repeatForever()
                                    .delay(Double(index) * 0.15),
                                value: isAnimating
                            )
                    }
                    Text("The Chronicler consults the archives...")
                        .font(Theme.Font.bodySmall)
                        .foregroundStyle(Theme.Color.muted)
                }

                Text("Elapsed: \(String(format: "%.1f", elapsedSeconds))s")
                    .font(Theme.Font.meta)
                    .foregroundStyle(Theme.Color.dim)
            }
            .padding(14)
            .background(Theme.Color.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardCorner))
            .frame(maxWidth: 400, alignment: .leading)

            Spacer(minLength: 40)
        }
        .onAppear { isAnimating = true }
    }
}

#Preview {
    LoadingEntryView(elapsedSeconds: 12.3)
        .padding()
        .background(Theme.Color.surface)
}
