# GitDiffViewer

A beautiful native macOS application for viewing git diffs with side-by-side comparison.

![GitDiffViewer](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![macOS](https://img.shields.io/badge/macOS-14.0+-green)

## Features

✨ **Beautiful Side-by-Side Diff View**
- Clean, modern interface inspired by professional diff tools
- Color-coded additions (green) and deletions (red)
- Line numbers for easy reference
- Synchronized scrolling between before/after panes

📜 **Timeline & History**
- Browse commit history with detailed metadata
- View unstaged changes instantly
- Quick navigation between commits
- Author and date information

📁 **File Management**
- File tree view with status indicators
- Quick file switching
- File statistics (additions/deletions count)
- Support for renamed and copied files

🎨 **Design**
- Gradient color scheme (purple to blue)
- Native macOS look and feel
- Responsive layout
- Clean typography with monospace fonts for code

🔔 **Menu Bar Integration**
- Lives in the macOS menu bar for quick access
- Stays running when window is closed
- Quick access menu with common actions
- Always available, never intrusive

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later (for building)
- Git installed on your system

## Installation

### Building from Source

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd swift-diff
   ```

2. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

3. Build the project:
   ```bash
   xcodebuild -project GitDiffViewer.xcodeproj -scheme GitDiffViewer -configuration Release build
   ```

4. The built app will be located at:
   ```
   ~/Library/Developer/Xcode/DerivedData/GitDiffViewer-*/Build/Products/Release/GitDiffViewer.app
   ```

### Running from Xcode

1. Open `GitDiffViewer.xcodeproj` in Xcode
2. Select the GitDiffViewer scheme
3. Press ⌘R to build and run

## Usage

### Opening a Repository

1. Launch GitDiffViewer
2. Click "Open Repository" on the welcome screen
3. Select a directory containing a git repository
4. The app will load the commit history and unstaged changes

### Viewing Diffs

**Unstaged Changes:**
- Click "Unstaged Changes" in the timeline sidebar
- View all uncommitted changes in your working directory

**Commit History:**
- Browse commits in the timeline view
- Click any commit to view its changes
- See commit hash, author, date, and message

**File Navigation:**
- Switch to the "Files" tab to see all changed files
- Click any file to view its diff
- File status icons indicate: Added (green +), Modified (blue pencil), Deleted (red -), Renamed (orange arrow)

### Menu Bar Access

GitDiffViewer lives in your macOS menu bar for quick, persistent access:

1. **Find the Icon**: Look for the branch icon (⎇) in the top-right menu bar
2. **Click to Access Menu**:
   - **Open Repository...** - Open a new git repository
   - **Show Window** - Bring back the main window if closed
   - **About GitDiffViewer** - View app information
   - **Quit GitDiffViewer** - Exit the application
3. **Close Window Without Quitting**: Press `⌘W` to close the window - the app stays running in the menu bar
4. **Reopen Window**: Click the menu bar icon and select "Show Window"

**Pro Tip**: The app continues running in the menu bar even when the main window is closed, making it instantly accessible whenever you need to view diffs.

### Keyboard Shortcuts

- `⌘O` - Open Repository
- `⌘R` - Refresh (reload commits)
- `⌘W` - Close window (app stays in menu bar)

## Architecture

### Core Components

**Models** (`Models.swift`)
- `CommitInfo`: Represents git commit metadata
- `DiffFile`: Represents a changed file with hunks
- `DiffHunk`: Represents a section of changes
- `DiffLine`: Represents individual line changes

**Git Integration** (`GitService.swift`)
- Executes git commands via `Process`
- Parses git output (log, diff)
- Handles unstaged changes and commit history

**UI Components**
- `ContentView.swift`: Main app structure and welcome screen
- `MainDiffView.swift`: Split view with sidebar and diff panes
- `DiffContentView.swift`: Side-by-side diff rendering

### Git Commands Used

```bash
# Load commit history
git log --pretty=format:%H%n%h%n%an%n%at%n%s%n%P -n 100 --no-merges

# View unstaged changes
git diff HEAD

# View commit diff
git diff <parent-hash> <commit-hash>
```

## Technical Details

### Diff Parsing

The app parses standard unified diff format:
- Detects file headers (`diff --git`)
- Parses hunk headers (`@@ -oldStart,oldCount +newStart,newCount @@`)
- Identifies line types: additions (+), deletions (-), context ( )
- Handles file status: added, modified, deleted, renamed

### Performance

- Lazy loading of commit history
- Efficient text rendering with SwiftUI
- Asynchronous git command execution
- Minimal memory footprint

## Future Enhancements

- [ ] Syntax highlighting for code
- [ ] Timeline slider for quick navigation
- [ ] Search within diffs
- [ ] Export diffs to HTML/PDF
- [ ] Command-line interface
- [ ] Dark mode optimization
- [ ] Diff statistics and visualizations
- [ ] Stage/unstage individual hunks
- [ ] Compare arbitrary commits

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - feel free to use this project for any purpose.

## Credits

Built with:
- SwiftUI for the user interface
- Native macOS APIs
- Git command-line tools

Inspired by professional diff tools and the need for a fast, native macOS git diff viewer.
