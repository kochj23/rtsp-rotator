#!/bin/bash

set -e

PROJECT="RTSP Rotator.xcodeproj/project.pbxproj"

echo "Configuring project as macOS Application..."

# Change product type
plutil -replace objects.*.productType -string "com.apple.product-type.application" "$PROJECT" 2>/dev/null || {
    # Try sed approach if plutil doesn't work
    sed -i.bak2 '
        s/com\.apple\.product-type\.bundle\.screen-saver/com.apple.product-type.application/g
        s/WRAPPER_EXTENSION = saver;/WRAPPER_EXTENSION = app;/g
        s/productName = "RTSP Rotator";/productName = "RTSP Rotator"; INFOPLIST_FILE = "RTSP Rotator\/Info.plist";/g
    ' "$PROJECT"
}

echo "Project configured successfully!"
echo "Please open the project in Xcode and manually add:"
echo "  - AppDelegate.h"
echo "  - AppDelegate.m" 
echo "  - main.m"
echo "  - Info.plist"

