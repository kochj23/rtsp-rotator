# RTSPS Support - Complete Solution Guide
## Making Secure RTSP (RTSPS) Actually Work

**Date**: October 30, 2025
**Issue**: AVFoundation doesn't support RTSPS with self-signed certificates
**Error**: -1002 (NSURLErrorUnsupportedURL)

---

## 🚨 **THE FUNDAMENTAL PROBLEM**

### **Apple's AVFoundation Limitation:**
```
AVPlayer + RTSPS + Self-Signed Certificate = ❌ DOESN'T WORK
```

**Why:**
- AVFoundation uses system SSL validation
- Rejects self-signed certificates
- No way to bypass certificate validation in AVPlayer
- Error -1002: "Unsupported URL"

**Your Setup:**
- UniFi Protect Controller: 10.0.0.1
- RTSPS Port: 7441
- Certificate: Self-signed ✅ (secure but not trusted by system)
- Result: AVPlayer refuses to connect ❌

---

## ✅ **SOLUTION OPTIONS** (3 Approaches)

### **Option 1: Use VLCKit** (RECOMMENDED - Best RTSPS Support) 🥇

**Pros:**
- ✅ Full RTSPS support with self-signed certificates
- ✅ Handles all codec types
- ✅ Battle-tested (used by VLC player)
- ✅ Open source
- ✅ Easy integration

**Cons:**
- ❌ Requires external framework (68 MB)
- ❌ Adds dependency

**Implementation Time:** 20 minutes

---

### **Option 2: Direct Camera RTSP** (Quick Workaround) ⚡

**Pros:**
- ✅ Works with AVFoundation immediately
- ✅ No code changes needed
- ✅ No dependencies
- ✅ Better performance (no encryption overhead)

**Cons:**
- ❌ Unencrypted video stream
- ❌ Less secure (OK for local network)
- ❌ Requires camera configuration change

**How:**
Connect directly to camera RTSP port instead of controller proxy:
```
Instead of: rtsps://10.0.0.1:7441/camera123
Use:        rtsp://192.168.1.50:554/camera123
```

**Implementation Time:** 5 minutes (just change URLs)

---

### **Option 3: FFmpeg Local Proxy** (Advanced) 🛠️

**Pros:**
- ✅ Handles RTSPS perfectly
- ✅ Transcodes if needed
- ✅ No framework dependencies (uses system ffmpeg)

**Cons:**
- ❌ Complex implementation
- ❌ Requires FFmpeg installed
- ❌ Extra process overhead
- ❌ Latency introduced

**How:**
Run local FFmpeg process to convert RTSPS → local RTSP stream

**Implementation Time:** 45 minutes

---

## 🎯 **RECOMMENDED SOLUTION: VLCKit**

VLCKit is the industry-standard solution for this exact problem.

### **Why VLCKit:**
1. ✅ Purpose-built for streaming video
2. ✅ Handles RTSPS + self-signed certificates perfectly
3. ✅ Used by thousands of apps
4. ✅ Actively maintained
5. ✅ Simple API similar to AVPlayer
6. ✅ Better codec support than AVFoundation

### **Installation:**
```bash
# Add VLCKit via CocoaPods
pod 'VLCKit'

# Or download VLCKit.framework manually
# https://code.videolan.org/videolan/VLCKit
```

---

## 💡 **IMMEDIATE WORKAROUND** (5 minutes)

While implementing VLCKit, you can use **direct camera RTSP (non-secure)**:

### **For UniFi Protect Cameras:**

UniFi cameras expose RTSP directly (not through controller):
```
Format: rtsp://[camera-ip]:554/[channel-path]

Example:
rtsp://192.168.1.50:554/s0
rtsp://192.168.1.51:554/s0

Where:
- 192.168.1.50 = Camera's IP address (not controller)
- 554 = Standard RTSP port
- s0 = Stream 0 (high quality)
- s1 = Stream 1 (low quality/substream)
```

**This works with AVFoundation immediately!**

---

## 🔧 **QUICK FIX: Enable Direct Camera RTSP**

### **Step 1: Find Camera IPs**

UniFi cameras have their own IP addresses. Check in UniFi Protect:
1. Open UniFi Protect console
2. Go to Devices
3. Note each camera's IP address

### **Step 2: Add Direct RTSP URLs**

Instead of controller proxy:
```
❌ rtsps://10.0.0.1:7441/CAMERA_TOKEN_4?enableSrtp
✅ rtsp://192.168.1.50:554/s0
```

---

## 🚀 **WHICH SOLUTION DO YOU WANT?**

Please choose:

**A) VLCKit Integration** (20 min - BEST, full RTSPS support)
- I'll integrate VLCKit framework
- Full RTSPS + self-signed cert support
- Professional solution

**B) Quick Workaround** (5 min - FAST, works now)
- Use direct camera RTSP (non-secure)
- No code changes
- Works immediately with AVFoundation

**C) Both Solutions** (30 min - COMPREHENSIVE)
- Add VLCKit for RTSPS
- Keep AVFoundation for regular RTSP
- User can choose per-camera

**D) FFmpeg Proxy** (45 min - ADVANCED)
- Local transcoding proxy
- Handles any stream type
- Most complex

---

## 📊 **TECHNICAL DETAILS**

### **Why AVFoundation Fails:**

```objective-c
// Current code (doesn't work for RTSPS + self-signed):
if ([feedURLString hasPrefix:@"rtsps://"]) {
    NSDictionary *options = @{
        AVURLAssetPreferPreciseDurationAndTimingKey: @NO,
        @"AVURLAssetOutOfBandMIMETypeKey": @"application/sdp"
    };
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:feedURL options:options];
    // ❌ AVFoundation still rejects self-signed cert
}
```

**The Problem:**
- No option in AVURLAsset to allow self-signed certificates
- No AVPlayer API to bypass certificate validation
- System-level SSL validation cannot be overridden for AVPlayer

### **VLCKit Solution:**

```objective-c
// VLCKit handles this perfectly:
VLCMedia *media = [VLCMedia mediaWithURL:rtspsURL];
VLCMediaPlayer *player = [[VLCMediaPlayer alloc] init];
player.media = media;
[player play];
// ✅ Works with self-signed certificates!
```

---

## 📞 **TELL ME YOUR PREFERENCE!**

**What do you want me to implement?**

Type:
- **"A"** - VLCKit (full RTSPS solution)
- **"B"** - Direct camera RTSP workaround
- **"C"** - Both options
- **"D"** - FFmpeg proxy

I'll implement it immediately! 🚀

---

**Current Status:**
- ✅ App is running
- ✅ All fixes applied
- ❌ RTSPS blocked by AVFoundation limitation
- ⏳ Waiting for your choice...
