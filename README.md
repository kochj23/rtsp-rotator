# RTSP Rotator v2.4.0

A powerful macOS application for displaying RTSP camera feeds with **AI-powered object detection**. Perfect for home security, business monitoring, and smart automation.

**✅ Latest Update (January 2026) - v2.4.0:**
- **🆕 CSV Camera Import** - Bulk import cameras from CSV files for rapid deployment!
- **🆕 OSD Toggle** - On-screen display control for camera names and status
- **🧠 MLX Object Detection** - Real-time AI detection of people, vehicles, animals, packages
- **🎯 Smart Alerts** - Zone-based alerts with cooldown periods
- **🔒 100% On-Device** - Complete privacy, no cloud processing

**Previous Features:**
- **UniFi Protect Integration** - Automatic camera discovery and bulk import
- **Configuration Export/Import** - Cross-platform config management
- **Multi-Dashboard System** - Organize up to 36+ cameras
- **Google Home Integration** - Native Google Home/Nest support
- **REST API** - Remote control for home automation

## What's New in v2.4.0

### 🆕 CSV Camera Import
**Bulk camera import for rapid deployment!**

- Import multiple cameras from CSV format: `name,url,type`
- Automatic URL validation for RTSP, HTTP, and HTTPS protocols
- Header row detection and automatic skipping
- Comment line support (# prefix)
- Quoted field handling for complex names
- Error reporting with line numbers for invalid entries
- Access via: File → Import Cameras from CSV
- Creates bookmarks for all successfully imported cameras

**Example CSV Format:**
```csv
name,url
Living Room,rtsp://192.168.1.100:554/stream
Front Door,rtsp://admin:pass@192.168.1.101/main
"Garage (Main)",rtsp://192.168.1.102:554/stream1
```

### 🆕 On-Screen Display (OSD) Control
**Toggle camera information overlay!**

- Show/hide camera names on video feeds
- Display timestamp and status indicators
- Persistent state via UserDefaults
- Toggle via: View → Toggle OSD
- Visual notification on state change
- Per-application OSD preferences

## 🧠 AI Object Detection (v2.3.0)

RTSP Rotator now includes **powerful on-device machine learning** for real-time object detection!

### Key Features
- **Real-time Detection**: Identify people, vehicles, animals, packages, and 80+ object classes
- **Smart Alerts**: Configurable alerts per object type with cooldown periods
- **Detection Zones**: Monitor specific areas only (driveway, front porch, etc.)
- **Visual Overlays**: Animated bounding boxes with labels and confidence scores
- **Complete Privacy**: 100% on-device processing, no cloud required
- **Performance**: 30-60 FPS on Apple Silicon, 15-30 FPS on Intel
- **Statistics**: Full event logging with CSV export

### Quick Start
```bash
# Download a CoreML model
cd "/Volumes/Data/xcode/RTSP Rotator"
./download_models.sh

# Add model to Xcode project and rebuild
```

### Documentation
- **[MLX_OBJECT_DETECTION.md](MLX_OBJECT_DETECTION.md)** - Complete feature guide
- **[MLX_INTEGRATION_GUIDE.md](MLX_INTEGRATION_GUIDE.md)** - Developer integration
- **download_models.sh** - Model download helper

---

## What's New in v2.2.0

### 🆕 UniFi Protect Integration
**Automatic camera discovery and import for UniFi Protect ecosystems!**

15. **UniFi Protect Adapter** - Seamless integration with UniFi cameras
    - Automatic camera discovery via UniFi Protect controller
    - Bulk import of all cameras with one click
    - Real-time connection status monitoring
    - Secure authentication (HTTPS/HTTP with self-signed cert support)
    - Optimized RTSP URL generation
    - Health testing before import
    - **📖 See [DOCS/UNIFI_PROTECT.md](DOCS/UNIFI_PROTECT.md) for complete documentation**

### 🔄 Configuration Export/Import System (v2.1.1)
**Cross-platform configuration management for multi-device deployments!**

14. **Configuration Export/Import** - Export all settings to JSON format
    - Export to local file or upload to remote URL
    - Import from file or download from URL
    - Auto-sync between devices (macOS, iOS, tvOS, screensaver)
    - Merge or replace modes
    - Centralized configuration management
    - **📖 See [CONFIGURATION_EXPORT.md](CONFIGURATION_EXPORT.md) for documentation**

### 🚀 13 Major Features from v2.1

**Phase 1 - Quick Wins:**
1. **Feed Bookmarks** - ⌘1-9 keyboard shortcuts for instant camera access
2. **Custom Transitions** - 11 transition effects (fade, slide, zoom, etc.)
3. **Full-Screen Mode** - Overlay controls with auto-hide
4. **Audio Monitoring** - Real-time audio level meters with alerts
5. **Motion Detection** - AI-powered motion detection with confidence scoring

**Phase 2 - High-Impact Features:**
6. **Picture-in-Picture** - Floating window for monitoring critical cameras
7. **Thumbnail Grid** - Live preview grid of all cameras
8. **PTZ Control** - Full pan/tilt/zoom control for compatible cameras
9. **REST API Server** - HTTP API for home automation integration
10. **Feed Failover** - Automatic backup feed switching

**Phase 3 - Advanced Features:**
11. **Smart Alerts** - Vision framework object detection (people, vehicles, animals)
12. **Cloud Storage** - Auto-upload to iCloud, Dropbox, Google Drive, or S3
13. **Event Timeline** - Comprehensive event logging with CSV/PDF export

**📖 See [NEW_FEATURES_V2.1.md](NEW_FEATURES_V2.1.md) for v2.1 feature documentation**

## Features

### Core Features
- **Standard macOS Application**: Proper app bundle with Dock integration, menu bar, and window management
- **Multi-Dashboard Support**: Create unlimited dashboards, each supporting up to 12 cameras simultaneously
- **Automatic Feed Rotation**: Cycles through multiple RTSP streams at configurable intervals
- **Grid Layouts**: View 1, 4, 6, 9, or 12 cameras simultaneously (1×1, 2×2, 3×2, 3×3, 4×3)
- **AVFoundation-Powered**: Uses Apple's native framework for robust RTSP stream handling
- **Zero External Dependencies**: No need to install VLCKit or other frameworks
- **Configuration UI**: Full preferences window with comprehensive camera management
- **Persistent Storage**: All configuration saved automatically
- **Audio Control**: Individual camera mute control

### Camera Management
- **RTSP Camera Support**: Full support for standard RTSP cameras with detailed configuration
- **Google Home/Nest Integration**: Native support for Google Home cameras via SDM API
- **UniFi Protect Integration**: Automatic camera discovery and import for UniFi ecosystems
- **Camera Type Separation**: Separate management for different camera types
- **Comprehensive Diagnostics**: Connection tests, stream analysis, health monitoring
- **Status Indicators**: Color-coded status lights (Green/Yellow/Red/Blue/Gray)
- **Feed Metadata**: Custom display names, categories, health tracking, statistics

### Advanced Features
- **On-Screen Display (OSD)**: Visual feedback for feed changes and diagnostics
- **Recording & Snapshots**: Capture screenshots or record video from streams
- **Status Menu Bar**: Quick access to controls and dashboard switching
- **Global Keyboard Shortcuts**: System-wide hotkeys for common actions
- **Import/Export**: Bulk camera import with CSV support
- **Feed Testing**: Test connectivity before adding feeds
- **Multi-Monitor Support**: Display on specific monitors
- **Health Tracking**: Monitor feed uptime, connection quality, framerate, bitrate
- **Automatic Health Monitoring**: Periodic health checks with alerts
- **Dashboard Auto-Cycling**: Automatically rotate between dashboards

## Requirements

- macOS 10.15 (Catalina) or later recommended
- macOS 11.0 (Big Sur) or later for modern UserNotifications
- Xcode 14.0 or later (for building)
- **No external dependencies!** AVFoundation is built into macOS

## Installation

### Quick Start

1. **Clone or download** the project

2. **Open the project:**
   ```bash
   cd "/Users/kochj/Desktop/xcode/RTSP Rotator"
   open "RTSP Rotator.xcodeproj"
   ```

3. **Build in Xcode:**
   - Select the "RTSP Rotator" scheme
   - Product > Build (⌘B)
   - Product > Run (⌘R)

4. **The application will:**
   - Launch as a standard macOS app
   - Show main window with video display
   - Display status menu icon for quick access
   - Open preferences if no cameras are configured

**That's it!** No external frameworks to install.

## Configuration

### Multi-Dashboard Setup

The application supports organizing cameras into multiple dashboards:

1. **Open Preferences** from the status menu or application menu
2. **Create Dashboards:**
   - Click "Add Dashboard"
   - Name it (e.g., "External Cameras", "Internal Cameras")
   - Select layout (1×1, 2×2, 3×2, 3×3, 4×3)
   - Configure display options

3. **Add Cameras:**
   - Choose camera type (RTSP or Google Home)
   - Enter camera details
   - Assign to dashboard
   - Enable/disable as needed

### RTSP Camera Configuration

RTSP cameras support detailed configuration:

```
URL Format: rtsp://[username:password@]host[:port]/path

Required:
- Name/Label
- RTSP URL
- Port (default: 554)

Optional:
- Username/Password
- Stream Path
- TLS/SSL (rtsps://)
- Preferred Framerate
- PTZ Control Support
- Audio Settings
```

Examples:
- `rtsp://192.168.1.100:554/stream1`
- `rtsp://admin:password@camera.local:554/live`
- `rtsps://secure-camera.example.com/camera/stream`

### Google Home Camera Setup

1. **Prerequisites:**
   - Google Home/Nest camera
   - Google Cloud Project with Smart Device Management API enabled
   - OAuth 2.0 credentials

2. **Authentication:**
   - Open Preferences > Google Home
   - Click "Authenticate"
   - Sign in with Google account
   - Grant permissions

3. **Import Cameras:**
   - Click "Discover Cameras"
   - Select cameras to import
   - Assign to dashboards
   - Configure refresh intervals

**Note:** Google Home streams expire after 5 minutes and auto-refresh.

### Dashboard Layouts

Each dashboard supports different grid layouts:

- **1×1**: Single camera, full screen
- **2×2**: 4 cameras in a grid
- **3×2**: 6 cameras (3 columns × 2 rows)
- **3×3**: 9 cameras in a grid
- **4×3**: 12 cameras (4 columns × 3 rows)

## Usage

### Running the Application

1. **Launch** from Xcode or built .app bundle
2. **Main Window** appears showing selected dashboard
3. **Status Menu** provides quick access to:
   - Dashboard switching
   - Preferences
   - Diagnostics
   - Quit

### Dashboard Management

**Switching Dashboards:**
- Click status menu > Select dashboard
- Use keyboard shortcuts (configurable)
- Enable auto-cycling for automatic rotation

**Dashboard Auto-Cycling:**
- Enable in dashboard settings
- Set cycle interval (e.g., every 60 seconds)
- Perfect for rotating through 36+ cameras

### Camera Diagnostics

**Run Diagnostics:**
1. Open Preferences > Diagnostics
2. Click "Test All Cameras" or test individual cameras
3. View detailed reports:
   - Connection status and time
   - Stream details (resolution, framerate, bitrate)
   - Network metrics (latency, packet loss)
   - Warnings and errors

**Status Indicators:**
- 🟢 **Green**: Healthy (all good)
- 🟡 **Yellow**: Warning (minor issues)
- 🔴 **Red**: Critical (not working)
- 🔵 **Blue**: Testing in progress
- ⚪ **Gray**: Unknown (not yet tested)

**Automatic Health Monitoring:**
- Enable in Preferences > Diagnostics
- Set check interval (default: 60 seconds)
- Get notifications for unhealthy cameras

### Keyboard Controls

- **Return/Enter**: Toggle audio mute
- **Cmd+,**: Open preferences
- **Cmd+Q**: Quit application
- **Cmd+F**: Toggle full screen

Custom global shortcuts can be configured in Preferences.

## Architecture

### Application Structure

```
RTSP Rotator.app
├── AppDelegate
│   ├── Application lifecycle management
│   ├── Window creation and management
│   ├── Manager initialization
│   └── Status menu setup
│
├── RTSPWallpaperController
│   ├── Video playback management
│   ├── Feed rotation logic
│   ├── AVPlayer/AVPlayerLayer integration
│   └── Dual-mode operation (standalone/integrated)
│
├── RTSPDashboardManager
│   ├── Multi-dashboard management
│   ├── Dashboard persistence (NSCoding)
│   ├── Auto-cycling support
│   └── Camera assignment
│
├── RTSPCameraTypeManager
│   ├── RTSP camera management
│   ├── Google Home camera management
│   ├── Type-specific configuration
│   └── Connection testing
│
├── RTSPCameraDiagnostics
│   ├── Comprehensive health checks
│   ├── Stream analysis (resolution, framerate, bitrate)
│   ├── Network diagnostics (latency, packet loss)
│   ├── Automatic monitoring
│   └── Report generation
│
├── RTSPMultiViewGrid
│   ├── Grid layout management
│   ├── Camera cell rendering
│   ├── Synchronized playback
│   └── Status indicator display
│
├── RTSPGoogleHomeAdapter
│   ├── OAuth 2.0 authentication
│   ├── Smart Device Management API
│   ├── Camera discovery
│   └── Stream URL generation
│
├── RTSPConfigurationManager
│   ├── Persistent storage
│   ├── Feed metadata management
│   └── Settings management
│
├── RTSPPreferencesController
│   ├── Preferences window UI
│   ├── Camera management interface
│   └── Settings configuration
│
├── RTSPStatusMenuController
│   ├── Menu bar integration
│   ├── Dashboard switching
│   └── Quick actions
│
└── Additional Components
    ├── RTSPRecorder (snapshots/recording)
    ├── RTSPOSDView (on-screen display)
    ├── RTSPGlobalShortcuts (keyboard shortcuts)
    ├── RTSPMotionDetector (motion detection)
    ├── RTSPNetworkMonitor (network monitoring)
    └── More...
```

### Code Structure

```
RTSP Rotator/
├── RTSP Rotator/
│   ├── AppDelegate.h/m              # Application delegate
│   ├── main.m                       # Application entry point
│   ├── Info.plist                   # Application metadata
│   │
│   ├── Core Controllers
│   ├── RTSP_RotatorView.m          # RTSPWallpaperController implementation
│   ├── RTSPWallpaperController.h   # Main video controller
│   │
│   ├── Multi-Dashboard System
│   ├── RTSPDashboardManager.h/m    # Dashboard management
│   ├── RTSPMultiViewGrid.h/m       # Grid view display
│   │
│   ├── Camera Management
│   ├── RTSPCameraTypeManager.h/m   # Camera type manager
│   ├── RTSPCameraDiagnostics.h/m   # Health monitoring
│   ├── RTSPGoogleHomeAdapter.h/m   # Google Home integration
│   │
│   ├── UI Components
│   ├── RTSPPreferencesController.h/m
│   ├── RTSPStatusMenuController.h/m
│   ├── RTSPOSDView.h/m
│   │
│   └── ... (40+ additional components)
│
├── Documentation/
│   ├── README.md                    # This file
│   ├── REFACTORING_SUMMARY.md      # App refactoring details
│   ├── MULTI_DASHBOARD_GUIDE.md    # Multi-dashboard usage
│   ├── API.md                       # API documentation
│   ├── FEATURES_V2.md              # Feature list
│   └── ... (additional docs)
│
└── RTSP Rotator.xcodeproj/         # Xcode project
```

## Troubleshooting

### Common Issues

**Problem**: Application won't launch
- **Solution**: Check Console.app for error messages
- **Solution**: Verify Info.plist is properly configured
- **Solution**: Ensure code signing is set up correctly

**Problem**: Feeds won't play
- **Solution**: Check RTSP URL format and network connectivity
- **Solution**: Verify camera/server is accessible
- **Solution**: Check firewall settings for port 554
- **Solution**: Run diagnostics to identify specific issues

**Problem**: Google Home cameras fail to connect
- **Solution**: Verify OAuth credentials are valid
- **Solution**: Check Smart Device Management API is enabled
- **Solution**: Ensure camera permissions are granted
- **Solution**: Try refreshing the stream URL

**Problem**: High CPU/memory usage with many cameras
- **Solution**: Use dashboard auto-cycling instead of viewing all cameras
- **Solution**: Reduce camera resolution at source
- **Solution**: Limit active cameras to 12 or fewer
- **Solution**: Use 720p instead of 1080p for grid views

**Problem**: Status indicators not updating
- **Solution**: Enable automatic health monitoring
- **Solution**: Manually run diagnostics
- **Solution**: Check that cameras are enabled

### Performance Optimization

**For 36+ Cameras:**
1. Create 3+ dashboards with 12 cameras each
2. Enable dashboard auto-cycling
3. Use 720p streams for grid layouts
4. Use gigabit Ethernet connection
5. Monitor system resources

**Network Requirements:**
- Bandwidth: ~2-8 Mbps per camera
- 12 cameras @ 720p ≈ 50-80 Mbps
- Wired connection strongly recommended

## Development

### Building from Source

```bash
cd "/Users/kochj/Desktop/xcode/RTSP Rotator"
xcodebuild -project "RTSP Rotator.xcodeproj" -scheme "RTSP Rotator" build
```

### Running Tests

```bash
xcodebuild test -scheme "RTSP Rotator" -destination "platform=macOS"
```

### Adding New Features

The application uses a modular architecture. To add features:

1. **New Camera Type**: Extend RTSPCameraTypeManager
2. **New Layout**: Add to RTSPDashboardLayout enum
3. **New Diagnostic**: Extend RTSPCameraDiagnostics
4. **New UI**: Add view controller and integrate with AppDelegate

## Security Considerations

- Credentials stored in NSUserDefaults (consider Keychain for production)
- OAuth tokens managed securely by Google APIs
- RTSP streams support authentication
- Local network access only (no external routing by default)
- Regular updates recommended for security patches

## License

Copyright © 2025 Jordan Koch

## Contributing

This is a personal project. For issues or suggestions, please contact the author.

## Version History

### Version 2.0.0 (Current - Oct 2025)
- **Major Refactoring**: Now a standard macOS application (.app)
- Added multi-dashboard system (unlimited dashboards)
- Added Google Home/Nest camera support
- Added comprehensive diagnostics system
- Added real-time health monitoring
- Added visual status indicators
- Added grid layouts (up to 12 cameras simultaneously)
- Added camera type management
- Refactored for better architecture and maintainability
- Zero compilation warnings, clean build

### Version 1.1.0
- Added comprehensive documentation
- Implemented external configuration file support
- Added error handling and validation
- Improved logging throughout
- Thread-safe operations

### Version 1.0.0
- Initial release
- Basic RTSP feed rotation
- Desktop-level window display

## Credits

- **AVFoundation**: Apple's native media framework
- **Google Smart Device Management API**: For Google Home integration
- **Author**: Jordan Koch

## Support

For questions or support:
- Review documentation in `/Documentation`
- Check logs in Console.app
- Run camera diagnostics
- Verify RTSP streams work in other players (VLC, etc.)

## Roadmap

Completed features (formerly on roadmap):
- ✅ Standard macOS application
- ✅ Multi-dashboard support
- ✅ Google Home integration
- ✅ Comprehensive diagnostics
- ✅ Health monitoring
- ✅ Status indicators
- ✅ Grid layouts
- ✅ Camera type management

Future enhancements:
- [ ] Touch Bar support
- [ ] Picture-in-Picture mode improvements
- [ ] Advanced motion detection
- [ ] Cloud storage integration
- [ ] Mobile app for remote monitoring
- [ ] Machine learning-based alerts
- [ ] Multi-user support with roles
- [ ] Advanced PTZ control

---

**Last Updated:** January 22, 2026
**Status:** ✅ Production Ready
