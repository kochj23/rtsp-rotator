# Installation Guide - RTSP Rotator v2.0

This guide walks you through installing and configuring RTSP Rotator on your macOS system.

## System Requirements

- **Operating System**: macOS 10.15 (Catalina) or later recommended
- **macOS 11.0 (Big Sur) or later** for modern UserNotifications framework
- **Development Tools**: Xcode 14.0 or later (for building from source)
- **Disk Space**: ~100 MB
- **RAM**: 4 GB minimum, 8 GB recommended for multiple cameras
- **Network**:
  - Access to RTSP camera feeds
  - Bandwidth: ~2-8 Mbps per camera
  - For 12 cameras @ 720p: ~50-80 Mbps
  - Wired Ethernet connection strongly recommended

## What's New in v2.0

**No External Dependencies!** RTSP Rotator now uses Apple's native AVFoundation framework instead of VLCKit. This means:
- ✅ No CocoaPods required
- ✅ No VLCKit installation needed
- ✅ Smaller app size
- ✅ Better macOS integration
- ✅ Standard .app bundle structure

## Quick Start

### 1. Build the Application

```bash
# Navigate to project directory
cd "~/Desktop/xcode/RTSP Rotator"

# Open in Xcode
open "RTSP Rotator.xcodeproj"
```

In Xcode:
1. Select the "RTSP Rotator" scheme
2. Product > Build (⌘B)
3. Product > Run (⌘R)

The application will launch as a standard macOS app with:
- Main window showing video display
- Status menu icon for quick access
- Preferences window (opens automatically if no cameras configured)

**That's it!** No external frameworks to install.

### 2. First Launch Setup

On first launch:

1. **Preferences window opens automatically** (if no cameras configured)
2. **Create your first dashboard:**
   - Click "Add Dashboard"
   - Name it (e.g., "External Cameras")
   - Select layout (1×1, 2×2, 3×2, 3×3, or 4×3)
   - Click "Save"

3. **Add RTSP cameras:**
   - Select "RTSP Cameras" tab
   - Click "Add Camera"
   - Enter camera details:
     - Name/Label
     - Host/IP address
     - Port (default: 554)
     - Username/Password (if required)
     - Stream path
   - Assign to dashboard
   - Click "Save"

4. **Or add Google Home cameras:**
   - Select "Google Home Cameras" tab
   - Click "Authenticate with Google"
   - Sign in with Google account
   - Grant permissions
   - Click "Discover Cameras"
   - Select cameras to import
   - Assign to dashboards
   - Click "Import"

5. **Configure settings:**
   - Set rotation interval (default: 60 seconds)
   - Enable/disable audio
   - Configure dashboard auto-cycling (optional)
   - Enable health monitoring (optional)

6. **Start watching:**
   - Close preferences
   - Cameras start playing automatically

## Building from Source

### Option 1: Build in Xcode (Recommended)

```bash
cd "~/Desktop/xcode/RTSP Rotator"
open "RTSP Rotator.xcodeproj"
```

Then in Xcode:
- Select "RTSP Rotator" scheme
- Press ⌘B to build
- Press ⌘R to run

### Option 2: Build from Command Line

```bash
cd "~/Desktop/xcode/RTSP Rotator"

# Debug build
xcodebuild -project "RTSP Rotator.xcodeproj" \
           -scheme "RTSP Rotator" \
           -configuration Debug \
           build

# Release build
xcodebuild -project "RTSP Rotator.xcodeproj" \
           -scheme "RTSP Rotator" \
           -configuration Release \
           build \
           CONFIGURATION_BUILD_DIR="$(pwd)/build"
```

Built application location:
```
~/Library/Developer/Xcode/DerivedData/RTSP_Rotator-*/Build/Products/Debug/RTSP Rotator.app
```

Or for Release build:
```
~/Desktop/xcode/RTSP Rotator/build/RTSP Rotator.app
```

### Running the Built Application

```bash
# Run debug build
open ~/Library/Developer/Xcode/DerivedData/RTSP_Rotator-*/Build/Products/Debug/RTSP\ Rotator.app

# Run release build
open build/RTSP\ Rotator.app
```

## Configuration

### RTSP Camera Setup

RTSP cameras require the following information:

**Required:**
- Name/Label (for display)
- Host/IP address
- Port (default: 554)

