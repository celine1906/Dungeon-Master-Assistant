//
//  ChapterIntroView.swift
//  DungeonAssistantAPP
//
//  Created by Nicholas Tristandi on 12/06/26.
//

import Foundation
import SwiftUI

import SwiftUI

// MARK: - Data

struct IntroSection: Identifiable {
    let id = UUID()
    let heading: String
    let body: String
}

private let joySections: [IntroSection] = [
    IntroSection(
        heading: "Finding the Book",
        body: "Your hometown is on the brink of total collapse. This past year, a devastating blight has taken hold of the landcrops have rotted in the dirt, the livestock stand in the fields like skeletal stick figures, and the rains have completely dried up. Desperate for answers, a local mage discovered that this isn't natural weather; a malicious curse has been levied against your home. The mage identified a renowned sage named Matreous as the only one who might know how to break it, and after some quick digging, tracked him to the great library-fortress of Candlekeep. You have been sent there on an urgent mission to find him and bring back a cure before it's too late. Alternatively, you might have traveled to Candlekeep on your own academic pursuits, spending weeks buried in dusty archives researching advanced magical theory specifically, the creation of permanent spells or the mechanics of demiplanes and pocket dimensions. Whichever path brought you here, your investigation ultimately converges on a single, fascinating tome titled The Joy of Extradimensional Spaces. But as you finally lay hands on the book, you uncover a pair of deep mysteries. First, Matreous has completely vanished, and the clues suggest he opened a portal and stepped right into the pages of this text. Second, and perhaps more alarming, is the realization that while opening the portal to go in after him is one thing, figuring out how to escape an extradimensional space once you are trapped inside is an entirely different problem."
    ),
    IntroSection(
        heading: "The Book",
        body: "The Joy of Extradimensional Spaces is a remarkably heavy tome, bound in thick, ornately tooled leather and decorated with intricate gold filigree. Emblazoned across the cover is the imposing bust of a spellcaster, whom anyone well-versed in history would recognize as the legendary archmage Mordenkainen. It is an artifact of pure arcane study, radiating both immense weight and a strange, subtle hum of hidden power."
    ),
    IntroSection(
        heading: "Opening the Portal",
        body: "Inside Matreous’s deserted study, the book lies open to a page filled with Fistandia's chaotic, handwritten notes. Deciphering her complex shorthand reveals the activation command word: 'scepter.' When spoken aloud, the air fractures as shimmering, translucent doors materialize in the center of the room. They begin to slowly fade, making it clear that you have only a few fleeting minutes to step through before the doorway vanishes entirely."
    ),
    IntroSection(
        heading: "Fistandia's Mansion",
        body: "You cross the threshold into a luxurious, airy manor built from solid stone blocks and rich hardwood floors, all sustained permanently by Fistandia’s own powerful enchantments. Warm oil lamps illuminate ironbound oak doors and deep brown furniture, creating a deceptively cozy atmosphere. Yet, just twenty feet outside the windows, a swirling indigo miasma looms in the void—a hostile fog that drains the life and energy from any creature foolish enough to step into it"
    ),
    IntroSection(
        heading: "The Puzzle Books",
        body: "To escape this magnificent pocket dimension, you must uncover a second command word that Fistandia cleverly hid away as a game. Scattered across the mansion are seven specific puzzle books, each bearing the same golden image of Mordenkainen and a single gilded letter stamped upon its spine. Only by scouring the rooms, finding every volume, and arranging them to spell the word will the exit portal finally open for you."
    )
]

// MARK: - View

struct ChapterIntroView: View {
    let chapter: Chapter
    @EnvironmentObject var router: AppRouter

    // Index of the last section that is currently visible (0-based).
    // -1 means nothing is visible yet.
    @State private var visibleUpTo: Int = -1

    // Controls whether the "Begin Session" CTA is shown at the end.
    @State private var showCTA: Bool = false

    // Controls whether the mansion map overlay is shown
    @State private var showMansionMap: Bool = false

    // Delay between each section appearing, in seconds.
    private let sectionDelay: Double = 2.8
    // Fade duration for each section.
    private let fadeDuration: Double = 1.2

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            // Background
            Color(red: 0.07, green: 0.07, blue: 0.10)
                .ignoresSafeArea()

