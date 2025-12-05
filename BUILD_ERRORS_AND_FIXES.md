# Build Errors and Fixes - RTSP Rotator v2.0

## Build Attempt: October 29, 2025

### Build Command Used
```bash
cd "/Users/kochj/Desktop/xcode/RTSP Rotator"
xcodebuild -project "RTSP Rotator.xcodeproj" -scheme "RTSP Rotator" -configuration Debug clean build
```

---

## ❌ Primary Error: VLCKit Framework Not Found

### Error Messages
```
/Users/kochj/Desktop/xcode/RTSP Rotator/RTSP Rotator/RTSPRecorder.h:10:9:
error: 'VLCKit/VLCKit.h' file not found

/Users/kochj/Desktop/xcode/RTSP Rotator/RTSP Rotator/RTSPPreferencesController+Extended.m:10:9:
error: 'VLCKit/VLCKit.h' file not found

/Users/kochj/Desktop/xcode/RTSP Rotator/RTSP Rotator/RTSP_RotatorView.m:9:9:
error: 'VLCKit/VLCKit.h' file not found
```

### Root Cause
The VLCKit framework has not been installed or linked to the project. This is a **required dependency** for video playback.

### Solution Options

#### Option 1: Install VLCKit via CocoaPods (Recommended)

```bash
cd "/Users/kochj/Desktop/xcode/RTSP Rotator"

# Create Podfile
cat > Podfile << 'EOF'
platform :osx, '10.15'
use_frameworks!

target 'RTSP Rotator' do
  pod 'VLCKit', '~> 3.0'
end
EOF

# Install CocoaPods if needed
sudo gem install cocoapods

# Install VLCKit
pod install

# IMPORTANT: Open the workspace, not the project
open "RTSP Rotator.xcworkspace"
```

Then build from the workspace:
```bash
xcodebuild -workspace "RTSP Rotator.xcworkspace" \
           -scheme "RTSP Rotator" \
           -configuration Debug \
           clean build
```

#### Option 2: Manual VLCKit Installation

1. **Download VLCKit:**
   ```bash
   # Go to: https://code.videolan.org/videolan/VLCKit/-/releases
   # Or use direct link (check for latest version):
   curl -L -o VLCKit.zip "https://download.videolan.org/pub/cocoapods/prod/VLCKit-3.6.5b9-f20df474-3959e00d.zip"
   unzip VLCKit.zip
   ```

2. **Add to Project:**
   - Open `RTSP Rotator.xcodeproj` in Xcode
   - Drag `VLCKit.framework` into project navigator
   - Check "Copy items if needed"
   - Target: "RTSP Rotator"

3. **Configure Embedding:**
   - Select project → Target "RTSP Rotator"
   - General tab
   - Frameworks, Libraries, and Embedded Content
   - Find VLCKit.framework
   - Set to **"Embed & Sign"**

4. **Update Build Settings:**
   - Build Settings tab
   - Search "Framework Search Paths"
   - Add: `$(PROJECT_DIR)`
   - Search "Header Search Paths"
   - Add: `$(PROJECT_DIR)/VLCKit.framework/Headers`

5. **Rebuild:**
   ```bash
   xcodebuild -project "RTSP Rotator.xcodeproj" \
              -scheme "RTSP Rotator" \
              -configuration Debug \
              clean build
   ```

---

## Additional Required Frameworks

The project also needs the **Carbon framework** for global keyboard shortcuts:

### Add Carbon Framework

