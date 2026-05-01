# RTSP Rotator v2.5.1

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS%2011.0%2B-blue.svg)](https://developer.apple.com/macos/)
[![Language: Objective-C](https://img.shields.io/badge/Language-Objective--C-orange.svg)](https://developer.apple.com/documentation/objectivec)
[![Tests: 7 Suites](https://img.shields.io/badge/Tests-7%20Suites-green.svg)](#testing)

**A professional macOS application for RTSP (Real Time Streaming Protocol) camera feeds with AI-powered object detection**

Perfect for home security, business monitoring, smart automation, and video wall applications with enterprise-grade features including real-time machine learning detection.

---

## Architecture

```mermaid
graph TB
    subgraph "Application Layer"
        AD[AppDelegate] --> WC[RTSPWallpaperController]
        AD --> MBC[RTSPMenuBarController]
        AD --> SMC[RTSPStatusMenuController]
        AD --> PC[RTSPPreferencesController]
    end

    subgraph "Camera Management"
        CM[RTSPCameraTypeManager] --> UFP[RTSPUniFiProtectAdapter]
        CM --> BM[RTSPBookmarkManager]
        CM --> FM[RTSPFeedMetadata]
    end

    subgraph "Playback & Display"
        WC --> |AVPlayer| STREAM[RTSP Stream]
        WC --> TC[RTSPTransitionController]
        WC --> FSC[RTSPFullScreenController]
        WC --> MVG[RTSPMultiViewGrid]
        WC --> PIP[RTSPPiPController]
        WC --> OSD[RTSPOSDView]
    end

    subgraph "Dashboard System"
        DM[RTSPDashboardManager] --> |Manages| DB1[Dashboard 1..N]
        DB1 --> |Contains| CAM[Camera Configs]
    end

    subgraph "AI Detection"
        OD[RTSPObjectDetector] --> MLX[RTSPMLXProcessor]
        OD --> SA[RTSPSmartAlerts]
        OD --> DOV[RTSPDetectionOverlayView]
        OD --> MD[RTSPMotionDetector]
    end

    subgraph "Security"
        KM[RTSPKeychainManager] --> |macOS Keychain| SEC[Secure Storage]
        KM --> |Migration| UD[NSUserDefaults Cleanup]
    end

    subgraph "Integration"
        API[RTSPAPIServer] --> |REST| EXT[External Systems]
        EL[RTSPEventLogger] --> |CSV/PDF| EXPORT[Export]
        CS[RTSPCloudStorage] --> |Upload| CLOUD[iCloud/S3]
        CE[RTSPConfigurationExporter] --> |JSON| CONFIG[Config Files]
    end

    AD --> CM
    AD --> DM
    AD --> OD
    WC --> KM
    UFP --> KM
```

---

## What is RTSP Rotator?

RTSP Rotator is a professional macOS application that displays and automatically rotates through multiple RTSP camera feeds with powerful AI-powered object detection capabilities. Whether you're monitoring a home security system, managing a business surveillance network, or building an intelligent video wall display, RTSP Rotator provides advanced features including real-time object detection, smart alerts, and comprehensive camera management in a native macOS application.

**Key Use Cases:**
- **Home Security**: Monitor all cameras with AI-powered detection of people, vehicles, packages
- **Business Surveillance**: Display feeds across multiple dashboards with zone-based alerting
- **Video Walls**: Grid layouts supporting up to 12 simultaneous cameras with object detection
- **NOC (Network Operations Center) / SOC (Security Operations Center) Displays**: Auto-cycling dashboards for 36+ cameras
- **Smart Home Integration**: REST API for home automation with detection triggers
- **Intelligent Monitoring**: Real-time object detection without cloud processing

**What Sets RTSP Rotator Apart:**
- **MLX (Machine Learning eXtensions) Object Detection**: On-device AI detection using Apple's MLX framework
- **macOS Widget**: Monitor cameras from your desktop with WidgetKit widget (v2.5.0+)
- **100% Privacy**: All AI processing happens locally on your Mac
- **80+ Object Classes**: Detect people, vehicles, animals, packages, and more
- **Zone-Based Alerts**: Monitor specific areas with configurable alert rules
- **Real-time Performance**: 30-60 FPS (Frames Per Second) on Apple Silicon, 15-30 FPS on Intel

---

## Features

### AI Object Detection (v2.3.0+)

#### Real-Time MLX Detection
- **80+ Object Classes**: People, vehicles (cars, trucks, buses), animals (dogs, cats, birds), packages, and more
- **On-Device Processing**: 100% local AI using Apple's MLX framework - no cloud required
- **High Performance**: 30-60 FPS on Apple Silicon (M1/M2/M3), 15-30 FPS on Intel Macs
- **Visual Overlays**: Animated bounding boxes with labels and confidence scores
- **Complete Privacy**: All detection happens on your Mac, videos never leave your network

#### Smart Alerts System
- **Per-Object Type Alerts**: Configure alerts for specific objects (person, car, dog, package, etc.)
- **Cooldown Periods**: Prevent alert spam with configurable cooldown (default: 30 seconds)
- **macOS Notifications**: System notifications with detection details
- **Alert History**: Full event logging with timestamps and confidence scores

#### Detection Zones
- **Custom Zone Definition**: Monitor specific areas only (driveway, front porch, backyard)
- **Polygon Zones**: Draw precise detection areas on video feeds
- **Zone-Specific Alerts**: Different alert rules for different zones
- **Multiple Zones**: Set up multiple zones per camera

#### Detection Analytics
- **Event Statistics**: Track detection counts, peak times, patterns
- **CSV Export**: Export detection data for analysis
- **Confidence Filtering**: Filter detections by confidence threshold
- **Detection Timeline**: Visual timeline of all detections

#### Model Support
- **YOLOv8 CoreML**: Fast, accurate object detection
- **Custom Models**: Support for custom-trained CoreML models
- **Model Management**: Easy model download and installation
- **Automatic Updates**: Model update checking

**Getting Started with Object Detection:**
```bash
# Download a CoreML model
cd "/Volumes/Data/xcode/RTSP Rotator"
./download_models.sh

# Add model to Xcode project and rebuild
# See MLX_OBJECT_DETECTION.md for complete guide
```

### Core Functionality
- **Automatic Feed Rotation**: Cycles through multiple RTSP streams at configurable intervals
- **Multi-Dashboard System**: Create unlimited dashboards, each supporting up to 12 cameras simultaneously
- **Grid Layouts**: View 1, 4, 6, 9, or 12 cameras simultaneously (1×1, 2×2, 3×2, 3×3, 4×3)
- **AVFoundation-Powered**: Uses Apple's native framework for robust RTSP stream handling
- **Zero External Dependencies**: No need to install VLCKit or other frameworks
- **Standard macOS Application**: Proper .app bundle with Dock integration, menu bar, window management
- **Persistent Storage**: All configuration saved automatically
- **Audio Control**: Individual camera mute control

### Camera Management
- **RTSP Camera Support**: Full support for standard RTSP cameras with authentication
- **Google Home/Nest Integration**: Native support via Smart Device Management API
- **UniFi Protect Integration**: Automatic camera discovery and bulk import
- **CSV Camera Import (v2.4.0)**: Bulk import from CSV files with validation
  - Import format: `name,url,type`
  - Automatic URL validation (RTSP, HTTP, HTTPS)
  - Header row detection and skipping
  - Comment line support (# prefix)
  - Quoted field handling for complex names
  - Error reporting with line numbers
  - Access: File → Import Cameras from CSV
- **Camera Type Separation**: Separate management for different camera types
- **Feed Bookmarks**: ⌘1-9 keyboard shortcuts for instant camera access
- **Feed Testing**: Test connectivity before adding feeds
- **Camera Diagnostics**: Real-time health monitoring with visual status indicators

### Dashboard Features
- **Dashboard Designer (v2.3.0)**: Visual interface for managing dashboards
  - Browse existing dashboards in dedicated window
  - View layout and camera assignments
  - Create, delete, rename, duplicate dashboards
  - Configure grid layouts (1×1 through 4×3)
  - Access via Dashboard → Open Dashboard Designer
- **Dashboard Auto-Cycling (v2.3.0)**: Automatic rotation through saved dashboards
  - Configurable cycle interval (default: 30 seconds)
  - Sequential cycling through all dashboards
  - Smooth transitions between views
  - Persistent state across app restarts
  - Perfect for monitoring 36+ cameras
- **Dashboard Layouts**: 1×1, 2×2, 3×2, 3×3, 4×3 (up to 12 cameras per dashboard)
- **Unlimited Dashboards**: Organize cameras by location, priority, or function

### Display & Visual Features
- **On-Screen Display (OSD) (v2.4.0)**: Toggle camera names and status overlays
  - Show/hide camera names on video feeds
  - Display timestamps and status indicators
  - Menu bar toggle: View → Toggle OSD
  - Persistent preferences via UserDefaults
  - Visual notification on state change
- **Custom Transitions**: 11 transition effects (fade, slide, zoom, etc.)
- **Full-Screen Mode**: Overlay controls with auto-hide
- **Picture-in-Picture**: Floating window for monitoring critical cameras
- **Thumbnail Grid**: Live preview grid of all cameras
- **Status Indicators**: Color-coded health (🟢Green/🟡Yellow/🔴Red/🔵Blue/⚪Gray)

### Advanced Features
- **REST API Server**: HTTP API for home automation integration
- **PTZ (Pan/Tilt/Zoom) Control**: Full pan/tilt/zoom control for compatible cameras
- **Motion Detection**: AI-powered motion detection with confidence scoring
- **Smart Alerts**: Vision framework object detection (people, vehicles, animals)
- **Audio Monitoring**: Real-time audio level meters with alerts
- **Recording & Snapshots**: Capture screenshots or record video from streams
- **Event Timeline**: Comprehensive event logging with CSV/PDF export
- **Cloud Storage**: Auto-upload to iCloud, Dropbox, Google Drive, or S3
- **Feed Failover**: Automatic backup feed switching
- **Configuration Export/Import**: JSON format for cross-platform deployment
- **Status Menu Bar**: Quick access to controls and dashboard switching
- **Global Keyboard Shortcuts**: System-wide hotkeys for common actions
- **Multi-Monitor Support**: Display on specific monitors
- **Health Tracking**: Monitor uptime, connection quality, framerate, bitrate

---

## What's New in v2.5.1 (May 2026)

### QE Pipeline & Test Suite
- **7 XCTest suites** with comprehensive coverage across unit, functional, security, and integration tests
- **RTSP URL Security Tests**: Credential stripping, Keychain-only storage, safe logging validation
- **CSV Import Tests**: Full CSV parsing with quoted fields, comments, header detection, URL validation
- **Keychain Manager Tests**: Store/retrieve/delete/migrate lifecycle, Unicode, thread safety
- **Configuration Tests**: Feed metadata, archiving/unarchiving, settings persistence
- **Integration Tests**: End-to-end credential flow, multi-service isolation, backwards compatibility
- **Memory Management Tests**: Deallocation verification, retain cycle detection, concurrent access
- **Core Tests**: Feed rotation, URL parsing, window management, configuration loading
- **Fixed duplicate Swift file warnings** in Xcode project (PBXFileSystemSynchronizedRootGroup cleanup)
- **Version bump** to 2.5.1 (build 251)

### What's New in v2.5.0 (February 2026)

### macOS Widget (WidgetKit)
**Monitor your cameras directly from your desktop:**

The RTSP Rotator Widget provides at-a-glance camera monitoring without opening the full app:

**Widget Sizes:**
- **Small**: Current camera name, health status, and detection count
- **Medium**: Camera status plus total stats (healthy cameras, detection count)
- **Large**: Full camera list with individual health status and detection counts

**Features:**
- Current camera name and health status
- AI detection alert counts per camera
- Camera health indicators (healthy/degraded/offline)
- Total detection statistics
- App running status indicator
- Tap to open app

**Setup:**
1. Build and run RTSP Rotator v2.5.0+
2. Right-click desktop > Edit Widgets
3. Search for "RTSP Rotator"
4. Add widget to desktop

**App Group Data Sharing:**
- Uses App Group: `group.com.jkoch.rtsprotator`
- Real-time sync between app and widget
- Automatic widget refresh every 5 minutes
- Instant updates on detection events

---

## What's New in v2.4.0 (January 2026)

### CSV Camera Import
**Bulk camera import for rapid deployment:**

```csv
# Example format
name,url,type
Living Room,rtsp://192.168.1.100:554/stream,rtsp
Front Door,rtsp://admin:pass@192.168.1.101/main,rtsp
"Garage (Main)",rtsp://192.168.1.102:554/stream1,rtsp
```

- Automatic URL validation (RTSP, HTTP, HTTPS)
- Header row detection and skipping
- Comment line support (# prefix)
- Quoted field handling for names with commas
- Error reporting with line numbers
- Creates bookmarks for all imported cameras
- Access: File → Import Cameras from CSV

### 🆕 On-Screen Display (OSD) Control
**Toggle camera information overlay:**

- Show/hide camera names on video feeds
- Display timestamps and status indicators
- Persistent state across sessions
- Toggle via View → Toggle OSD
- Visual notifications on state change
- Per-application OSD preferences

### 🧠 AI Object Detection (v2.3.0)
**Powerful on-device machine learning:**

- **Real-time Detection**: 80+ object classes at 30-60 FPS
- **Smart Alerts**: Configurable per object type with cooldown
- **Detection Zones**: Monitor specific areas only
- **Visual Overlays**: Bounding boxes with confidence scores
- **Complete Privacy**: 100% on-device, no cloud required
- **Statistics**: Event logging with CSV export

**Quick Start:**
```bash
# Download CoreML model
cd "/Volumes/Data/xcode/RTSP Rotator"
./download_models.sh

# Model will be added to project automatically
```

**Documentation:**
- **[MLX_OBJECT_DETECTION.md](MLX_OBJECT_DETECTION.md)** - Complete feature guide
- **[MLX_INTEGRATION_GUIDE.md](MLX_INTEGRATION_GUIDE.md)** - Developer integration guide
- **download_models.sh** - Model download helper script

---

## Security

### Security Features
- **RTSP Authentication**: Username/password support for camera access
- **OAuth 2.0**: Secure Google Home authentication
- **Local Network**: No external routing by default
- **Keychain Credential Storage**: All API keys stored in macOS Keychain (migrated from UserDefaults in v2.5.1)
- **App Transport Security**: Strict ATS policy enforced -- no arbitrary HTTP loads permitted
- **HTTPS Support**: rtsps:// for encrypted RTSP streams
- **Token Management**: Google OAuth tokens managed securely
- **Auto-Migration**: Existing plaintext API keys automatically migrated to Keychain on launch

### Privacy
- **No Telemetry**: No data sent to external services
- **Local Processing**: All video and AI processing on-device
- **No Cloud Storage**: (unless explicitly configured by user)
- **Audit Logging**: All events logged locally only
- **MLX Detection**: 100% on-device AI, videos never leave your Mac

### Best Practices
- Use authentication on all RTSP cameras
- Change default camera passwords
- Use VLANs (Virtual Local Area Networks) to isolate camera network
- Enable rtsps:// for encrypted streams when available
- Regularly update firmware on cameras
- Consider Keychain for credential storage in production
- Keep CoreML models updated for best detection accuracy

---

## Requirements

### System Requirements
- **macOS 10.15 (Catalina) or later** (11.0+ recommended for modern features)
- **macOS 12.0+ recommended** for MLX object detection
- **Architecture**: Universal (Apple Silicon and Intel)
  - **Apple Silicon (M1/M2/M3)**: Best performance for object detection (30-60 FPS)
  - **Intel Macs**: Good performance (15-30 FPS)
- **Xcode 14.0+** (for building from source)

### Network Requirements
- **Bandwidth**: 2-8 Mbps per camera
- **12 cameras @ 720p**: ~50-80 Mbps total
- **Wired Gigabit Ethernet**: Strongly recommended for 12+ cameras
- **Port 554**: RTSP default port (must be accessible)

### MLX Object Detection Requirements
- **macOS 12.0+**: Required for CoreML 5 features
- **CoreML Model**: YOLOv8 or compatible model (provided via download_models.sh)
- **Memory**: 4GB+ RAM recommended for object detection
- **CPU/GPU**: Apple Silicon recommended for best performance

### Dependencies
**None!** RTSP Rotator uses only built-in macOS frameworks:
- AVFoundation (video playback)
- Vision (object detection)
- CoreML (machine learning)
- AppKit (UI)
- Foundation (core functionality)

---

## Installation

### Option 1: Pre-built Binary (Recommended)

1. **Download DMG (Disk Image):**
   ```bash
   # From binaries folder
   open "/Volumes/Data/xcode/binaries/20260127-RTSPRotator-v2.4.0/RTSPRotator-v2.4.0-build240.dmg"
   ```

2. **Install:**
   - Drag RTSP Rotator.app to Applications folder
   - Double-click to launch

3. **Install Object Detection (Optional):**
   ```bash
   # Download CoreML models
   cd "/Volumes/Data/xcode/RTSP Rotator"
   ./download_models.sh
   ```

### Option 2: Build from Source

1. **Clone repository:**
   ```bash
   git clone https://github.com/kochj23/RTSPRotator.git
   cd RTSPRotator
   ```

2. **Open in Xcode:**
   ```bash
   open "RTSP Rotator.xcodeproj"
   ```

3. **Build:**
   - Select "RTSP Rotator" scheme
   - Product → Build (⌘B)
   - Product → Run (⌘R)

4. **Archive for Distribution:**
   ```bash
   xcodebuild archive -project "RTSP Rotator.xcodeproj" -scheme "RTSP Rotator" -configuration Release -archivePath "/tmp/RTSPRotator.xcarchive"
   ```

---

## Configuration

### First Launch Setup

1. **Add Your First Camera:**
   - File → Add Camera (or ⌘N)
   - Enter camera name
   - Enter RTSP URL: `rtsp://user:pass@192.168.1.100:554/stream`
   - Click Add

2. **Or Import from CSV:**
   - File → Import Cameras from CSV
   - Select your CSV file (format: `name,url,type`)
   - Review import summary

3. **Create Dashboard:**
   - Dashboard → Create New Dashboard
   - Name it (e.g., "Main Cameras")
   - Select layout (e.g., 2×2 for 4 cameras)
   - Assign cameras to dashboard

4. **Enable Object Detection (Optional):**
   - Preferences → Object Detection
   - Enable "Real-time Detection"
   - Configure alert rules per object type
   - Set up detection zones if desired

### RTSP URL Format

```
rtsp://[username:password@]host[:port]/path

Examples:
rtsp://192.168.1.100:554/stream1
rtsp://admin:password@camera.local:554/live
rtsps://secure-camera.example.com/camera/stream
```

### Camera Configuration Options

**Required:**
- Name/Label
- RTSP URL
- Port (default: 554)

**Optional:**
- Username/Password (for authenticated cameras)
- Stream Path
- TLS/SSL (rtsps://)
- Preferred Framerate
- PTZ Control Support
- Audio Settings
- Health Check Interval
- Object Detection Enabled

### Object Detection Configuration

**Enable Detection:**
1. Select camera in Preferences
2. Enable "Object Detection"
3. Choose CoreML model (auto-detected if installed)
4. Configure alert rules:
   - Enable alerts for specific objects (person, car, dog, package)
   - Set cooldown period (default: 30 seconds)
   - Choose notification sound

**Detection Zones:**
1. Open camera detail view
2. Click "Configure Zones"
3. Draw polygon zones on video preview
4. Name zones (e.g., "Driveway", "Front Door")
5. Enable/disable per-zone alerts

**Alert Examples:**
- Alert on person detected in "Front Door" zone
- Alert on vehicle in "Driveway" between 10pm-6am
- Alert on package detected (delivery notification)
- Alert on dog detected in "Backyard"

### Dashboard Configuration

**Create Multiple Dashboards:**
```
Dashboard 1: "Exterior Cameras" (12 outdoor cameras, 4×3 grid)
Dashboard 2: "Interior Cameras" (9 indoor cameras, 3×3 grid)
Dashboard 3: "Critical Areas" (4 priority cameras, 2×2 grid)
```

**Auto-Cycling Setup:**
1. Dashboard → Toggle Dashboard Auto-Cycle
2. Dashboard → Set Cycle Interval (e.g., 30 seconds)
3. Dashboards will rotate automatically

---

## Usage

### Basic Operation

**Launch Application:**
```bash
open ~/Applications/RTSP\ Rotator.app
```

**Status Menu:** Click menu bar icon for:
- Quick dashboard switching
- Camera controls
- Object detection toggle
- Preferences
- Diagnostics
- Quit

**Keyboard Shortcuts:**
- **⌘1-9**: Switch to bookmarked camera
- **⌘F**: Toggle full screen
- **⌘D**: Toggle object detection overlays
- **⌘,**: Open preferences
- **⌘Q**: Quit application
- **Return/Enter**: Toggle audio mute

### Object Detection Usage

**View Detections:**
- Bounding boxes appear automatically around detected objects
- Labels show object type and confidence (e.g., "person 95%")
- Colors indicate object category (people=green, vehicles=blue, etc.)

**Review Detection History:**
1. Window → Detection History
2. View timeline of all detections
3. Filter by object type, camera, time range
4. Export to CSV for analysis

**Configure Alerts:**
1. Preferences → Object Detection → Alerts
2. Enable alerts per object type
3. Set cooldown periods
4. Test notifications

### Dashboard Management

**Switch Dashboards:**
- Status menu → Select dashboard
- Use keyboard shortcuts (configurable)
- Auto-cycling (if enabled)

**Edit Dashboard:**
- Dashboard → Open Dashboard Designer
- View all dashboards and layouts
- Create/modify/delete dashboards

### Camera Operations

**Test Camera:**
- Select camera in preferences
- Click "Test Camera"
- Review diagnostic report

**Adjust Settings:**
- Right-click camera in grid
- Adjust audio, quality, refresh rate
- Enable/disable individual cameras
- Toggle object detection per camera

---

## Troubleshooting

### Common Issues

**Application won't launch:**
- Check Console.app for error messages
- Verify Info.plist configuration
- Ensure code signing is correct

**Feeds won't play:**
- Verify RTSP URL format
- Check network connectivity to camera
- Verify firewall allows port 554
- Run diagnostics to identify issues
- Test URL in VLC to confirm it works

**Object detection not working:**
- Verify CoreML model is installed (check Preferences → Object Detection)
- Ensure macOS 12.0+ for best compatibility
- Check camera resolution is supported (480p-4K)
- Monitor CPU usage in Activity Monitor
- Try reducing number of cameras with detection enabled

**High CPU usage with detection:**
- Reduce detection frame rate (Preferences → Object Detection → Frame Rate)
- Enable detection on fewer cameras simultaneously
- Use lower camera resolutions (720p recommended)
- On Intel Macs, limit to 2-4 cameras with detection
- Apple Silicon can handle more cameras (up to 12)

**False positive detections:**
- Increase confidence threshold (Preferences → Detection → Confidence)
- Use detection zones to limit monitored areas
- Adjust alert cooldown to reduce notification spam
- Review model settings

**Google Home cameras fail:**
- Verify OAuth credentials
- Check Smart Device Management API is enabled
- Ensure camera permissions granted
- Try refreshing stream URL

### Performance Optimization

**For Object Detection:**
- **Apple Silicon Macs**: Can handle 6-12 cameras with detection at 30-60 FPS
- **Intel Macs**: Limit to 2-4 cameras with detection at 15-30 FPS
- **Frame Rate**: Lower to 15 FPS if CPU usage too high
- **Resolution**: Use 720p for best balance of quality and performance
- **Detection Zones**: Significantly reduces CPU usage by processing less area

**For 36+ Cameras:**
1. Create 3+ dashboards with 12 cameras each
2. Enable dashboard auto-cycling (30-60 second intervals)
3. Use 720p streams for grid layouts
4. Use gigabit Ethernet connection
5. Enable object detection on critical cameras only
6. Monitor Activity Monitor for resource usage

**Network Requirements:**
- Single camera: 2-8 Mbps
- 12 cameras @ 720p: 50-80 Mbps total
- Wired connection strongly recommended

---

## REST API

RTSP Rotator includes a built-in REST API for home automation integration with object detection support.

**Endpoints:**
- `GET /feeds` - List all cameras
- `GET /current` - Get current camera index
- `POST /switch/{index}` - Switch to specific camera
- `POST /next` - Switch to next camera
- `POST /previous` - Switch to previous camera
- `POST /snapshot` - Capture current frame
- `POST /recording/start` - Start recording
- `POST /recording/stop` - Stop recording
- `GET /recording/status` - Get recording status
- `POST /interval` - Set rotation interval
- `GET /detections` - Get recent detections (NEW)
- `GET /detections/{camera}` - Get detections for specific camera (NEW)
- `POST /detection/enable` - Enable detection on camera (NEW)
- `POST /detection/disable` - Disable detection on camera (NEW)

**Example:**
```bash
# Get all feeds
curl http://localhost:8080/feeds

# Switch to camera 2
curl -X POST http://localhost:8080/switch/2

# Get recent detections
curl http://localhost:8080/detections

# Enable detection on camera 0
curl -X POST http://localhost:8080/detection/enable -d '{"camera": 0}'
```

---

## Architecture

### Application Components

```
RTSP Rotator/
├── AppDelegate                  # Application lifecycle, manager initialization
├── RTSPWallpaperController     # Video playback, feed rotation, AVPlayer integration
├── RTSPDashboardManager        # Multi-dashboard management, persistence, auto-cycling
├── RTSPCameraTypeManager       # RTSP & Google Home camera management
├── RTSPCameraDiagnostics       # Health checks, stream analysis, monitoring
├── RTSPMultiViewGrid           # Grid layout, synchronized playback
├── RTSPGoogleHomeAdapter       # OAuth 2.0, SDM API, camera discovery
├── RTSPConfigurationManager    # Persistent storage, settings
├── RTSPPreferencesController   # Preferences UI
├── RTSPStatusMenuController    # Menu bar integration
├── RTSPAPIServer               # REST API server
├── RTSPObjectDetector          # MLX/CoreML object detection (NEW)
├── RTSPDetectionZone           # Detection zone management (NEW)
├── RTSPAlertManager            # Smart alerts and notifications (NEW)
├── RTSPRecorder                # Snapshots and recording
├── RTSPOSDView                 # On-screen display
├── RTSPGlobalShortcuts         # Keyboard shortcuts
├── RTSPMotionDetector          # Motion detection
└── RTSPNetworkMonitor          # Network monitoring
```

### Technology Stack
- **Language**: Objective-C
- **UI Framework**: AppKit
- **Media Framework**: AVFoundation (AVPlayer, AVPlayerLayer)
- **AI Framework**: Vision, CoreML (object detection)
- **Storage**: NSUserDefaults, NSCoding
- **Networking**: NSURLSession
- **API**: GCDWebServer for REST endpoints

---

## Development

### Building from Source

```bash
cd "/Volumes/Data/xcode/RTSP Rotator"
xcodebuild clean build -project "RTSP Rotator.xcodeproj" -scheme "RTSP Rotator" -configuration Release
```

### Running Tests

```bash
xcodebuild test -scheme "RTSP Rotator" -destination "platform=macOS"
```

### Adding Features

**Enable Object Detection on New Camera:**
```objective-c
// In RTSPObjectDetector
- (void)enableDetectionForCamera:(RTSPCamera *)camera {
    // Load CoreML model
    // Configure detection pipeline
    // Start processing frames
}
```

**Custom Detection Zone:**
```objective-c
// In RTSPDetectionZone
RTSPDetectionZone *zone = [[RTSPDetectionZone alloc] init];
zone.name = @"Front Door";
zone.points = @[/* polygon points */];
zone.enabled = YES;
[camera addDetectionZone:zone];
```

---

## Version History

### v2.5.1 (May 2026) - Current
- **QE Pipeline**: 7 XCTest suites covering security, functional, integration, and memory tests
- **Security Tests**: RTSP URL credential handling, Keychain enforcement, plaintext prevention
- **CSV Import Tests**: Full CSV parsing validation with edge cases
- **Build Fixes**: Removed duplicate Swift file warnings, added proper test target
- **Version**: 2.5.1 (build 251)

### v2.5.0 (February 2026)
- **macOS Widget**: WidgetKit widget for desktop camera monitoring
  - Small, Medium, and Large widget sizes
  - Camera health status and detection counts
  - Real-time sync via App Group
- **App Group Integration**: Data sharing between app and widget
- **Widget Bridge**: Objective-C to Swift bridge for widget updates

### v2.4.0 (January 2026)
- **CSV Camera Import**: Bulk import with validation and error reporting
- **OSD Toggle**: On-screen display control for camera names and status
- **Enhanced Documentation**: Complete feature guides with examples

### v2.3.0 (December 2025)
- **MLX Object Detection**: Real-time AI detection of 80+ object classes
- **Smart Alerts**: Configurable per-object alerts with cooldown
- **Detection Zones**: Monitor specific areas only
- **Detection Analytics**: Event logging and CSV export
- **Dashboard Designer**: Visual dashboard management interface
- **Dashboard Auto-Cycling**: Automatic rotation through dashboards

### v2.2.0 (October 2025)
- **UniFi Protect Integration**: Automatic camera discovery
- **Configuration Export/Import**: Cross-platform config management

### v2.1.0 (September 2025)
- **15 Major Features**: Bookmarks, transitions, motion detection, API
- **Picture-in-Picture**: Floating monitor window
- **Thumbnail Grid**: Live preview of all cameras
- **PTZ Control**: Pan/tilt/zoom support
- **REST API Server**: Home automation integration

### v2.0.0 (August 2025)
- **Major Refactoring**: Standard macOS application
- **Multi-Dashboard System**: Unlimited dashboards
- **Google Home Support**: Native Nest camera integration

### v1.0.0 (Initial Release)
- Basic RTSP feed rotation
- Desktop-level window display

---

## Testing

### Test Suites (7 Total)

| Suite | Tests | Coverage Area |
|-------|-------|--------------|
| `RTSP_RotatorTests` | 14 | Core rotation, URL parsing, feed loading, window management |
| `RTSPKeychainManagerTests` | 20 | Password store/retrieve/delete, migration, isolation, Unicode |
| `RTSPConfigurationTests` | 18 | Feed metadata, archiving, settings, OSD, recording config |
| `RTSPIntegrationTests` | 10 | End-to-end credential flows, multi-service isolation |
| `RTSPMemoryManagementTests` | 12 | Deallocation, retain cycles, observer cleanup, concurrency |
| `RTSPURLSecurityTests` | 14 | Credential stripping, Keychain enforcement, URL validation |
| `RTSPCSVImportTests` | 16 | CSV parsing, quoted fields, URL validation, stream cycling |

### Running Tests

```bash
# Build and run all tests
xcodebuild test -scheme "RTSP Rotator" -destination "platform=macOS"

# Run specific test suite
xcodebuild test -scheme "RTSP Rotator" -destination "platform=macOS" \
  -only-testing:"RTSP RotatorTests/RTSPURLSecurityTests"
```

### Security Test Coverage
- RTSP URL credential parsing and stripping for safe logging
- Keychain-only password storage enforcement
- NSUserDefaults migration verification (no plaintext passwords remain)
- CSV import credential handling
- URL scheme validation (rtsp/rtsps only for stream URLs)

---

## License

MIT License

Copyright © 2026 Jordan Koch

---

## Credits

- **Author**: Jordan Koch
- **AVFoundation**: Apple's native media framework
- **Vision & CoreML**: Apple's AI frameworks for object detection
- **Google Smart Device Management API**: For Google Home/Nest integration
- **YOLOv8**: Object detection model architecture

---

## Support & Contributing

**GitHub**: https://github.com/kochj23/RTSPRotator

**Documentation:**
- **[MLX_OBJECT_DETECTION.md](MLX_OBJECT_DETECTION.md)** - Complete object detection guide
- **[MLX_INTEGRATION_GUIDE.md](MLX_INTEGRATION_GUIDE.md)** - Developer integration guide
- **[MULTI_DASHBOARD_GUIDE.md](MULTI_DASHBOARD_GUIDE.md)** - Dashboard setup guide
- **[CONFIGURATION_EXPORT.md](CONFIGURATION_EXPORT.md)** - Config management guide
- **[API.md](API.md)** - REST API documentation

**For Issues:**
- Review documentation
- Check logs in Console.app
- Run camera diagnostics
- Verify RTSP streams work in VLC

This is a personal project by Jordan Koch.

---

**Last Updated:** May 1, 2026
**Version:** 2.5.1 (build 251)
**Status:** Production Ready
