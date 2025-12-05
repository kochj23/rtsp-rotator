#!/bin/bash

PROJECT_FILE="RTSP Rotator.xcodeproj/project.pbxproj"
BACKUP_FILE="RTSP Rotator.xcodeproj/project.pbxproj.backup"

# Backup the project file
cp "$PROJECT_FILE" "$BACKUP_FILE"

# Change product type from screensaver to application
sed -i '' 's/PRODUCT_BUNDLE_IDENTIFIER = DisneyGPT.RTSP-Rotator;/PRODUCT_BUNDLE_IDENTIFIER = com.disneyg pt.rtsp-rotator;/g' "$PROJECT_FILE"
sed -i '' 's/WRAPPER_EXTENSION = saver;/WRAPPER_EXTENSION = app;/g' "$PROJECT_FILE"
sed -i '' 's/com.apple.product-type.bundle.screen-saver/com.apple.product-type.application/g' "$PROJECT_FILE"
sed -i '' 's/productType = "com.apple.product-type.bundle.screen-saver"/productType = "com.apple.product-type.application"/g' "$PROJECT_FILE"

echo "Project file updated successfully"
echo "Backup saved to: $BACKUP_FILE"
