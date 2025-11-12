#!/bin/bash

# GitDiffViewer Build Script
# This script builds the GitDiffViewer app and installs it to Applications

set -e

echo "🔨 Building GitDiffViewer..."

# Clean and build the project
echo "📦 Generating Xcode project..."
xcodegen generate

echo "🏗️ Building Release version..."
xcodebuild -project GitDiffViewer.xcodeproj -scheme GitDiffViewer -configuration Release clean build

# Find the built app
BUILT_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "GitDiffViewer.app" -type d | head -1)

if [ -z "$BUILT_APP" ]; then
    echo "❌ Failed to find built app"
    exit 1
fi

echo "📋 Built app found at: $BUILT_APP"

# Copy to project directory
echo "📁 Copying to project directory..."
cp -R "$BUILT_APP" ./

# Install to Applications
echo "🚀 Installing to Applications folder..."
sudo rm -rf /Applications/GitDiffViewer.app 2>/dev/null || true
cp -R ./GitDiffViewer.app /Applications/

# Verify installation
if [ -d "/Applications/GitDiffViewer.app" ]; then
    echo "✅ GitDiffViewer successfully built and installed!"
    echo "📱 You can now launch it from:"
    echo "   • Applications folder"
    echo "   • Spotlight (Cmd+Space, type 'GitDiffViewer')"
    echo "   • Launchpad"
    
    # Get app info
    APP_VERSION=$(defaults read /Applications/GitDiffViewer.app/Contents/Info.plist CFBundleShortVersionString)
    APP_IDENTIFIER=$(defaults read /Applications/GitDiffViewer.app/Contents/Info.plist CFBundleIdentifier)
    echo ""
    echo "ℹ️ App Details:"
    echo "   Version: $APP_VERSION"
    echo "   Bundle ID: $APP_IDENTIFIER"
    echo "   Logo: Custom-designed git diff icon ✨"
else
    echo "❌ Installation failed"
    exit 1
fi
