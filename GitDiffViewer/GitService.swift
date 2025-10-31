//
//  GitService.swift
//  GitDiffViewer
//
//  Service for interacting with git repositories
//

import Foundation

class GitService: ObservableObject {
    let repositoryPath: URL
    @Published var commits: [CommitInfo] = []
    @Published var unstagedFiles: [DiffFile] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // Cache for commit diffs to improve performance
    private var diffCache: [String: [DiffFile]] = [:]
    private let cacheQueue = DispatchQueue(label: "com.gitdiffviewer.cache")
    
    init(repositoryPath: URL) {
        self.repositoryPath = repositoryPath
    }
    
    func clearCache() {
        cacheQueue.async { [weak self] in
            self?.diffCache.removeAll()
        }
    }
    
    // MARK: - Public Methods
    
    func loadCommitHistory(limit: Int = 100) async {
        await MainActor.run { isLoading = true }
        
        do {
            let output = try await executeGit(args: [
                "log",
                "--pretty=format:%H%n%h%n%an%n%at%n%s%n%P",
                "-n", "\(limit)",
                "--no-merges"
            ])
            
            let parsedCommits = parseCommitLog(output)
            
            await MainActor.run {
                self.commits = parsedCommits
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to load commits: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func loadUnstagedChanges() async {
        await MainActor.run { isLoading = true }
        
        do {
            let output = try await executeGit(args: ["diff", "HEAD"])
            let files = parseDiff(output)
            
            await MainActor.run {
                self.unstagedFiles = files
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to load unstaged changes: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func loadDiffForCommit(_ commit: CommitInfo) async -> [DiffFile] {
        // Check cache first
        let cacheKey = commit.hash
        if let cached = await getCachedDiff(for: cacheKey) {
            print("📦 Using cached diff for commit \(commit.shortHash)")
            return cached
        }
        
        print("⏳ Loading diff for commit \(commit.shortHash)...")
        let startTime = Date()
        
        do {
            let args: [String]
            if let parent = commit.parentHash {
                args = ["diff", parent, commit.hash]
            } else {
                // First commit, show all files as added
                args = ["show", "--pretty=format:", commit.hash]
            }
            
            let output = try await executeGit(args: args)
            let files = parseDiff(output)
            
            // Cache the result
            await cacheDiff(files, for: cacheKey)
            
            let elapsed = Date().timeIntervalSince(startTime)
            print("✅ Loaded diff in \(String(format: "%.2f", elapsed))s")
            
            return files
        } catch {
            await MainActor.run {
                self.error = "Failed to load diff: \(error.localizedDescription)"
            }
            return []
        }
    }
    
    private func getCachedDiff(for key: String) async -> [DiffFile]? {
        return await cacheQueue.sync {
            return diffCache[key]
        }
    }
    
    private func cacheDiff(_ files: [DiffFile], for key: String) async {
        await cacheQueue.sync {
            diffCache[key] = files
        }
    }
    
    func loadDiffBetweenCommits(from: CommitInfo, to: CommitInfo) async -> [DiffFile] {
        do {
            let output = try await executeGit(args: ["diff", from.hash, to.hash])
            return parseDiff(output)
        } catch {
            await MainActor.run {
                self.error = "Failed to load diff: \(error.localizedDescription)"
            }
            return []
        }
    }
    
    // MARK: - Git Execution
    
    private func executeGit(args: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = repositoryPath
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        if process.terminationStatus != 0 {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw GitError.commandFailed(errorMessage)
        }
        
        return String(data: outputData, encoding: .utf8) ?? ""
    }
    
    // MARK: - Parsing
    
    private func parseCommitLog(_ output: String) -> [CommitInfo] {
        let lines = output.components(separatedBy: "\n")
        var commits: [CommitInfo] = []
        
        var i = 0
        while i < lines.count {
            guard i + 5 < lines.count else { break }
            
            let hash = lines[i]
            let shortHash = lines[i + 1]
            let author = lines[i + 2]
            let timestamp = lines[i + 3]
            let message = lines[i + 4]
            let parents = lines[i + 5]
            
            guard !hash.isEmpty else {
                i += 6
                continue
            }
            
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp) ?? 0)
            let parentHash = parents.components(separatedBy: " ").first
            
            let commit = CommitInfo(
                id: hash,
                hash: hash,
                shortHash: shortHash,
                author: author,
                date: date,
                message: message,
                parentHash: parentHash?.isEmpty == true ? nil : parentHash
            )
            
            commits.append(commit)
            i += 6
        }
        
        return commits
    }
    
    private func parseDiff(_ output: String) -> [DiffFile] {
        var files: [DiffFile] = []
        let lines = output.components(separatedBy: "\n")
        
        var i = 0
        while i < lines.count {
            let line = lines[i]
            
            // Look for diff header
            if line.hasPrefix("diff --git") {
                let (file, newIndex) = parseFile(lines: lines, startIndex: i)
                if let file = file {
                    files.append(file)
                }
                i = newIndex
            } else {
                i += 1
            }
        }
        
        return files
    }
    
    private func parseFile(lines: [String], startIndex: Int) -> (DiffFile?, Int) {
        var i = startIndex
        var path = ""
        var oldPath: String?
        var status: DiffFile.FileStatus = .modified
        var hunks: [DiffHunk] = []
        
        // Parse file header
        while i < lines.count {
            let line = lines[i]
            
            if line.hasPrefix("diff --git") {
                // Extract paths from "diff --git a/path b/path"
                let components = line.components(separatedBy: " ")
                if components.count >= 4 {
                    oldPath = String(components[2].dropFirst(2)) // Remove "a/"
                    path = String(components[3].dropFirst(2)) // Remove "b/"
                }
                i += 1
            } else if line.hasPrefix("new file mode") {
                status = .added
                i += 1
            } else if line.hasPrefix("deleted file mode") {
                status = .deleted
                i += 1
            } else if line.hasPrefix("rename from") {
                status = .renamed
                oldPath = String(line.dropFirst("rename from ".count))
                i += 1
            } else if line.hasPrefix("rename to") {
                path = String(line.dropFirst("rename to ".count))
                i += 1
            } else if line.hasPrefix("---") || line.hasPrefix("+++") {
                i += 1
            } else if line.hasPrefix("@@") {
                // Start of hunk
                let (hunk, newIndex) = parseHunk(lines: lines, startIndex: i)
                if let hunk = hunk {
                    hunks.append(hunk)
                }
                i = newIndex
            } else if line.hasPrefix("diff --git") || i >= lines.count - 1 {
                // Next file or end
                break
            } else {
                i += 1
            }
        }
        
        guard !path.isEmpty else {
            return (nil, i)
        }
        
        let file = DiffFile(
            path: path,
            oldPath: oldPath != path ? oldPath : nil,
            status: status,
            hunks: hunks
        )
        
        return (file, i)
    }
    
    private func parseHunk(lines: [String], startIndex: Int) -> (DiffHunk?, Int) {
        var i = startIndex
        let headerLine = lines[i]
        
        // Parse hunk header: @@ -oldStart,oldCount +newStart,newCount @@
        let pattern = #"@@\s*-([0-9]+),?([0-9]*)\s*\+([0-9]+),?([0-9]*)\s*@@"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: headerLine, range: NSRange(headerLine.startIndex..., in: headerLine)) else {
            return (nil, i + 1)
        }
        
        let oldStart = Int((headerLine as NSString).substring(with: match.range(at: 1))) ?? 0
        let oldCountStr = (headerLine as NSString).substring(with: match.range(at: 2))
        let oldCount = oldCountStr.isEmpty ? 1 : (Int(oldCountStr) ?? 1)
        let newStart = Int((headerLine as NSString).substring(with: match.range(at: 3))) ?? 0
        let newCountStr = (headerLine as NSString).substring(with: match.range(at: 4))
        let newCount = newCountStr.isEmpty ? 1 : (Int(newCountStr) ?? 1)
        
        i += 1
        
        var diffLines: [DiffLine] = []
        var oldLineNum = oldStart
        var newLineNum = newStart
        
        // Parse hunk lines
        while i < lines.count {
            let line = lines[i]
            
            if line.hasPrefix("@@") || line.hasPrefix("diff --git") {
                // Next hunk or file
                break
            }
            
            let type: DiffLine.LineType
            let content: String
            var oldNum: Int?
            var newNum: Int?
            
            if line.hasPrefix("+") {
                type = .addition
                content = String(line.dropFirst())
                newNum = newLineNum
                newLineNum += 1
            } else if line.hasPrefix("-") {
                type = .deletion
                content = String(line.dropFirst())
                oldNum = oldLineNum
                oldLineNum += 1
            } else if line.hasPrefix(" ") {
                type = .context
                content = String(line.dropFirst())
                oldNum = oldLineNum
                newNum = newLineNum
                oldLineNum += 1
                newLineNum += 1
            } else if line.isEmpty {
                type = .context
                content = ""
                oldNum = oldLineNum
                newNum = newLineNum
                oldLineNum += 1
                newLineNum += 1
            } else {
                // Unknown line type, treat as context
                type = .context
                content = line
                oldNum = oldLineNum
                newNum = newLineNum
                oldLineNum += 1
                newLineNum += 1
            }
            
            let diffLine = DiffLine(
                type: type,
                content: content,
                oldLineNumber: oldNum,
                newLineNumber: newNum
            )
            
            diffLines.append(diffLine)
            i += 1
        }
        
        let hunk = DiffHunk(
            header: headerLine,
            oldStart: oldStart,
            oldCount: oldCount,
            newStart: newStart,
            newCount: newCount,
            lines: diffLines
        )
        
        return (hunk, i)
    }
}

// MARK: - Git Error
enum GitError: LocalizedError {
    case commandFailed(String)
    case invalidRepository
    
    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return "Git command failed: \(message)"
        case .invalidRepository:
            return "Invalid git repository"
        }
    }
}
