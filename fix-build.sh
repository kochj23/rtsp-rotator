#!/bin/bash
# fix-build.sh - Automated RTSP Rotator build fix
# This script installs VLCKit and prepares the project for building

set -e

echo "========================================="
echo "RTSP Rotator v2.0 - Build Fix Script"
echo "========================================="
echo

# Navigate to project directory
cd "/Users/kochj/Desktop/xcode/RTSP Rotator"

# Check if CocoaPods is installed
if ! command -v pod &> /dev/null; then
    echo "📦 CocoaPods not found. Installing..."
    sudo gem install cocoapods
    echo "✅ CocoaPods installed"
else
    echo "✅ CocoaPods already installed"
fi

# Create Podfile
echo
echo "📝 Creating Podfile..."
cat > Podfile << 'EOF'
platform :osx, '10.15'
use_frameworks!

target 'RTSP Rotator' do
  pod 'VLCKit', '~> 3.0'
end
EOF
echo "✅ Podfile created"

# Install VLCKit
echo
echo "📦 Installing VLCKit (this may take a few minutes)..."
pod install

echo
echo "========================================="
echo "✅ Installation Complete!"
echo "========================================="
echo
echo "IMPORTANT NEXT STEPS:"
echo
echo "1. Open the WORKSPACE (not the project):"
echo "   open 'RTSP Rotator.xcworkspace'"
echo
echo "2. In Xcode, add Carbon.framework:"
echo "   - Select project → Target 'RTSP Rotator'"
echo "   - General → Frameworks and Libraries"
echo "   - Click '+' → Search 'Carbon' → Add"
echo
echo "3. Build the project:"
echo "   - Product → Build (⌘B)"
echo
echo "4. If errors occur, check BUILD_ERRORS_AND_FIXES.md"
echo
echo "========================================="
echo

# Automatically open workspace
echo "Opening workspace..."
open "RTSP Rotator.xcworkspace"

echo "Done! Check Xcode for build status."
