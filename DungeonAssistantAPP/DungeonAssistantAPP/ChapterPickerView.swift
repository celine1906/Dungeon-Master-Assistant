//
//  ChapterPickerView.swift
//  DungeonAssistantAPP
//
//  Created by Nicholas Tristandi on 11/06/26.
//

import SwiftUI

struct ChapterPickerView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top bar with back button
                HStack(spacing: 10) {
                    Button(action: {
                        router.show(.start)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 14, design: .serif))
                        }
                        .foregroundStyle(Theme.Color.goldBright)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    HStack(spacing: 8) {
                        // Empty space to match MainView status circle
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 8, height: 8)

                        Text("Select Chapter")
                            .font(Theme.Font.heading)
                            .foregroundStyle(Theme.Color.heading)
                    }

                    Spacer()

                    // Invisible spacer for centering (matches MainView statusLabel width)
                    Text("00.0s")
                        .font(Theme.Font.meta)
                        .opacity(0)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Theme.Color.bar)

                Divider().background(Theme.Color.divider)

                // Chapter selection area
                ZStack {
                    // Background
                    Image("background")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .opacity(0.2)

                    HStack(spacing: 30) {
                        // Chapter 1
                        Button(action: {
                            router.show(.intro(chapter: Chapter.all[0]))
                        }) {
                            chapterCard(title: "Chapter 1", subtitle: "The joy Of Extradimensional Spaces", image: "Subject")
                        }
                        .buttonStyle(.plain)

                        // Chapter 2
                        Button(action: {
                            router.show(.intro(chapter: Chapter.all[1]))
                        }) {
                            chapterCard(title: "Chapter 2", subtitle: "Mazfroth's Mighty Digressions", image: "Subject 2")
                        }
                        .buttonStyle(.plain)

                        // Chapter 3
                        Button(action: {
                            router.show(.intro(chapter: Chapter.all[2]))
                        }) {
                            chapterCard(title: "Chapter 3", subtitle: "Book Of The Raven", image: "Subject 3")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.top, 50)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(Theme.Color.surface)
    }

    // Chapter card component
    @ViewBuilder
    private func chapterCard(title: String, subtitle: String, image: String) -> some View {
        ZStack {
            // Background image
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 200, height: 280)
                .clipped()

            // Dark overlay for text readability
            Rectangle()
                .fill(Color.black.opacity(0.5))

            // Text content
            VStack(spacing: 8) {
                Spacer()

                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.Color.goldBright)

                Text(subtitle)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(Theme.Color.userText)
                    .lineLimit(2)
                    .padding(.horizontal, 12)

                Spacer()
            }
            .padding(14)
        }
        .frame(width: 200, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.Color.border, lineWidth: 2)
        )
    }
}

#Preview {
    ChapterPickerView()
        .environmentObject(AppRouter())
}