            // Scrollable content
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 48) {

                        // Chapter eyebrow
                        Text(chapter.sourcebook.uppercased())
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(Color(red: 0.65, green: 0.50, blue: 0.30))
                            .opacity(visibleUpTo >= 0 ? 1 : 0)
                            .animation(.easeIn(duration: fadeDuration), value: visibleUpTo)

                        // Chapter title
                        Text(chapter.title)
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(Color(red: 0.95, green: 0.90, blue: 0.78))
                            .opacity(visibleUpTo >= 0 ? 1 : 0)
                            .animation(.easeIn(duration: fadeDuration), value: visibleUpTo)

                        // DM label
                        Text("The Dungeon Master speaks...")
                            .font(.system(size: 13, weight: .regular, design: .serif))
                            .italic()
                            .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.35))
                            .opacity(visibleUpTo >= 0 ? 1 : 0)
                            .animation(.easeIn(duration: fadeDuration), value: visibleUpTo)

                        Divider()
                            .background(Color(red: 0.30, green: 0.22, blue: 0.14))
                            .opacity(visibleUpTo >= 0 ? 1 : 0)
                            .animation(.easeIn(duration: fadeDuration), value: visibleUpTo)

                        // Sections
                        ForEach(Array(joySections.enumerated()), id: \.element.id) { index, section in
                            SectionBlock(
                                section: section,
                                showMapButton: section.heading == "Fistandia's Mansion",
                                onMapButtonTap: { showMansionMap = true }
                            )
                            .opacity(visibleUpTo >= index ? 1 : 0)
                            .animation(
                                .easeIn(duration: fadeDuration),
                                value: visibleUpTo
                            )
                            .id("section_\(index)")
                        }

                        // Begin Session CTA
                        if showCTA {
                            Button(action: navigateToChat) {
                                HStack(spacing: 10) {
                                    Text("Begin Session")
                                        .font(.system(size: 16, weight: .semibold, design: .serif))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(Color(red: 0.07, green: 0.07, blue: 0.10))
                                .padding(.horizontal, 28)
                                .padding(.vertical, 14)
                                .background(Color(red: 0.78, green: 0.60, blue: 0.30))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 52)
                    .padding(.bottom, 40)
                }
                .onChange(of: visibleUpTo) { newIndex in
                    // Auto-scroll so the newly revealed section is visible
                    if newIndex >= 0 {
                        withAnimation {
                            proxy.scrollTo("section_\(newIndex)", anchor: .bottom)
                        }
                    }
                }
            }

            // Skip / bottom-right — always visible
            skipButton
                .padding(.trailing, 24)
                .padding(.bottom, 24)
        }
        .overlay {
            if showMansionMap {
                MansionMapOverlay(isPresented: $showMansionMap)
            }
        }
        .onAppear(perform: startSequence)
    }

    // MARK: - Skip Button

    @ViewBuilder
    private var skipButton: some View {
        Button(action: navigateToChat) {
            Text("Skip")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .tracking(1)
                .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.35))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(red: 0.30, green: 0.22, blue: 0.14), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sequence Logic

    private func startSequence() {
        // Reveal the header (eyebrow + title + divider) first
        withAnimation(.easeIn(duration: fadeDuration)) {
            visibleUpTo = -1
        }

        // Then reveal each section with a cumulative delay
        for i in 0..<joySections.count {
            // +1.0s base offset so the header settles before sections begin
            let delay = 1.0 + (Double(i) * sectionDelay)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: fadeDuration)) {
                    visibleUpTo = i
                }
            }
        }

        // Show CTA after all sections have appeared
        let ctaDelay = 1.0 + (Double(joySections.count) * sectionDelay) + fadeDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + ctaDelay) {
            withAnimation(.easeIn(duration: 0.8)) {
                showCTA = true
            }
        }
    }

    // MARK: - Navigation

    private func navigateToChat() {
        router.show(.chat(chapter: chapter))
    }
}

// MARK: - Section Block

private struct SectionBlock: View {
    let section: IntroSection
    let showMapButton: Bool
    let onMapButtonTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section heading with decorative rule
            HStack(alignment: .center, spacing: 12) {
                Text(section.heading.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(2.5)
                    .foregroundColor(Color(red: 0.65, green: 0.50, blue: 0.30))

                Rectangle()
                    .fill(Color(red: 0.30, green: 0.22, blue: 0.14))
                    .frame(height: 1)

                if showMapButton {
                    Button(action: onMapButtonTap) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.78, green: 0.60, blue: 0.30))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Body text — large, readable, italic serif for DM voice
            Text(section.body)
                .font(.system(size: 20, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(Color(red: 0.88, green: 0.83, blue: 0.72))
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Mansion Map Overlay

private struct MansionMapOverlay: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPresented = false
                    }
                }

            // Map image with close button
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 0.88, green: 0.83, blue: 0.72))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }

                // Mansion map image
                Image("Fistandia's Mansion_labeled")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 700, maxHeight: 600)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.10, green: 0.08, blue: 0.06))
                    .shadow(color: .black.opacity(0.8), radius: 30, x: 0, y: 10)
            )
            .padding(40)
        }
        .transition(.opacity)
    }
}

// MARK: - Preview

#Preview {
    ChapterIntroView(chapter: Chapter.all[0])
        .environmentObject(AppRouter())
        .frame(width: 760, height: 860)
}
