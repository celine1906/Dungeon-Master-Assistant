//
//  MainView.swift
//  D&D DM's Assistant
//
//  Created by Regina Celine Adiwinata on 09/06/26.
//

//import SwiftUI
//
//struct MainView: View {
//    @StateObject private var client = RAGClient()
//    @State private var queryText: String = ""
//    @State private var serverURL: String = "http://127.0.0.1:8000"
//    @Namespace private var bottomAnchor
// 
//    var body: some View {
//        VStack(spacing: 0) {
// 
//            // ── Top bar ──────────────────────────────────────────────
//            HStack(spacing: 10) {
//                Circle()
//                    .fill(statusColor)
//                    .frame(width: 8, height: 8)
//                Text("Dungeon Master Assistant")
//                    .font(.system(size: 14, weight: .semibold, design: .serif))
//                    .foregroundStyle(Color(red: 0.88, green: 0.80, blue: 0.62))
//                Spacer()
//                if client.isLoading {
//                    Text(String(format: "%.1fs", client.elapsedSeconds))
//                        .font(.system(size: 12, design: .monospaced))
//                        .foregroundStyle(Color(red: 0.60, green: 0.52, blue: 0.35))
//                    ProgressView().scaleEffect(0.65)
//                        .tint(Color(red: 0.72, green: 0.58, blue: 0.30))
//                } else {
//                    Text(client.statusMessage)
//                        .font(.system(size: 12, design: .monospaced))
//                        .foregroundStyle(Color(red: 0.50, green: 0.44, blue: 0.30))
//                }
//            }
//            .padding(.horizontal, 16).padding(.vertical, 10)
//            .background(Color(red: 0.13, green: 0.10, blue: 0.07))
// 
//            Divider().background(Color(red: 0.32, green: 0.26, blue: 0.16))
//                
//            ScrollViewReader { proxy in
//                ScrollView {
//                    LazyVStack(alignment: .leading, spacing: 24) {
//                        if client.chatHistory.isEmpty {
//                            VStack(spacing: 12) {
//                                Image(systemName: "books.vertical")
//                                    .font(.system(size: 36))
//                                    .foregroundStyle(Color(red: 0.35, green: 0.28, blue: 0.18))
//                                Text("Ask the Chronicler")
//                                    .font(.system(size: 18, weight: .semibold, design: .serif))
//                                    .foregroundStyle(Color(red: 0.50, green: 0.42, blue: 0.28))
//                                Text("Describe a situation your players are in\nand receive scenario options.")
//                                    .font(.system(size: 13, design: .serif))
//                                    .foregroundStyle(Color(red: 0.40, green: 0.34, blue: 0.22))
//                                    .multilineTextAlignment(.center)
//                            }
//                            .frame(maxWidth: .infinity)
//                            .padding(.top, 80)
//                        }
// 
//                        ForEach(client.chatHistory) { entry in
//                            ChatEntryView(entry: entry)
//                                .id(entry.id)
//                        }
// 
//                        // Loading placeholder
//                        if client.isLoading {
//                            LoadingEntryView(elapsedSeconds: client.elapsedSeconds)
//                                .padding(.top, 8)
//                        }
// 
//                        Color.clear.frame(height: 1).id("bottom")
//                    }
//                    .padding(16)
//                }
//                .onChange(of: client.chatHistory.count) { _ in
//                    withAnimation { proxy.scrollTo("bottom") }
//                }
//                .onChange(of: client.isLoading) { _ in
//                    withAnimation { proxy.scrollTo("bottom") }
//                }
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity) // Mengisi sisa ruang kosong di antara Top & Input bar
//            .background(
//                // Pasang background image di sini agar ukurannya nge-fit dengan pas
//                Image("background")
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .opacity(0.2)
//                    .allowsHitTesting(false)
//            )
//            .clipped()
//
// 
//            Divider().background(Color(red: 0.32, green: 0.26, blue: 0.16))
// 
//            // ── Input bar ────────────────────────────────────────────
//            HStack(alignment: .center, spacing: 10) {
//                TextEditor(text: $queryText)
//                    .font(.system(size: 13, design: .serif))
//                    .foregroundStyle(Color(red: 0.90, green: 0.84, blue: 0.68))
//                    .scrollContentBackground(.hidden)
//                    .background(Color.clear)
//                    .frame(minHeight: 36, maxHeight: 100)
//                    .padding(.horizontal, 10).padding(.vertical, 6)
//                    .background(Color(red: 0.18, green: 0.14, blue: 0.09))
//                    .clipShape(RoundedRectangle(cornerRadius: 8))
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 8)
//                            .stroke(Color(red: 0.38, green: 0.30, blue: 0.18), lineWidth: 1)
//                    )
//                    .onKeyPress(.return) {
//                        if !queryText.trimmingCharacters(in: .whitespaces).isEmpty && !client.isLoading {
//                            let q = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
//                            queryText = ""
//                            Task { await client.sendQuery(query: q) }
//                            return .handled
//                        }
//                        return .ignored
//                    }
// 
//                Button {
//                    let q = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
//                    guard !q.isEmpty else { return }
//                    queryText = ""
//                    Task { await client.sendQuery(query: q) }
//                } label: {
//                    Image(systemName: "paperplane.fill")
//                        .font(.system(size: 14))
//                        .foregroundStyle(
//                            client.isLoading || queryText.trimmingCharacters(in: .whitespaces).isEmpty
//                            ? Color(red: 0.35, green: 0.28, blue: 0.18)
//                            : Color(red: 0.82, green: 0.65, blue: 0.35)
//                        )
//                        .frame(width: 36, height: 36)
//                        .background(
//                            client.isLoading || queryText.trimmingCharacters(in: .whitespaces).isEmpty
//                            ? Color(red: 0.18, green: 0.14, blue: 0.09)
//                            : Color(red: 0.28, green: 0.20, blue: 0.10)
//                        )
//                        .clipShape(RoundedRectangle(cornerRadius: 8))
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 8)
//                                .stroke(Color(red: 0.38, green: 0.30, blue: 0.18), lineWidth: 1)
//                        )
//                }
//                .buttonStyle(.plain)
//                .disabled(client.isLoading || queryText.trimmingCharacters(in: .whitespaces).isEmpty)
//            }
//            .padding(.horizontal, 14).padding(.vertical, 10)
//            .background(Color(red: 0.13, green: 0.10, blue: 0.07))
//        }
//        .background(Color(red: 0.11, green: 0.09, blue: 0.06))
//        .frame(minWidth: 680, minHeight: 560)
//    }
// 
//    var statusColor: Color {
//        switch client.isConnected {
//        case true:  return Color(red: 0.35, green: 0.72, blue: 0.45)
//        case false: return Color(red: 0.78, green: 0.32, blue: 0.28)
//        case nil:   return Color(red: 0.40, green: 0.36, blue: 0.28)
//        }
//    }
//}
//
//#Preview{
//    MainView()
//}

