# Quick Start Guide

## GitDiffViewer - Beautiful Git Diff Viewer for macOS

### Installation & Running

**Option 1: Quick Run (Recommended)**
```bash
./run.sh
```
The app will launch and appear in your menu bar with a branch icon (⎇)

**Option 2: Open in Xcode**
```bash
open GitDiffViewer.xcodeproj
```
Then press ⌘R to run

**Option 3: Build and Run Manually**
```bash
xcodebuild -project GitDiffViewer.xcodeproj -scheme GitDiffViewer -configuration Debug build
open ~/Library/Developer/Xcode/DerivedData/GitDiffViewer-*/Build/Products/Debug/GitDiffViewer.app
```

### 🔔 Menu Bar Feature

**GitDiffViewer now lives in your menu bar!**
- Look for the branch icon (⎇) in the top-right of your screen
- Click it to access: Open Repository, Show Window, Quit, and more
- Close the window with `⌘W` - the app stays running in the menu bar
- Click "Show Window" from the menu bar to bring it back anytime

### First Time Use

1. **Launch the app** - You'll see a beautiful welcome screen with a gradient background

2. **Open a repository** - Click "Open Repository" and select any directory containing a git repository

3. **View changes** - The app will automatically load:
   - Commit history in the timeline
   - Unstaged changes (if any)
   - All changed files

### Interface Overview

```
┌─────────────────────────────────────────────────────────────┐
│  GitDiffViewer                                    ⟲ Refresh │
├──────────────┬──────────────────────────────────────────────┤
│              │                                              │
│  Timeline    │           Side-by-Side Diff View            │
│  ─────────   │                                              │
│              │  ┌──────────────┬──────────────┐            │
│  📄 Unstaged │  │   Before     │    After     │            │
│              │  ├──────────────┼──────────────┤            │
│  Commits:    │  │  1  old line │  1  new line │            │
│  ├─ abc123   │  │  2  context  │  2  context  │            │
│  ├─ def456   │  │  3 -deleted  │              │            │
│  └─ ghi789   │  │              │  3 +added    │            │
│              │  └──────────────┴──────────────┘            │
│  Files       │                                              │
│  ─────       │                                              │
│  ✏️  file.txt│                                              │
│  ➕ new.txt  │                                              │
│  ➖ old.txt  │                                              │
└──────────────┴──────────────────────────────────────────────┘
```

### Features

#### Timeline View
- **Unstaged Changes**: Click to see uncommitted changes
- **Commit List**: Browse through commit history
- **Commit Info**: See hash, author, date, and message

#### Files View
- **File List**: All changed files with status icons
- **Statistics**: See +additions and -deletions count
- **Quick Navigation**: Click any file to view its diff

#### Diff View
- **Side-by-Side**: Before (left) and After (right) comparison
- **Line Numbers**: Easy reference for both versions
- **Color Coding**:
  - 🟢 Green background = Added lines
  - 🔴 Red background = Deleted lines
  - ⚪ White background = Context lines
- **Synchronized**: Both panes show corresponding changes

### File Status Icons

- ✏️ **Modified** (Blue pencil) - File was changed
- ➕ **Added** (Green plus) - New file
- ➖ **Deleted** (Red minus) - File removed
- ➡️ **Renamed** (Orange arrow) - File moved/renamed
- 📄 **Copied** (Purple docs) - File copied

### Keyboard Shortcuts

- `⌘O` - Open Repository
- `⌘R` - Refresh (reload commits)
- `⌘W` - Close window
- `⌘Q` - Quit application

### Tips & Tricks

1. **Large Repositories**: The app loads the last 100 commits by default for performance

2. **No Changes?**: If you see "No file selected", make sure:
   - You're in a git repository
   - There are commits or unstaged changes
   - A file is selected in the sidebar

3. **Switching Views**: Use the Timeline/Files tabs to switch between commit history and file list

4. **File Navigation**: Click any file in the Files tab to jump directly to its diff

### Troubleshooting

**App won't open repository**
- Make sure the directory contains a `.git` folder
- Check that git is installed: `which git`

**No commits showing**
- Verify the repository has commits: `git log`
- Try refreshing with ⌘R

**Build errors**
- Make sure you have Xcode 15.0+
- Run `xcodegen generate` to regenerate the project
- Clean build folder: `rm -rf ~/Library/Developer/Xcode/DerivedData/GitDiffViewer-*`

### Example Workflow

```bash
# 1. Make some changes to your code
echo "new feature" >> myfile.txt

# 2. Open GitDiffViewer
./run.sh

# 3. In the app:
#    - Click "Open Repository"
#    - Select your project directory
#    - Click "Unstaged Changes"
#    - Select "myfile.txt" from the Files tab
#    - View the beautiful side-by-side diff!

# 4. Commit your changes
git add myfile.txt
git commit -m "Add new feature"

# 5. In GitDiffViewer:
#    - Click the refresh button
#    - See your new commit in the timeline
#    - Click it to view the commit's changes
```

### Advanced Usage

**Viewing Specific Commits**
- Click any commit in the timeline to see its changes
- The diff shows what changed in that commit compared to its parent

**Comparing Files**
- Switch between files using the Files tab
- Each file shows all its hunks (sections of changes)

**Understanding Hunks**
- Each hunk header shows: `@@ -oldStart,oldCount +newStart,newCount @@`
- This tells you which lines changed in each version

### Performance Notes

- **Fast Loading**: Asynchronous git operations don't block the UI
- **Efficient Parsing**: Optimized diff parsing for large files
- **Lazy Rendering**: Only visible content is rendered

### What's Next?

Future enhancements planned:
- Syntax highlighting for code
- Search within diffs
- Export to HTML/PDF
- Stage/unstage individual hunks
- Command-line interface
- Timeline slider for quick navigation

---

**Enjoy using GitDiffViewer!** 🎉

For issues or contributions, see the main README.md
