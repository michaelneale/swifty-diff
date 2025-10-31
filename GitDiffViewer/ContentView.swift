//
//  ContentView.swift
//  GitDiffViewer
//
//  Main view of the application
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        Group {
            if appState.selectedRepository == nil {
                WelcomeView()
            } else {
                MainDiffView()
                    .environmentObject(viewModel)
            }
        }
        .fileImporter(isPresented: $appState.showDirectoryPicker, allowedContentTypes: [.folder]) { result in
            handleDirectorySelection(result)
        }
    }
    
    private func handleDirectorySelection(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            appState.openRepository(at: url)
        case .failure(let error):
            print("Error selecting directory: \(error.localizedDescription)")
        }
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Git Diff Viewer")
                .font(.system(size: 48, weight: .bold))
            
            Text("Beautiful side-by-side diff visualization")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Button(action: {
                appState.showDirectoryPicker = true
            }) {
                HStack {
                    Image(systemName: "folder.badge.plus")
                    Text("Open Repository")
                }
                .font(.title3)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .shadow(color: Color(hex: "667eea").opacity(0.3), radius: 10, x: 0, y: 5)
            
            Spacer()
            
            VStack(spacing: 10) {
                Text("Quick Start")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    FeatureItem(icon: "clock.arrow.circlepath", text: "View History")
                    FeatureItem(icon: "doc.text.magnifyingglass", text: "Compare Changes")
                    FeatureItem(icon: "slider.horizontal.3", text: "Timeline Slider")
                }
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "667eea"))
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 120)
    }
}

// MARK: - Content View Model
class ContentViewModel: ObservableObject {
    @Published var selectedCommit: CommitInfo?
    @Published var viewMode: ViewMode = .unstaged
    @Published var diffFiles: [DiffFile] = []
    @Published var isLoadingDiff = false
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