//
//  MainView.swift
//  D&D DM's Assistant
//

import SwiftUI

struct MainView: View {
    let chapter: Chapter
    @StateObject private var client = RAGClient()
    @State private var queryText = ""
    @State private var inputResetID = 0
    @State private var showMansionMap = false
    @EnvironmentObject var router: AppRouter

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                topBar
                Divider().background(Theme.Color.divider)
                chatArea
                Divider().background(Theme.Color.divider)
                inputBar
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(Theme.Color.surface)
        .overlay {
            if showMansionMap {
                MansionMapOverlay(isPresented: $showMansionMap)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await client.checkHealth() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 10) {
            // Back button
            Button(action: {
                router.show(.chapterPicker)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Chapters")
                        .font(.system(size: 14, design: .serif))
                }
                .foregroundStyle(Theme.Color.goldBright)
            }
            .buttonStyle(.plain)

            Spacer()

            // Status indicator and title
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text("Candlelight DM")
                    .font(Theme.Font.heading)
                    .foregroundStyle(Theme.Color.heading)
            }

            Spacer()

            HStack(spacing: 8) {
                statusLabel

                // Mansion map button
                Button(action: {
                    showMansionMap = true
                }) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Color.gold)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Theme.Color.bar)
    }

    @ViewBuilder
    private var statusLabel: some View {
        if client.isLoading {
            HStack(spacing: 8) {
                Text(String(format: "%.1fs", client.elapsedSeconds))
                    .font(Theme.Font.meta)
                    .foregroundStyle(Theme.Color.gold)
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(Theme.Color.gold)
            }
        } else {
            Text(client.statusMessage)
                .font(Theme.Font.meta)
                .foregroundStyle(Theme.Color.muted)
        }
    }

    // MARK: - Chat Area

    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if client.chatHistory.isEmpty {
                        emptyState
                    }

                    ForEach(client.chatHistory) { entry in
                        ChatEntryView(entry: entry)
                            .id("\(entry.id.uuidString)-\(entry.revision)")
                    }

                    if client.isLoading {
                        LoadingEntryView(elapsedSeconds: client.elapsedSeconds)
                    }

                    // Invisible anchor at the very bottom
                    SwiftUI.Color.clear
                        .frame(height: 1)
                        .id("scroll_bottom")
                }
                .padding(20)
            }
            .onChange(of: client.historyRevision) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: client.chatHistory.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: client.isLoading) { _, _ in
                scrollToBottom(proxy)
            }
        }
        .background(
            Image("background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(0.15)
                .allowsHitTesting(false)
        )
        .clipped()
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            proxy.scrollTo("scroll_bottom", anchor: .bottom)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "books.vertical")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Color.muted.opacity(0.5))

            Text("Ask the Chronicler")
                .font(Theme.Font.title)
                .foregroundStyle(Theme.Color.muted)

            Text("Describe a player situation or ask about the adventure.")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.dim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 12) {
                TextEditor(text: $queryText)
                    .id(inputResetID)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.userText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 40, maxHeight: 120)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.Color.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardCorner))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Layout.cardCorner)
                            .stroke(Theme.Color.border, lineWidth: 1)
                    )
                    .onKeyPress(.return) {
                        guard canSend else { return .ignored }
                        handleSend()
                        return .handled
                    }

                Button(action: { handleSend() }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(canSend ? Theme.Color.goldBright : Theme.Color.muted)
                        .frame(width: 40, height: 40)
                        .background(canSend ? Theme.Color.userBubble : Theme.Color.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardCorner))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Layout.cardCorner)
                                .stroke(Theme.Color.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
            }

            // Mode toggle
            HStack(spacing: 8) {
                Image(systemName: client.mode == "fast" ? "hare.fill" : "tortoise.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Color.muted)

                Toggle(isOn: modeBinding) {
                    HStack(spacing: 4) {
                        Text(client.mode == "fast" ? "Low Mode" : "Smart Mode")
                            .font(.system(size: 11, design: .serif))
                        Text("(\(client.mode == "fast" ? "Ollama/Qwen3-8b" : "Groq/Llama3.3-70b-versatile"))")
                            .font(.system(size: 10, design: .monospaced))
                            .opacity(0.7)
                    }
                    .foregroundStyle(Theme.Color.muted)
                }
                .toggleStyle(.switch)
                .tint(Theme.Color.goldBright)
                .disabled(client.isLoading)

                Spacer()
            }
            .padding(.horizontal, 2)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Theme.Color.bar)
    }

    // MARK: - Helpers

    private var canSend: Bool {
        !queryText.trimmingCharacters(in: .whitespaces).isEmpty && !client.isLoading
    }

    private var modeBinding: Binding<Bool> {
        Binding(
            get: { self.client.mode == "smart" },
            set: { newValue in
                self.client.mode = newValue ? "smart" : "fast"
            }
        )
    }

    private func handleSend() {
        let trimmed = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !client.isLoading else { return }
        queryText = ""
        inputResetID += 1
        Task { @MainActor in
            await client.sendQuery(query: trimmed)
        }
    }

    private var statusColor: Color {
        switch client.isConnected {
        case true:  return Theme.Color.online
        case false: return Theme.Color.offline
        default:    return Theme.Color.unknown
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

#Preview {
    MainView(chapter: Chapter.all[0])
        .environmentObject(AppRouter())
}