**Optional:**
- Username/Password (for authentication)
- Stream path (e.g., `/stream1`, `/live`, `/h264`)
- TLS/SSL (use `rtsps://` for encrypted streams)
- Preferred framerate
- PTZ control support
- Audio settings

**URL Format:**
```
rtsp://[username:password@]host[:port]/path
```

**Examples:**
```
rtsp://192.168.1.100:554/stream1
rtsp://admin:password@camera.local:554/live
rtsps://secure-camera.example.com/camera/stream
```

### Google Home Camera Setup

**Prerequisites:**
1. Google Home or Nest camera
2. Google Cloud Project with Smart Device Management API enabled
3. OAuth 2.0 credentials configured

**Steps:**
1. Open Preferences > Google Home Cameras
2. Click "Authenticate with Google"
3. Sign in with your Google account
4. Grant required permissions
5. Click "Discover Cameras"
6. Select cameras to import
7. Assign to dashboards
8. Configure refresh intervals

**Note:** Google Home streams expire after 5 minutes and will auto-refresh.

### Multi-Dashboard Configuration

For 36+ cameras, create multiple dashboards:

**Recommended Setup:**
- Dashboard 1: 12 external cameras (4×3 layout)
- Dashboard 2: 12 internal cameras (4×3 layout)
- Dashboard 3: 12 additional cameras (4×3 layout)

**Enable Dashboard Auto-Cycling:**
1. Open dashboard settings
2. Enable "Auto-cycle dashboards"
3. Set cycle interval (e.g., 60 seconds)
4. All dashboards will rotate automatically

**Dashboard Layouts:**
- **1×1**: 1 camera (full screen)
- **2×2**: 4 cameras in grid
- **3×2**: 6 cameras (3 columns × 2 rows)
- **3×3**: 9 cameras in grid
- **4×3**: 12 cameras (4 columns × 3 rows)

## Code Signing

### Automatic Signing (Recommended)

1. Open project in Xcode
2. Select "RTSP Rotator" target
3. Go to "Signing & Capabilities" tab
4. Check "Automatically manage signing"
5. Select your team from dropdown
6. Xcode creates provisioning profile automatically

### Manual Signing

If you need manual code signing:

```bash
# List available identities
security find-identity -v -p codesigning

# Sign the application
codesign --force --sign "Your Developer ID" \
         --timestamp \
         --options runtime \
         "RTSP Rotator.app"

# Verify signature
codesign -dvv "RTSP Rotator.app"
```

## Testing Camera Feeds

Before adding cameras to RTSP Rotator, test URLs:

### Test with VLC Media Player

```bash
# Install VLC (if not already installed)
brew install --cask vlc

# Test RTSP URL
/Applications/VLC.app/Contents/MacOS/VLC rtsp://your-camera-url
```

If VLC can't play the stream, RTSP Rotator won't be able to either.

### Test with ffmpeg

```bash
# Install ffmpeg (if not already installed)
brew install ffmpeg

# Test RTSP stream
ffmpeg -rtsp_transport tcp -i rtsp://your-camera-url -t 10 -f null -

# Should show stream info without errors
```

### Built-in Diagnostics

RTSP Rotator includes comprehensive diagnostics:

1. Open Preferences > Diagnostics
2. Click "Test All Cameras" or test individual cameras
3. Review diagnostic reports:
   - Connection status and time
   - Stream details (resolution, framerate, bitrate)
   - Network metrics (latency, packet loss)
   - Warnings and errors

## Post-Installation

### Verify Installation

Check application logs:

```bash
# View real-time logs
log stream --predicate 'process == "RTSP Rotator"' --level debug

# Expected output:
# [AppDelegate] Application starting...
# [AppDelegate] Loaded X feeds
# [INFO] Starting RTSP Rotator
# [INFO] AVPlayer initialized
# [INFO] Playing feed 1/X: rtsp://...
```

### Test Functionality

**1. Verify camera playback:**
- Main window should show video
- Check for smooth playback
- Verify correct aspect ratio

**2. Test feed rotation:**
- Wait for rotation interval (default: 60 seconds)
- Feed should automatically switch
- Check logs for "Switching to next feed"

**3. Test dashboard switching:**
- Click status menu icon
- Select different dashboard
- Cameras should change to new dashboard

