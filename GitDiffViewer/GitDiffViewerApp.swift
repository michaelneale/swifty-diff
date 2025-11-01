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
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    handleCommandLineArguments()
                    appDelegate.appState = appState
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

// MARK: - App Delegate for Menu Bar
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var appState: AppState?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Normal app with dock icon
        NSApplication.shared.setActivationPolicy(.regular)
    }
    
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            // Try to use SF Symbol, fallback to text if not available
            if let image = NSImage(systemSymbolName: "arrow.triangle.branch", accessibilityDescription: "GitDiffViewer") {
                button.image = image
            } else {
                button.title = "⎇"  // Git branch symbol
            }
            button.toolTip = "GitDiffViewer - Click to open menu"
        }
        
        updateMenu()
    }
    
    func updateMenu() {
        // Create menu
        let menu = NSMenu()
        menu.delegate = self
        
        menu.addItem(NSMenuItem(title: "GitDiffViewer", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Open Repository...", action: #selector(openRepository), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        
        if let repoItem = appState?.selectedRepository {
            menu.addItem(NSMenuItem(title: "Current: \(repoItem.lastPathComponent)", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
        }
        
        menu.addItem(NSMenuItem(title: "Show Window", action: #selector(showWindow), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About GitDiffViewer", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit GitDiffViewer", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func openRepository() {
        appState?.showDirectoryPicker = true
        showWindow()
    }
    
    @objc func showWindow() {
        // Make sure we're in regular mode when showing window
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Find and show the main window
        if let window = NSApplication.shared.windows.first(where: { $0.isVisible == false || $0.isMiniaturized }) {
            window.makeKeyAndOrderFront(nil)
            window.deminiaturize(nil)
        } else if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc func showAbout() {
        showWindow()
        NSApplication.shared.orderFrontStandardAboutPanel(
            options: [
                NSApplication.AboutPanelOptionKey.applicationName: "GitDiffViewer",
                NSApplication.AboutPanelOptionKey.applicationVersion: "1.0",
                NSApplication.AboutPanelOptionKey.version: "1.0.0"
            ]
        )
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showWindow()
        }
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Quit when last window closes like a normal app
        return true
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Update menu items when menu is about to open
        updateMenu()
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
