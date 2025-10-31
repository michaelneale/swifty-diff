//
//  MainDiffView.swift
//  GitDiffViewer
//
//  Main diff viewing interface with sidebar and diff panes
//

import SwiftUI

struct MainDiffView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: ContentViewModel
    @State private var sidebarWidth: CGFloat = 300
    
    var body: some View {
        HSplitView {
            // Left sidebar with timeline and file list
            SidebarView()
                .frame(minWidth: 250, idealWidth: sidebarWidth, maxWidth: 400)
            
            // Main diff view
            DiffContentView()
                .frame(minWidth: 600)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: {
                    appState.selectedRepository = nil
                }) {
                    Label("Close Repository", systemImage: "arrow.left")
                }
                
                if let repo = appState.selectedRepository {
                    Text(repo.lastPathComponent)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    Task {
                        await appState.gitService?.loadCommitHistory()
                    }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .task {
            // Load initial data
            if let gitService = appState.gitService {
                await gitService.loadCommitHistory()
                await gitService.loadUnstagedChanges()
                
                // Set initial view to unstaged changes by default
                await MainActor.run {
                    viewModel.viewMode = .unstaged
                    viewModel.diffFiles = gitService.unstagedFiles
                    viewModel.selectedFile = gitService.unstagedFiles.first
                }
            }
        }
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            TimelineView()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Timeline View
struct TimelineView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: ContentViewModel
    @State private var sliderValue: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Unstaged changes button
            Button(action: {
                selectUnstagedChanges()
            }) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.orange)
                    Text("Unstaged Changes")
                        .fontWeight(.medium)
                    Spacer()
                    if case .unstaged = viewModel.viewMode {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(
                    viewModel.viewMode == .unstaged ? Color.blue.opacity(0.1) : Color.clear
                )
            }
            .buttonStyle(.plain)
            
            Divider()
            
            // Timeline Slider
            if let gitService = appState.gitService, !gitService.commits.isEmpty {
                VStack(spacing: 4) {
                    HStack {
                        Text("Timeline")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Slider(
                        value: $sliderValue,
                        in: 0...Double(max(0, gitService.commits.count - 1)),
                        step: 1
                    ) { editing in
                        if !editing {
                            // When user releases slider, select that commit
                            let index = Int(sliderValue)
                            if index < gitService.commits.count {
                                selectCommit(gitService.commits[index])
                            }
                        }
                    }
                    .labelsHidden()
                    .accentColor(Color(hex: "667eea"))
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Divider()
            }
            
            // Commit list
            ScrollView {
                LazyVStack(spacing: 0) {
                    if let gitService = appState.gitService {
                        ForEach(gitService.commits) { commit in
                            CommitRowView(commit: commit)
                                .onTapGesture {
                                    selectCommit(commit)
                                    // Update slider to match selected commit
                                    if let index = gitService.commits.firstIndex(where: { $0.id == commit.id }) {
                                        sliderValue = Double(index)
                                    }
                                }
                        }
                    }
                }
            }
        }
        .onChange(of: appState.gitService?.commits) { commits in
            // Reset slider when commits change
            sliderValue = 0
        }
        .onAppear {
            // Initialize slider to first commit
            if let gitService = appState.gitService, !gitService.commits.isEmpty {
                sliderValue = 0
            }
        }
    }
    
    private func selectUnstagedChanges() {
        Task {
            await appState.gitService?.loadUnstagedChanges()
            await MainActor.run {
                viewModel.viewMode = .unstaged
                viewModel.diffFiles = appState.gitService?.unstagedFiles ?? []
                viewModel.selectedFile = viewModel.diffFiles.first
            }
        }
    }
    
    private func selectCommit(_ commit: CommitInfo) {
        Task {
            viewModel.isLoadingDiff = true
            let files = await appState.gitService?.loadDiffForCommit(commit) ?? []
            await MainActor.run {
                viewModel.viewMode = .commit(commit)
                viewModel.selectedCommit = commit
                viewModel.diffFiles = files
                viewModel.selectedFile = files.first
                viewModel.isLoadingDiff = false
            }
        }
    }
}

// MARK: - Commit Row View
struct CommitRowView: View {
    let commit: CommitInfo
    @EnvironmentObject var viewModel: ContentViewModel
    
    var isSelected: Bool {
        if case .commit(let selected) = viewModel.viewMode {
            return selected.id == commit.id
        }
        return false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(commit.shortHash)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(commit.displayDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(commit.message)
                .font(.system(size: 13))
                .lineLimit(2)
                .foregroundColor(.primary)
            
            Text(commit.author)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .overlay(
            Rectangle()
                .frame(width: 3)
                .foregroundColor(isSelected ? .blue : .clear),
            alignment: .leading
        )
    }
}

// MARK: - File List View
struct FileListView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(viewModel.diffFiles) { file in
                    FileRowView(file: file)
                        .onTapGesture {
                            viewModel.selectedFile = file
                        }
                }
            }
        }
    }
}

// MARK: - File Row View
struct FileRowView: View {
    let file: DiffFile
    @EnvironmentObject var viewModel: ContentViewModel
    
    var isSelected: Bool {
        viewModel.selectedFile?.id == file.id
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: file.status.icon)
                .foregroundColor(file.status.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.fileName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                if file.path != file.fileName {
                    Text(file.path)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Stats
            HStack(spacing: 4) {
                let stats = calculateStats(file)
                if stats.additions > 0 {
                    Text("+\(stats.additions)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.green)
                }
                if stats.deletions > 0 {
                    Text("-\(stats.deletions)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .overlay(
            Rectangle()
                .frame(width: 3)
                .foregroundColor(isSelected ? .blue : .clear),
            alignment: .leading
        )
    }
    
    private func calculateStats(_ file: DiffFile) -> (additions: Int, deletions: Int) {
        var additions = 0
        var deletions = 0
        
        for hunk in file.hunks {
            for line in hunk.lines {
                switch line.type {
                case .addition:
                    additions += 1
                case .deletion:
                    deletions += 1
                default:
                    break
                }
            }
        }
        
        return (additions, deletions)
    }
}