**4. Test mute toggle:**
- Press Return/Enter in main window
- Or use menu: Controls > Toggle Mute
- Check audio on/off

**5. Run diagnostics:**
- Open Preferences > Diagnostics
- Click "Test All Cameras"
- Verify status indicators update (Green/Yellow/Red)

### Configure Launch at Login (Optional)

**Method 1: System Preferences**
1. System Preferences > Users & Groups
2. Select your user
3. Click "Login Items" tab
4. Click "+" button
5. Navigate to and select "RTSP Rotator.app"
6. Click "Add"

**Method 2: Launch Agent**

```bash
# Create launch agent
cat > ~/Library/LaunchAgents/com.rtsp.rotator.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
          "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.rtsp.rotator</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/RTSP Rotator.app/Contents/MacOS/RTSP Rotator</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

# Load launch agent
launchctl load ~/Library/LaunchAgents/com.rtsp.rotator.plist

# Verify it's loaded
launchctl list | grep rtsp
```

## Troubleshooting

### Application Won't Launch

**Problem:** Application opens and immediately quits

**Solutions:**
1. Check Console.app for crash logs:
   - Open Console.app
   - Search for "RTSP Rotator"
   - Look for crash reports
2. Verify Info.plist is properly configured
3. Check code signing:
   ```bash
   codesign -dvv "RTSP Rotator.app"
   ```
4. Ensure proper entitlements (camera access, network)

### Build Errors

**Problem:** Build fails in Xcode

**Solutions:**
1. Clean build folder (⌘⇧K)
2. Close and reopen Xcode
3. Delete DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/RTSP_Rotator-*
   ```
4. Verify code signing settings
5. Check for compilation errors in Issue Navigator

### Feeds Won't Play

**Problem:** Application runs but no video displays

**Solutions:**
1. **Check RTSP URL format:**
   - Verify URL syntax: `rtsp://host:port/path`
   - Test URL in VLC first
   - Check username/password if required

2. **Verify network connectivity:**
   ```bash
   ping camera-ip-address
   telnet camera-ip-address 554
   ```

3. **Check firewall settings:**
   - Allow outgoing connections on port 554
   - Check router firewall settings
   - Verify camera is accessible on network

4. **Run diagnostics:**
   - Open Preferences > Diagnostics
   - Test individual cameras
   - Review error messages

5. **Check logs:**
   ```bash
   log show --predicate 'process == "RTSP Rotator"' --last 5m
   ```

### Google Home Cameras Fail to Connect

**Problem:** Google Home authentication or stream errors

**Solutions:**
1. **Verify OAuth credentials:**
   - Check Google Cloud Console
   - Ensure Smart Device Management API is enabled
   - Verify OAuth 2.0 client ID and secret

2. **Check API permissions:**
   - Ensure camera permissions are granted
   - Verify API quota is not exceeded

3. **Refresh authentication:**
   - Open Preferences > Google Home
   - Click "Re-authenticate"
   - Grant permissions again

4. **Try manual stream refresh:**
   - Select camera in preferences
   - Click "Refresh Stream"
   - Check if new URL works

### High CPU/Memory Usage

**Problem:** System resources maxed out with many cameras

**Solutions:**
1. **Use dashboard auto-cycling instead of viewing all 36 cameras at once:**
   - Create 3 dashboards with 12 cameras each
   - Enable auto-cycling
   - Reduces active camera count

2. **Reduce camera resolution at source:**
   - Use 720p instead of 1080p for grid views
   - Configure camera to output lower resolution

3. **Limit active cameras:**
   - Use fewer than 12 cameras per dashboard
   - Use smaller grid layouts (2×2 or 3×2)

4. **Check network bandwidth:**
   - Ensure gigabit Ethernet connection
   - Monitor bandwidth usage
   - Reduce camera bitrates if needed

5. **Monitor system resources:**
   ```bash
   # Check CPU usage
   top -pid $(pgrep "RTSP Rotator")

   # Check memory usage
   ps aux | grep "RTSP Rotator"
   ```

### Status Indicators Not Updating

**Problem:** Green/red lights don't change

**Solutions:**
1. **Enable automatic health monitoring:**
   - Open Preferences > Diagnostics
   - Check "Enable automatic health monitoring"
   - Set check interval (default: 60 seconds)

