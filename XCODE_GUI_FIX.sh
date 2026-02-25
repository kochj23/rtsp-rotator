#!/bin/bash
# Fix Xcode GUI showing VLCKit error when command-line build succeeds

echo "🔧 Xcode GUI Cache Fix Script"
echo "================================"
echo ""

# Kill Xcode if running
if pgrep -x "Xcode" > /dev/null; then
    echo "⚠️  Xcode is running. Closing it..."
    osascript -e 'quit app "Xcode"'
    sleep 2
    echo "✅ Xcode closed"
else
    echo "✅ Xcode is not running"
fi

echo ""
echo "🧹 Clearing all Xcode caches..."

# Clear DerivedData
echo "  - Clearing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/RTSP_Rotator-* 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex 2>/dev/null || true

# Clear Xcode caches
echo "  - Clearing Xcode caches..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode 2>/dev/null || true

# Clear Swift package caches
echo "  - Clearing Swift caches..."
rm -rf ~/Library/Caches/org.swift.swiftpm 2>/dev/null || true

# Remove old CocoaPods artifacts if they exist
cd "$(cd "$(dirname "$0")" && pwd)"
if [ -d "RTSP Rotator.xcworkspace" ]; then
    echo "  - Removing old CocoaPods workspace..."
    rm -rf "RTSP Rotator.xcworkspace"
    rm -f Podfile Podfile.lock
    rm -rf Pods/
    echo "  ✅ Removed CocoaPods artifacts"
fi

echo ""
echo "🔨 Running clean build from command line..."
xcodebuild -project "RTSP Rotator.xcodeproj" -scheme "RTSP Rotator" clean build 2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)"

echo ""
echo "✅ Cache clearing complete!"
echo ""
echo "📋 Next steps:"
echo "1. Open Xcode with this command:"
echo "   open 'RTSP Rotator.xcodeproj'"
echo ""
echo "2. In Xcode, do:"
echo "   - Product → Clean Build Folder (⌘⇧K)"
echo "   - Product → Build (⌘B)"
echo ""
echo "3. If error persists in Xcode but command-line builds succeed:"
echo "   - Close Xcode completely"
echo "   - Run this script again"
echo "   - Reopen Xcode"
echo ""

# Open the project
echo "🚀 Opening Xcode project..."
open "RTSP Rotator.xcodeproj"

echo ""
echo "✅ Done! Xcode should open shortly."
