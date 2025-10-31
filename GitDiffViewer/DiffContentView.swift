//
//  DiffContentView.swift
//  GitDiffViewer
//
//  Side-by-side diff view
//

import SwiftUI

struct DiffContentView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    
    var body: some View {
        if viewModel.isLoadingDiff {
            ProgressView("Loading diff...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !viewModel.diffFiles.isEmpty {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    ForEach(Array(viewModel.diffFiles.enumerated()), id: \.element.id) { index, file in
                        VStack(spacing: 0) {
                            // File header - big and obvious
                            HStack(spacing: 12) {
                                Image(systemName: file.status.icon)
                                    .foregroundColor(file.status.color)
                                    .font(.title2)
                                
                                Text(file.displayPath)
                                    .font(.system(size: 18, weight: .bold))
                                
                                Spacer()
                                
                                let stats = calculateStats(file)
                                if stats.additions > 0 {
                                    Text("+\(stats.additions)")
                                        .font(.system(size: 14, design: .monospaced))
                                        .foregroundColor(.green)
                                }
                                if stats.deletions > 0 {
                                    Text("-\(stats.deletions)")
                                        .font(.system(size: 14, design: .monospaced))
                                        .foregroundColor(.red)
                                }
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            
                            // The actual diff
                            SimpleDiffView(file: file)
                            
                            // Separator between files
                            if index < viewModel.diffFiles.count - 1 {
                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(height: 3)
                                    .padding(.vertical, 20)
                            }
                        }
                    }
                }
            }
        } else {
            EmptyDiffView()
        }
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

// MARK: - Simple Diff View (side by side)
struct SimpleDiffView: View {
    let file: DiffFile
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left side - BEFORE
            VStack(spacing: 0) {
                Text("BEFORE")
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(4)
                    .background(Color.red.opacity(0.7))
                
                ForEach(file.hunks) { hunk in
                    ForEach(hunk.lines) { line in
                        if line.type != .addition {
                            DiffLineView(line: line, side: .left)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            Rectangle()
                .fill(Color.gray)
                .frame(width: 2)
            
            // Right side - AFTER
            VStack(spacing: 0) {
                Text("AFTER")
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(4)
                    .background(Color.green.opacity(0.7))
                
                ForEach(file.hunks) { hunk in
                    ForEach(hunk.lines) { line in
                        if line.type != .deletion {
                            DiffLineView(line: line, side: .right)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Diff Header
struct DiffHeaderView: View {
    let file: DiffFile
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: file.status.icon)
                .foregroundColor(file.status.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.displayPath)
                    .font(.system(size: 15, weight: .semibold))
                
                HStack(spacing: 12) {
                    Label(file.status.rawValue, systemImage: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    let stats = calculateStats(file)
                    if stats.additions > 0 || stats.deletions > 0 {
                        HStack(spacing: 8) {
                            if stats.additions > 0 {
                                Text("+\(stats.additions)")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                            if stats.deletions > 0 {
                                Text("-\(stats.deletions)")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
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

// MARK: - Side by Side Diff View
struct SideBySideDiffView: View {
    let file: DiffFile
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView([.vertical]) {
                HStack(alignment: .top, spacing: 1) {
                    // Left pane (before)
                    DiffPaneContentView(
                        file: file,
                        side: .left,
                        width: geometry.size.width / 2 - 0.5
                    )
                    
                    Divider()
                    
                    // Right pane (after)
                    DiffPaneContentView(
                        file: file,
                        side: .right,
                        width: geometry.size.width / 2 - 0.5
                    )
                }
            }
        }
    }
}

// MARK: - Shared DiffSide enum
enum DiffSide {
    case left, right
}

// MARK: - Diff Pane Content View (for synced scrolling)
struct DiffPaneContentView: View {
    let file: DiffFile
    let side: DiffSide
    let width: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(side == .left ? "Before" : "After")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                side == .left ?
                Color.red.opacity(0.05) :
                Color.green.opacity(0.05)
            )
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(side == .left ? .red.opacity(0.3) : .green.opacity(0.3)),
                alignment: .bottom
            )
            
            // Content
            VStack(spacing: 0) {
                ForEach(file.hunks) { hunk in
                    DiffHunkView(hunk: hunk, side: side)
                }
            }
        }
        .frame(width: width)
    }
}

// MARK: - Diff Pane
struct DiffPaneView: View {
    let file: DiffFile
    let side: DiffSide
    let width: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(side == .left ? "Before" : "After")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                side == .left ?
                Color.red.opacity(0.05) :
                Color.green.opacity(0.05)
            )
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(side == .left ? .red.opacity(0.3) : .green.opacity(0.3)),
                alignment: .bottom
            )
            
            // Content
            ScrollView([.vertical, .horizontal]) {
                VStack(spacing: 0) {
                    ForEach(file.hunks) { hunk in
                        DiffHunkView(hunk: hunk, side: side)
                    }
                }
            }
        }
        .frame(width: width)
    }
}

// MARK: - Diff Hunk View
struct DiffHunkView: View {
    let hunk: DiffHunk
    let side: DiffSide
    
    var body: some View {
        VStack(spacing: 0) {
            // Hunk header
            HStack {
                Text(hunk.header)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.1))
            
            // Lines
            ForEach(hunk.lines) { line in
                DiffLineView(line: line, side: side)
            }
        }
    }
}

// MARK: - Diff Line View
struct DiffLineView: View {
    let line: DiffLine
    let side: DiffSide
    
    var shouldShow: Bool {
        switch (side, line.type) {
        case (.left, .addition):
            return false
        case (.right, .deletion):
            return false
        default:
            return true
        }
    }
    
    var displayContent: String {
        if !shouldShow {
            return ""
        }
        return line.content
    }
    
    var lineNumber: String {
        if !shouldShow {
            return ""
        }
        
        if side == .left {
            if let num = line.oldLineNumber {
                return "\(num)"
            }
        } else {
            if let num = line.newLineNumber {
                return "\(num)"
            }
        }
        return ""
    }
    
    var backgroundColor: Color {
        if !shouldShow {
            return Color.gray.opacity(0.05)
        }
        return line.type.backgroundColor
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Line number
            Text(lineNumber)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
                .padding(.horizontal, 8)
                .background(Color.gray.opacity(0.05))
            
            // Content
            Text(displayContent)
                .font(.system(size: 12, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
        }
        .frame(height: 20)
        .background(backgroundColor)
    }
}

// MARK: - Empty Diff View
struct EmptyDiffView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No file selected")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Select a file from the sidebar to view its diff")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