2. **Manually run diagnostics:**
   - Open Preferences > Diagnostics
   - Click "Test All Cameras"
   - Wait for tests to complete

3. **Check that cameras are enabled:**
   - Open Preferences > RTSP Cameras or Google Home
   - Verify cameras have checkmarks (enabled)

4. **Verify network connectivity:**
   - Test each camera URL individually
   - Check firewall settings

## Advanced Configuration

### Performance Optimization for 36+ Cameras

**Recommended Setup:**
```
Total: 36 cameras
├── Dashboard 1: 12 external cameras (4×3, auto-cycle every 60s)
├── Dashboard 2: 12 internal cameras (4×3, auto-cycle every 60s)
└── Dashboard 3: 12 additional cameras (4×3, auto-cycle every 60s)
```

**Network Requirements:**
- Minimum bandwidth: 100 Mbps (gigabit recommended)
- 12 cameras @ 720p ≈ 50-80 Mbps
- Use wired Ethernet connection
- Configure QoS for camera traffic if available

**System Requirements:**
- RAM: 8 GB minimum, 16 GB recommended
- CPU: Quad-core Intel/Apple Silicon
- macOS 11.0+ for best performance

### Custom Installation Location

```bash
# Build with custom output directory
xcodebuild -project "RTSP Rotator.xcodeproj" \
           -scheme "RTSP Rotator" \
           -configuration Release \
           CONFIGURATION_BUILD_DIR="/Applications" \
           build

# Application will be built to:
# /Applications/RTSP Rotator.app
```

### Backup Configuration

Preferences are stored in NSUserDefaults:

```bash
# Export preferences
defaults export com.jkoch.RTSP-Rotator ~/rtsp-rotator-backup.plist

# Import preferences (on another Mac or after reinstall)
defaults import com.jkoch.RTSP-Rotator ~/rtsp-rotator-backup.plist
```

## Uninstallation

To completely remove RTSP Rotator:

```bash
# Stop application if running
killall "RTSP Rotator"

# Remove application
rm -rf "/Applications/RTSP Rotator.app"

# Remove preferences
defaults delete com.jkoch.RTSP-Rotator

# Remove launch agent (if configured)
launchctl unload ~/Library/LaunchAgents/com.rtsp.rotator.plist
rm ~/Library/LaunchAgents/com.rtsp.rotator.plist

# Remove cached data (if any)
rm -rf ~/Library/Caches/com.jkoch.RTSP-Rotator
rm -rf ~/Library/Application\ Support/RTSP\ Rotator
```

## Getting Help

If you encounter issues:

1. **Check documentation:**
   - [README.md](README.md) - Feature overview and usage
   - [MULTI_DASHBOARD_GUIDE.md](MULTI_DASHBOARD_GUIDE.md) - Dashboard system details
   - [API.md](API.md) - Development documentation
   - [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) - Architecture details

2. **Review logs:**
   ```bash
   log stream --predicate 'process == "RTSP Rotator"' --level debug
   ```

3. **Run diagnostics:**
   - Open Preferences > Diagnostics
   - Test all cameras
   - Review diagnostic reports

4. **Test cameras externally:**
   - Verify RTSP streams work in VLC
   - Check network connectivity
   - Verify camera credentials

5. **Check Console.app:**
   - Open Console.app
   - Filter for "RTSP Rotator"
   - Look for errors or warnings

## Next Steps

After successful installation:

- **Read the user guide:** [README.md](README.md)
- **Configure multiple dashboards:** [MULTI_DASHBOARD_GUIDE.md](MULTI_DASHBOARD_GUIDE.md)
- **Set up Google Home cameras:** [README.md](README.md#google-home-camera-setup)
- **Enable health monitoring:** Preferences > Diagnostics
- **Configure keyboard shortcuts:** Preferences > Shortcuts

## Version Information

This installation guide is for **RTSP Rotator v2.0** (October 2025).

**What's New:**
- Standard macOS application (.app bundle)
- No external dependencies (AVFoundation-powered)
- Multi-dashboard system (unlimited dashboards)
- Google Home/Nest camera support
- Comprehensive diagnostics system
- Real-time health monitoring
- Visual status indicators
- Zero compilation warnings

For older versions, please refer to the documentation included with that version.

---

**Copyright © 2025 Jordan Koch**
