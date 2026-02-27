# Fix "VLCKit/VLCKit.h file not found" Error

If you're seeing this error even though VLCKit has been removed, it's due to Xcode's build cache.

## Quick Fix (Try These in Order)

### Step 1: Clean Build Folder in Xcode
1. Open Xcode
2. Product → Clean Build Folder (⌘⇧K)
3. Product → Build (⌘B)

### Step 2: Clear Derived Data
```bash
# Close Xcode first, then:
rm -rf ~/Library/Developer/Xcode/DerivedData/RTSP_Rotator-*
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
```

Then reopen Xcode and build.

### Step 3: Reset Xcode Package Cache
```bash
# Close Xcode first, then:
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData
```

Then reopen Xcode and build.

### Step 4: Build from Command Line
This bypasses Xcode's GUI caching:

```bash
cd "~/Desktop/xcode/RTSP Rotator"

# Clean everything
xcodebuild -project "RTSP Rotator.xcodeproj" -scheme "RTSP Rotator" clean
rm -rf ~/Library/Developer/Xcode/DerivedData/RTSP_Rotator-*

# Build fresh
xcodebuild -project "RTSP Rotator.xcodeproj" -scheme "RTSP Rotator" build
```

**Expected Output:** `** BUILD SUCCEEDED **`

### Step 5: Verify No VLCKit References

Run this to confirm all VLCKit code has been removed:

```bash
cd "~/Desktop/xcode/RTSP Rotator"
find . -name "*.m" -o -name "*.h" | xargs grep -i "vlckit" | grep -v ".git"
```

**Expected Output:** No output (empty) - this means VLCKit is completely removed.

## If Error Persists

### Check if you have an old workspace file:

```bash
cd "~/Desktop/xcode/RTSP Rotator"
ls -la *.xcworkspace 2>/dev/null
```

If you see `RTSP Rotator.xcworkspace`, this might be from the old CocoaPods setup. Delete it:

```bash
rm -rf "RTSP Rotator.xcworkspace"
rm -rf Podfile
rm -rf Podfile.lock
rm -rf Pods/
```

Then open the `.xcodeproj` file directly:

```bash
open "RTSP Rotator.xcodeproj"
```

## Verification Commands

### Verify the build succeeds:
```bash
cd "~/Desktop/xcode/RTSP Rotator"
xcodebuild -project "RTSP Rotator.xcodeproj" -scheme "RTSP Rotator" clean build 2>&1 | tail -20
```

You should see:
```
** BUILD SUCCEEDED **
```

### Verify no VLCKit in compiled files:
```bash
cd "~/Desktop/xcode/RTSP Rotator"
find ~/Library/Developer/Xcode/DerivedData/RTSP_Rotator-*/Build -name "*.o" 2>/dev/null | xargs nm 2>/dev/null | grep -i vlc || echo "✅ No VLCKit references in compiled code"
```

## What Was Changed

All VLCKit references have been replaced with AVFoundation:

- ❌ `#import <VLCKit/VLCKit.h>`
- ✅ `#import <AVFoundation/AVFoundation.h>`
- ✅ `#import <AVKit/AVKit.h>`

- ❌ `VLCMediaPlayer *player`
- ✅ `AVPlayer *player`

- ❌ `VLCMedia *media`
- ✅ `AVPlayerItem *playerItem`

## Still Having Issues?

### Check which file is causing the error:

When you build and see the error, Xcode should show which file is trying to import VLCKit. Look for:

```
/path/to/file.m:10:9: error: 'VLCKit/VLCKit.h' file not found
```

The file path and line number will tell you exactly which file still has the import.

### Manual verification of all source files:

```bash
cd "~/Desktop/xcode/RTSP Rotator/RTSP Rotator"
for file in *.m *.h; do
    echo "Checking $file..."
    grep -n "VLCKit\|VLCMedia\|VLC" "$file" 2>/dev/null || echo "  ✅ Clean"
done
```

All files should show "✅ Clean"

## Contact Information

If the error persists after trying all these steps, please provide:

1. The exact error message from Xcode
2. The file and line number where the error occurs
3. Output of: `find . -name "*.m" -o -name "*.h" | xargs grep -n "VLCKit"`
4. Output of: `xcodebuild -version`

---

**Status:** All VLCKit code has been removed. The error is from cached build data.

**Solution:** Clean build folders and derived data as shown above.

**Verified:** Command-line build succeeds with `** BUILD SUCCEEDED **`