1. **In Xcode:**
   - Select project → Target "RTSP Rotator"
   - General tab → Frameworks and Libraries
   - Click "+" button
   - Search "Carbon"
   - Add "Carbon.framework"
   - Set to "Do Not Embed" (it's a system framework)

2. **Verify:**
   ```bash
   # Carbon should appear in link phase
   # Check project.pbxproj for:
   # System/Library/Frameworks/Carbon.framework
   ```

---

## Predicted Additional Errors (After VLCKit is Fixed)

Based on the code analysis, here are likely errors that will appear after VLCKit is resolved:

### 1. Missing Forward Declarations

**File:** `RTSPStatusMenuController.m`
**Issue:** Uses `RTSPWallpaperController` without import

**Fix:**
```objc
// Add at top of RTSPStatusMenuController.m
@class RTSPWallpaperController;

// Or add full import:
#import "RTSP_RotatorView.h"  // Contains RTSPWallpaperController
```

### 2. Category Method Conflicts

**File:** `RTSPPreferencesController+Extended.m`
**Issue:** Methods declared in category but not in main header

**Fix:**
Ensure all methods in Extended category are either:
- Declared in a category in the .h file, OR
- Are private methods (not exposed in header)

### 3. NSUserNotification Deprecation

**File:** `RTSPStatusMenuController.m` line ~278
**Issue:** `NSUserNotification` is deprecated in macOS 11+

**Fix:**
```objc
// Replace NSUserNotification with UNUserNotificationCenter
#import <UserNotifications/UserNotifications.h>

// Instead of:
NSUserNotification *notification = [[NSUserNotification alloc] init];
[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];

// Use:
UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
content.title = @"RTSP Rotator";
content.body = @"Snapshot saved to Downloads";
UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"snapshot"
                                                                      content:content
                                                                      trigger:nil];
[[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request
                                                       withCompletionHandler:nil];
```

### 4. VLCMediaPlayerStateChanged Notification

**File:** `RTSPPreferencesController+Extended.m` line ~251
**Issue:** May need to use correct notification name

**Verify:**
```objc
// Ensure using correct VLC notification constant
VLCMediaPlayerStateChanged  // Check VLCKit documentation for exact name
```

### 5. Method Signature Mismatches

**Files:** Various Extended headers/implementations
**Issue:** Methods declared but not implemented, or vice versa

**Check:**
- `RTSPWallpaperController+Extended.h` declarations
- Must have corresponding implementations in main `.m` file or extended `.m`

---

## Build Order

Once VLCKit is installed, build in this order to isolate issues:

### 1. Build Core Files First
```bash
# Test just the main view
xcodebuild -project "RTSP Rotator.xcodeproj" \
           -scheme "RTSP Rotator" \
           -configuration Debug \
           -target "RTSP Rotator" \
           ONLY_ACTIVE_ARCH=YES \
           build
```

### 2. Check for Specific File Errors
```bash
# Compile individual files to isolate issues
cd "/Users/kochj/Desktop/xcode/RTSP Rotator/RTSP Rotator"

# Test RTSPFeedMetadata (no VLC dependency)
clang -c RTSPFeedMetadata.m -o /tmp/RTSPFeedMetadata.o \
      -framework Foundation \
      -fobjc-arc

# Test RTSPOSDView (no VLC dependency)
clang -c RTSPOSDView.m -o /tmp/RTSPOSDView.o \
      -framework Cocoa \
      -fobjc-arc

# Test RTSPRecorder (requires VLC)
# Will fail without VLCKit
```

---

## Warnings to Expect (Non-Critical)

These warnings will likely appear but won't prevent building:

### 1. Deprecated Carbon APIs
```
warning: 'RegisterEventHotKey' is deprecated
```
**Impact:** None for macOS < 13
**Solution:** Will need migration to modern hotkey API in future

### 2. Implicit Conversion Warnings
```
warning: implicit conversion loses integer precision
```
**Impact:** Minor, type safety concern
**Solution:** Add explicit casts where needed

### 3. Unused Variable Warnings
```
warning: unused variable 'xyz'
```
**Impact:** None
**Solution:** Remove or prefix with `__unused`

---

## Complete Build Checklist

- [ ] **Install VLCKit** (CocoaPods or manual)
- [ ] **Add Carbon.framework** to project
- [ ] **Update project file** to include all new source files
- [ ] **Verify file targets** (all .m files in compile sources)
- [ ] **Check framework embedding** (VLCKit = Embed & Sign)
- [ ] **Set deployment target** to macOS 10.15+
- [ ] **Enable ARC** (Automatic Reference Counting)
- [ ] **Clean build folder** (Shift+Cmd+K)
- [ ] **Build** (Cmd+B)
- [ ] **Fix any remaining errors**
- [ ] **Address warnings** (optional but recommended)
- [ ] **Run** (Cmd+R)
- [ ] **Test features**

---

## Estimated Time to Fix

| Task | Time | Difficulty |
|------|------|------------|
| Install VLCKit (CocoaPods) | 5-10 min | Easy |
| Add Carbon framework | 1 min | Easy |
| Fix import issues | 5-10 min | Easy |
| Fix method signatures | 10-15 min | Medium |
| Fix deprecation warnings | 15-20 min | Medium |
| **Total** | **35-55 min** | **Medium** |

---

## Quick Fix Script

Here's a script to automate the VLCKit installation:

```bash
#!/bin/bash
# fix-build.sh - Automated VLCKit installation

set -e

echo "=== RTSP Rotator Build Fix Script ==="
echo

cd "/Users/kochj/Desktop/xcode/RTSP Rotator"

# Check if CocoaPods is installed
if ! command -v pod &> /dev/null; then
    echo "Installing CocoaPods..."
    sudo gem install cocoapods
fi

# Create Podfile
echo "Creating Podfile..."
cat > Podfile << 'EOF'
platform :osx, '10.15'
use_frameworks!

target 'RTSP Rotator' do
  pod 'VLCKit', '~> 3.0'
end
EOF

# Install pods
echo "Installing VLCKit..."
pod install

echo
echo "=== Installation Complete ==="
echo
echo "NEXT STEPS:"
echo "1. Open: RTSP Rotator.xcworkspace (not .xcodeproj!)"
echo "2. Add Carbon.framework to project"
echo "3. Build (Cmd+B)"
echo

# Open workspace
open "RTSP Rotator.xcworkspace"
```

**Run it:**
```bash
chmod +x fix-build.sh
./fix-build.sh
```

---

## Alternative: Stub VLCKit for Testing

If you want to test the build without VLCKit temporarily:

### Create VLCKit Stub

```bash
cd "/Users/kochj/Desktop/xcode/RTSP Rotator"
mkdir -p VLCKit.framework/Headers

# Create minimal VLCKit.h stub
cat > VLCKit.framework/Headers/VLCKit.h << 'EOF'
// VLCKit Stub - For compilation testing only
#import <Foundation/Foundation.h>

@class VLCMedia;
@class VLCMediaPlayer;

typedef NS_ENUM(NSInteger, VLCMediaPlayerState) {
    VLCMediaPlayerStateStopped,
    VLCMediaPlayerStateOpening,
    VLCMediaPlayerStateBuffering,
    VLCMediaPlayerStatePlaying,
    VLCMediaPlayerStatePaused,
    VLCMediaPlayerStateError,
    VLCMediaPlayerStateEnded
};

@interface VLCMedia : NSObject
+ (instancetype)mediaWithURL:(NSURL *)url;
- (void)addOption:(NSString *)option;
@end

@interface VLCMediaPlayer : NSObject
@property (nonatomic, strong) VLCMedia *media;
@property (nonatomic, assign) VLCMediaPlayerState state;
@property (nonatomic, strong) id drawable;
- (void)play;
- (void)stop;
- (void)saveVideoSnapshotAt:(NSString *)path withWidth:(int)width andHeight:(int)height;
@end

extern NSString * const VLCMediaPlayerStateChanged;
EOF

# Create module.modulemap
cat > VLCKit.framework/Headers/module.modulemap << 'EOF'
framework module VLCKit {
    umbrella header "VLCKit.h"
    export *
    module * { export * }
}
EOF
```

**Warning:** This stub won't actually work for video playback, but it will let the project compile so you can find other errors.

---

## Summary

**Primary Issue:** Missing VLCKit framework

**Resolution:** Install VLCKit via CocoaPods or manually

**Status:** Build cannot proceed until VLCKit is installed

**Next Action:** Run the fix script above or follow Option 1 installation steps

---

## Contact for Help

If issues persist after installing VLCKit:

1. Check Console.app for detailed error messages
2. Review Xcode build log (full output)
3. Verify VLCKit version compatibility (3.x required)
4. Check macOS version (10.15+ required)
5. Ensure Xcode Command Line Tools installed: `xcode-select --install`

---

**Generated:** October 29, 2025
**Project:** RTSP Rotator v2.0
**Status:** Awaiting VLCKit installation
**Estimated Fix Time:** 35-55 minutes
