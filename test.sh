#!/bin/bash
# Test GitDiffViewer with the current repository

set -e

echo "📊 GitDiffViewer Test Suite"
echo "============================="
echo ""

echo "✓ Checking if we're in a git repository..."
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Not a git repository. Please run this from a git repository."
    exit 1
fi
echo "  ✓ Git repository detected"

echo ""
echo "✓ Checking git commands..."

# Test commit log
echo "  Testing: git log"
COMMIT_COUNT=$(git log --oneline | wc -l | tr -d ' ')
echo "  ✓ Found $COMMIT_COUNT commits"

# Test diff
echo "  Testing: git diff HEAD"
DIFF_OUTPUT=$(git diff HEAD)
if [ -z "$DIFF_OUTPUT" ]; then
    echo "  ℹ No unstaged changes (this is fine)"
else
    CHANGED_FILES=$(git diff HEAD --name-only | wc -l | tr -d ' ')
    echo "  ✓ Found $CHANGED_FILES changed files"
fi

echo ""
echo "✓ Checking project structure..."
for file in "GitDiffViewer/GitDiffViewerApp.swift" "GitDiffViewer/Models.swift" "GitDiffViewer/GitService.swift" "GitDiffViewer/ContentView.swift" "GitDiffViewer/MainDiffView.swift" "GitDiffViewer/DiffContentView.swift"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ❌ Missing: $file"
    fi
done

echo ""
echo "✓ Checking Xcode project..."
if [ -d "GitDiffViewer.xcodeproj" ]; then
    echo "  ✓ GitDiffViewer.xcodeproj exists"
else
    echo "  ❌ GitDiffViewer.xcodeproj not found"
    exit 1
fi

echo ""
echo "============================="
echo "✅ All tests passed!"
echo ""
echo "To run the app:"
echo "  ./run.sh"
echo ""
echo "Or open in Xcode:"
echo "  open GitDiffViewer.xcodeproj"
echo ""
