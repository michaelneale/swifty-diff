//
//  GitDiffViewerApp.swift
//  GitDiffViewer
//
//  Created by G3 on 2024
//

import SwiftUI

@main
struct GitDiffViewerApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1200, minHeight: 800)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Repository...") {
                    appState.showDirectoryPicker = true
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var selectedRepository: URL?
    @Published var showDirectoryPicker = false
    @Published var gitService: GitService?
    
    func openRepository(at url: URL) {
        selectedRepository = url
        gitService = GitService(repositoryPath: url)
    }
}
