#!/bin/bash
# Run GitDiffViewer

set -e

echo "🔨 Building GitDiffViewer..."
xcodebuild -project GitDiffViewer.xcodeproj -scheme GitDiffViewer -configuration Debug build > /dev/null 2>&1

echo "✅ Build successful!"
echo "🚀 Launching GitDiffViewer..."

open ~/Library/Developer/Xcode/DerivedData/GitDiffViewer-*/Build/Products/Debug/GitDiffViewer.app

echo "✨ GitDiffViewer is now running!"
