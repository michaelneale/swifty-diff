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
                .onAppear {
                    handleCommandLineArguments()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1400, height: 900)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About GitDiffViewer") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.applicationName: "GitDiffViewer",
                            NSApplication.AboutPanelOptionKey.applicationVersion: "1.0",
                            NSApplication.AboutPanelOptionKey.version: "1.0.0"
                        ]
                    )
                }
            }
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
    
    private func handleCommandLineArguments() {
        let args = CommandLine.arguments
        if args.count > 1 {
            let path = args[1]
            let url = URL(fileURLWithPath: path)
            // Check if it's a valid directory
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
                appState.openRepository(at: url)
            } else {
                print("Error: '\(path)' is not a valid directory")
                print("Usage: GitDiffViewer [directory-path]")
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
        print("Opened repository at: \(url.path)")
    }
}
