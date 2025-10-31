//
//  Models.swift
//  GitDiffViewer
//
//  Data models for git diff representation
//

import Foundation
import SwiftUI

// MARK: - Commit Info
struct CommitInfo: Identifiable, Equatable {
    let id: String // commit hash
    let hash: String
    let shortHash: String
    let author: String
    let date: Date
    let message: String
    let parentHash: String?
    
    var displayDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Diff File
struct DiffFile: Identifiable, Equatable {
    let id = UUID()
    let path: String
    let oldPath: String?
    let status: FileStatus
    let hunks: [DiffHunk]
    
    var fileName: String {
        (path as NSString).lastPathComponent
    }
    
    var displayPath: String {
        if let oldPath = oldPath, oldPath != path {
            return "\(oldPath) → \(path)"
        }
        return path
    }
    
    enum FileStatus: String {
        case added = "A"
        case modified = "M"
        case deleted = "D"
        case renamed = "R"
        case copied = "C"
        case unmerged = "U"
        
        var color: Color {
            switch self {
            case .added: return .green
            case .modified: return .blue
            case .deleted: return .red
            case .renamed: return .orange
            case .copied: return .purple
            case .unmerged: return .yellow
            }
        }
        
        var icon: String {
            switch self {
            case .added: return "plus.circle.fill"
            case .modified: return "pencil.circle.fill"
            case .deleted: return "minus.circle.fill"
            case .renamed: return "arrow.right.circle.fill"
            case .copied: return "doc.on.doc.fill"
            case .unmerged: return "exclamationmark.triangle.fill"
            }
        }
    }
}

// MARK: - Diff Hunk
struct DiffHunk: Identifiable, Equatable {
    let id = UUID()
    let header: String
    let oldStart: Int
    let oldCount: Int
    let newStart: Int
    let newCount: Int
    let lines: [DiffLine]
}

// MARK: - Diff Line
struct DiffLine: Identifiable, Equatable {
    let id = UUID()
    let type: LineType
    let content: String
    let oldLineNumber: Int?
    let newLineNumber: Int?
    
    enum LineType {
        case context
        case addition
        case deletion
        case empty
        
        var backgroundColor: Color {
            switch self {
            case .context: return .clear
            case .addition: return Color.green.opacity(0.15)
            case .deletion: return Color.red.opacity(0.15)
            case .empty: return Color.gray.opacity(0.05)
            }
        }
        
        var prefix: String {
            switch self {
            case .context: return " "
            case .addition: return "+"
            case .deletion: return "-"
            case .empty: return " "
            }
        }
    }
}

// MARK: - View Mode
enum ViewMode: Equatable {
    case unstaged
    case commit(CommitInfo)
    case commitRange(from: CommitInfo, to: CommitInfo)
}

// MARK: - Side by Side Line Pair
struct LinePair: Identifiable {
    let id = UUID()
    let leftLine: DiffLine?
    let rightLine: DiffLine?
}

