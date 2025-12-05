# Changelog

All notable changes to the RTSP Rotator project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2025-10-29

### 🆕 UniFi Protect Integration

This release adds comprehensive integration with the UniFi Protect ecosystem, making it easy to automatically discover and import all your UniFi cameras.

### Added - UniFi Protect Adapter ⭐⭐⭐⭐⭐

#### Automatic Camera Discovery
- **UniFi Protect API integration** - Connect directly to UniFi Protect controller
- **Automatic camera discovery** - Finds all cameras on your UniFi network
- **Real-time camera information** - Name, model, IP address, online status
- **Connection authentication** - HTTPS/HTTP with self-signed certificate support
- **Session management** - Cookie-based authentication with automatic re-auth

#### Bulk Camera Import
- **One-click import** - Import all discovered cameras instantly
- **Selective import** - Choose specific cameras to import
- **Duplicate detection** - Prevents importing same camera twice
- **Automatic naming** - Uses UniFi camera names (e.g., "Front Door (UVC-G4-PRO)")
- **Category tagging** - Tags cameras as "UniFi Protect" for organization
- **Status-based enabling** - Only online cameras are enabled by default

#### RTSP URL Generation
- **Optimized URL format** - Generates correct RTSP URLs for UniFi cameras
- **Multi-stream support** - High, medium, and low quality streams
- **Port 7447 default** - UniFi standard RTSP port
- **Channel selection** - Channel 0 (high), 1 (medium), 2 (low)
- **Authentication embedded** - Username and password in URL

#### Health Monitoring
- **Connection testing** - Test camera accessibility before import
- **Real-time status** - Online/offline indicators for each camera
- **TCP connectivity check** - Verifies RTSP port (7447) is reachable
- **Bulk testing** - Test multiple cameras simultaneously
- **Latency measurement** - Shows connection time for each camera

#### User Interface
- **Dedicated preferences window** - Clean, intuitive interface
- **Status menu integration** - Access via "UniFi Protect..." menu item
- **Live camera table** - Shows all discovered cameras with details
- **Connection status** - Visual feedback for connection state
- **Progress indicators** - Shows activity during authentication/discovery
- **Multi-column table** - Name, model, IP, status columns

#### Configuration Persistence
- **Settings storage** - Saves controller host, port, credentials
- **Auto-load on startup** - Remembers your configuration
- **Secure password storage** - Currently in NSUserDefaults (Keychain planned)
- **HTTPS/SSL preferences** - Saves SSL verification settings

### Implementation Files

- `RTSPUniFiProtectAdapter.h/m` - Core UniFi Protect adapter (~650 lines)
- `RTSPUniFiProtectPreferences.h/m` - UI controller (~550 lines)
- `RTSPUniFiCamera` model - Camera data structure with NSCoding support
- `DOCS/UNIFI_PROTECT.md` - Comprehensive documentation (5,000+ words)
- Updated `AppDelegate.m` - Initialize UniFi adapter
- Updated `RTSPStatusMenuController.m` - Add menu item
- Updated `RTSPConfigurationExporter.m` - Export/import support
- Updated `RTSPCameraTypeManager.h` - Integration with camera types
- Updated `README.md` - Feature documentation

### Technical Details

- **Build Status:** ✅ SUCCESS (0 errors, 0 warnings)
- **Lines of Code:** ~1,200+ (adapter + UI)
- **Documentation:** 5,000+ words
- **Supported UniFi Versions:** 1.20.0 and later
- **API Endpoints Used:**
  - `POST /api/auth/login` - Authentication
  - `GET /proxy/protect/api/cameras` - Camera discovery
  - `GET /proxy/protect/api/cameras/{id}` - Individual camera details
  - `POST /api/auth/logout` - Logout

### Use Cases

1. **Home Security Systems**
   - Quickly add all UniFi cameras to RTSP Rotator
   - Automated discovery eliminates manual RTSP URL configuration
   - Perfect for large camera deployments

2. **Commercial Installations**
   - Manage dozens of cameras with ease
   - Bulk import reduces setup time from hours to minutes
   - Test camera connectivity before deployment

3. **Multi-Location Monitoring**
   - Connect to multiple UniFi Protect controllers
   - Import cameras from different sites
   - Centralized monitoring of distributed cameras

4. **Camera Testing**
   - Test camera connectivity without manual RTSP URL entry
   - Verify cameras are accessible before adding to rotation
   - Health monitoring shows camera status at a glance

### Integration Example

```objc
// Access the UniFi Protect adapter
RTSPUniFiProtectAdapter *adapter = [RTSPUniFiProtectAdapter sharedAdapter];

// Configure controller
adapter.controllerHost = @"192.168.1.1";
adapter.controllerPort = 443;
adapter.username = @"admin";
adapter.password = @"password";
adapter.useHTTPS = YES;

// Authenticate and discover cameras
[adapter authenticateWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        [adapter discoverCamerasWithCompletion:^(NSArray<RTSPUniFiCamera *> *cameras, NSError *error) {
            if (cameras) {
                NSLog(@"Found %lu cameras", (unsigned long)cameras.count);

                // Import cameras
                [adapter importCameras:cameras completion:^(NSInteger importedCount) {
                    NSLog(@"Imported %ld cameras", (long)importedCount);
                }];
            }
        }];
    }
}];
```

### RTSP URL Format

UniFi Protect cameras use this RTSP URL format:

```
rtsp://username:password@camera-ip:7447/channel
```

**Example URLs:**
- `rtsp://admin:pass@192.168.1.100:7447/0` - High quality (main stream)
- `rtsp://admin:pass@192.168.1.100:7447/2` - Low quality (sub stream)

### Camera Information Captured

For each UniFi camera, the adapter captures:
- Camera ID (unique identifier)
- Display name
- Model (e.g., UVC-G4-PRO, UVC-G3-FLEX)
- MAC address
- IP address
- Firmware version
- Online/offline status
- RTSP port and channel
- Generated RTSP URL

### Security Considerations

- **HTTPS recommended** - Encrypts credentials during authentication
- **Self-signed certificates** - SSL verification can be disabled for self-hosted controllers
- **Password storage** - Currently in NSUserDefaults (future: macOS Keychain)
- **Session cookies** - Used for authenticated API requests
- **No external connections** - All communication is local to your network

### Documentation

Comprehensive documentation available at:
- **Quick Start Guide** - Step-by-step setup instructions
- **Configuration Reference** - Detailed settings documentation
- **Troubleshooting Guide** - Common issues and solutions
- **Technical Details** - API endpoints, URL formats, data models
- **FAQ** - Frequently asked questions

See `DOCS/UNIFI_PROTECT.md` for complete documentation.

### Known Limitations

- **UniFi Protect only** - Does not support legacy UniFi Video
- **Local network** - Controller must be accessible from your Mac
- **Password storage** - Currently uses NSUserDefaults (Keychain planned)
- **Manual refresh** - No automatic camera discovery updates (requires manual refresh)

### Future Enhancements

Planned for future releases:
- macOS Keychain integration for secure password storage
- Automatic periodic camera sync
- Per-camera stream quality selection in UI
- UniFi Protect event integration
- Snapshot capture via UniFi API
- PTZ control for supported cameras
- Smart detection integration

---

## [2.1.1] - 2025-10-29

### 🆕 Configuration Export/Import System

This release adds a comprehensive configuration management system for multi-device deployments and centralized configuration.

### Added - Configuration Export/Import ⭐⭐⭐⭐⭐

#### Complete Settings Export to JSON
- Export all application settings to cross-platform JSON format
- Includes: feeds, bookmarks, API settings, monitoring features, transitions, failover, cloud storage, event logging
- Metadata included: version, export date, platform
- Human-readable JSON with pretty-printing

#### Import from Multiple Sources
- **Local file import** - Load configuration from filesystem
- **Remote URL import** - Download configuration from HTTP(S) URL
- **Merge or replace modes** - Preserve or replace existing settings
- Error handling for invalid JSON or network failures

#### Upload to Remote URL
- **POST/PUT support** - Upload to RESTful APIs
- **Configurable HTTP method** - Choose POST or PUT
- JSON content-type automatic
- Success/failure callbacks

#### Auto-Sync Feature
- **Bidirectional sync** - Download then upload configuration
- **Configurable interval** - Default: 5 minutes (300 seconds)
- **Automatic retry** - Handles temporary network failures
- **Manual sync trigger** - Force sync on-demand
- **Start/stop control** - Enable/disable auto-sync

#### Cross-Platform JSON Format
- Designed for compatibility with:
  - macOS application (current)
  - iOS app (future)
  - tvOS app (future)
  - macOS screensaver (future)
- Platform-agnostic field names
- Optional fields for platform-specific settings

### Implementation Files

- `RTSPConfigurationExporter.h/m` - Complete export/import system
- `CONFIGURATION_EXPORT.md` - Comprehensive documentation (8,000+ words)
- Updated `AppDelegate.m` - Initialize configuration exporter

### Technical Details

- **Build Status:** ✅ SUCCESS (0 errors, 0 warnings)
- **Lines of Code:** ~700+ (RTSPConfigurationExporter.m)
- **Documentation:** 8,000+ words
- **JSON Format Version:** 2.1

### Use Cases

1. **Centralized Configuration Management**
   - Deploy RTSP Rotator across multiple machines
   - All machines sync from central configuration server
   - Instant configuration updates across entire fleet

2. **Cross-Platform Sync**
   - Share configuration between macOS, iOS, tvOS, screensaver
   - Auto-sync keeps all devices in sync
   - Single source of truth for configuration

3. **Disaster Recovery**
   - Export configuration before major changes
   - Backup to cloud storage or version control
   - Quick restore from known-good configuration

4. **Configuration Templates**
   - Create standard configurations for different scenarios
   - Distribute templates to multiple users/devices
   - Company-wide or team-specific configurations

### JSON Format Example

```json
{
  "version": "2.1",
  "exportDate": "2025-10-29T12:00:00Z",
  "platform": "macOS",
  "basic": { ... },
  "feeds": [ ... ],
  "bookmarks": [ ... ],
  "api": { ... },
  "monitoring": { ... }
}
```

### API Usage

```objc
RTSPConfigurationExporter *exporter = [RTSPConfigurationExporter sharedExporter];

// Export to file
[exporter exportConfigurationToFile:nil completion:^(BOOL success, NSString *path, NSError *error) {
    NSLog(@"Exported to: %@", path);
}];

// Import from URL
[exporter importConfigurationFromURL:@"https://example.com/config.json"
                               merge:NO
                          completion:^(BOOL success, NSError *error) {
    NSLog(@"Import: %@", success ? @"✓" : @"✗");
}];

// Auto-sync
exporter.autoSyncURL = @"https://example.com/api/config";
exporter.autoSyncInterval = 300; // 5 minutes
exporter.autoSyncEnabled = YES;
[exporter startAutoSync];
```

### Documentation

- Created `CONFIGURATION_EXPORT.md` with complete documentation
- Updated `README.md` with v2.1.1 information
- Updated `CHANGELOG.md` (this file)

### Changed

- Enhanced `AppDelegate.m` to initialize RTSPConfigurationExporter
- Configuration now automatically saved to persistent storage

### Security Considerations

- **HTTPS recommended** for remote URLs (credentials in JSON)
- **API key support** for authenticated uploads
- **Sensitive data warning** - JSON includes RTSP credentials and API keys
- Encryption support planned for future release

## [2.1.0] - 2025-10-29

### 🎉 Major Feature Release - 13 New Features Implemented

This release adds 13 major new features across three implementation phases, dramatically expanding RTSP Rotator's capabilities for professional monitoring and automation.

### Added - Phase 1: Quick Wins (5 Features)

#### Feed Bookmarks & Quick Access ⭐⭐⭐⭐⭐
- Instant camera access via keyboard shortcuts (⌘1-9)
- Persistent bookmark storage
- Conflict resolution for duplicate hotkeys
- Integration with event logging
- Delegate pattern for bookmark activation

#### Custom Transition Effects ⭐⭐⭐⭐
- 11 transition types: None, Fade, Slide (4 directions), Zoom In/Out, Dissolve, Push, Cube, Flip
- Configurable duration (0.1-2.0 seconds)
- Custom timing functions
- Preview support in preferences

#### Full-Screen Mode with Overlay Controls ⭐⭐⭐⭐
- True full-screen mode (hides menu bar and dock)
- Overlay controls on mouse hover
- Configurable fade delay (1-10 seconds)
- Keyboard shortcut (⌘F) support

#### Audio Level Meters & Monitoring ⭐⭐⭐⭐
- Real-time audio level visualization
- Loud noise detection with configurable threshold
- Silence detection with duration tracking
- Peak and average level tracking
- Alert callbacks for audio events

#### Motion Detection ⭐⭐⭐⭐⭐
- Vision framework integration for motion detection
- Adjustable sensitivity (0.0-1.0)
- Configurable check interval
- Motion confidence scoring
- Start/stop motion callbacks

### Added - Phase 2: High-Impact Features (5 Features)

#### Picture-in-Picture Mode ⭐⭐⭐⭐⭐
- Floating, always-on-top PiP window
- Four corner positions with auto-snap
- Draggable and resizable
- Adjustable opacity (0.3-1.0)
- Swap with main feed support
- Multiple PiP windows supported

#### Feed Preview Thumbnails Grid ⭐⭐⭐⭐⭐
- Live thumbnail grid of all cameras
- Auto-refreshing (1-60 seconds configurable)
- Click to switch feeds
- Drag-and-drop reordering
- Health status indicators per thumbnail
- Configurable grid size and columns

#### PTZ Camera Control ⭐⭐⭐⭐
- Full Pan/Tilt/Zoom control
- ONVIF protocol support
- Preset positions (save/recall up to 10)
- Auto-tour mode between presets
- Speed control (0-100 for pan/tilt/zoom)
- Keyboard controls (arrows, +/-, 0-9)

#### HTTP REST API Server ⭐⭐⭐⭐⭐
- Complete RESTful API for remote control
- JSON responses for all endpoints
- Optional API key authentication
- Configurable port (default: 8080)
- Home automation integration support
- API endpoints for: status, feed switching, recording, snapshots, rotation interval
- Delegate pattern for request handling

#### Feed Failover & Redundancy ⭐⭐⭐⭐
- Automatic failover to backup URLs
- Multiple backup URLs per feed
- Health check monitoring (10-300 seconds)
- Automatic primary restoration
- Manual failover triggers
- Connection timeout configuration
- Retry attempts before failover (1-10)
- Delegate callbacks for failover events

### Added - Phase 3: Advanced Features (3 Features)

#### Smart Alerts with Vision Framework ⭐⭐⭐⭐⭐
- AI-powered object detection using Vision framework
- Detect: Person, Vehicle, Animal, Package
- Confidence threshold configuration (0.5-0.95)
- Configurable check interval (0.5-5.0 seconds)
- Real-time analysis of video streams
- Integration with event logging

#### Cloud Storage Integration ⭐⭐⭐
- Multi-provider support: iCloud, Dropbox, Google Drive, Amazon S3
- Automatic upload on snapshot/recording
- Configurable retention policies (days or infinite)
- Bandwidth throttling support
- Upload queue management
- Retry on failure
- File listing and deletion

#### Event Timeline & Logging ⭐⭐⭐⭐
- Comprehensive event logging system
- Event types: Feed Switch, Snapshot, Recording, Motion, Audio, Connection, Failover, Bookmark, Error
- Searchable event history
- Filter by type, date range, feed
- CSV and PDF export
- Persistent storage to disk
- Event thumbnails and metadata
- Maximum events configurable (100-10000)

### Changed - Integration & Architecture

- **AppDelegate Enhanced**
  - Added initialization methods for all 3 phases
  - Implemented 3 delegate protocols (Bookmark, API Server, Failover)
  - Added global keyboard shortcut handling
  - Added player monitor initialization
  - Integrated all features into application lifecycle

- **RTSPWallpaperController Enhanced**
  - Added `playCurrentFeed` method for API/bookmark integration
  - Exposed `player` property for monitoring features
  - Added AVFoundation import

### Technical Details

- **Build Status:** ✅ SUCCESS
- **Compilation:** 0 errors, 0 warnings
- **Files Modified:** 3 (AppDelegate.h/m, RTSPWallpaperController.h)
- **New Files:** 2 (NEW_FEATURES_V2.1.md, V2.1_IMPLEMENTATION_COMPLETE.md)
- **Lines of Code Added/Modified:** ~2,000+
- **Documentation:** 18,000+ words

### Fixed

- All compilation errors from feature integration (16 errors fixed)
- Proper method signatures for event logging
- Correct singleton accessor names
- Missing property declarations
- Delegate protocol implementations

### Keyboard Shortcuts

- ⌘1-9: Bookmark quick access
- ⌘F: Toggle full-screen
- ⌘N: Next feed
- ⌘M: Toggle mute
- ⌘,: Preferences
- Arrow Keys: PTZ control
- +/-: PTZ zoom

### API Endpoints

- GET /api/status - Current status
- GET /api/feeds - List feeds
- GET /api/current - Current feed index
- POST /api/feed/:index - Switch feed
- POST /api/next - Next feed
- POST /api/previous - Previous feed
- POST /api/snapshot - Take snapshot
- POST /api/record/start - Start recording
- POST /api/record/stop - Stop recording
- POST /api/interval/:seconds - Set rotation interval

### Documentation

- Created NEW_FEATURES_V2.1.md with comprehensive feature documentation
- Created V2.1_IMPLEMENTATION_COMPLETE.md with implementation summary
- Updated README.md with v2.1 information
- Updated CHANGELOG.md (this file)

## [2.0.0] - 2025-10-29

### 🎉 Major Release - Standard macOS Application + Multi-Dashboard System

This release represents a complete architectural transformation with multiple major changes:
1. Refactored from screensaver bundle to standard macOS application
2. Added multi-dashboard system supporting unlimited dashboards
3. Integrated Google Home/Nest camera support
4. Implemented comprehensive diagnostics and health monitoring
5. Migrated to AVFoundation (removed VLCKit dependency)
6. Achieved zero warnings build

### Changed - Breaking
- **Screensaver Bundle → Standard macOS Application (.app)**
  - Changed from `.saver` bundle to `.app` bundle
  - Now a proper macOS application with Dock icon and menu bar
  - Added standard AppDelegate and main.m entry point
  - Dual-mode RTSPWallpaperController (standalone/integrated)

- **Replaced VLCKit with AVFoundation** - No external dependencies required
  - `VLCMediaPlayer` → `AVPlayer`
  - `VLCMedia` → `AVPlayerItem`
  - `VLCMediaPlayerDelegate` → KVO/NSNotification observers
  - All RTSP playback now uses native macOS APIs
  - Better Apple Silicon optimization and performance

### Added - Multi-Dashboard System
- **RTSPDashboardManager.h/m** - Multi-dashboard management system
  - Unlimited dashboards with up to 12 cameras each
  - 5 grid layouts: 1×1, 2×2, 3×2, 3×3, 4×3
  - Dashboard auto-cycling for rotating between dashboards
  - NSCoding/NSSecureCoding persistence
  - Supports organizing 36+ cameras across multiple dashboards

- **RTSPMultiViewGrid.h/m** - Grid view display controller
  - Renders 1-12 cameras simultaneously
  - Dynamic grid layout based on camera count
  - Individual camera cell management
  - Status indicator display per camera
  - Synchronized playback across all cameras

### Added - Camera Management
- **RTSPCameraTypeManager.h/m** - Camera type management
  - Separate configuration for RTSP cameras vs Google Home cameras
  - Type-specific settings and capabilities
  - RTSP cameras: Detailed configuration (port, path, credentials, PTZ support)
  - Google Home cameras: OAuth integration, device discovery, auto-refresh

- **RTSPGoogleHomeAdapter.h/m** - Google Home camera integration
  - OAuth 2.0 authentication with Google
  - Smart Device Management API integration
  - Camera discovery and import
  - Automatic stream URL generation and refresh
  - Handles 5-minute stream expiration

### Added - Diagnostics System
- **RTSPCameraDiagnostics.h/m** - Comprehensive health monitoring
  - Connection testing for all cameras
  - Stream analysis (resolution, framerate, bitrate)
  - Network diagnostics (latency, packet loss)
  - 5-level health status system:
    - 🟢 Green: Healthy (all good)
    - 🟡 Yellow: Warning (minor issues)
    - 🔴 Red: Critical (not working)
    - 🔵 Blue: Testing (in progress)
    - ⚪ Gray: Unknown (not tested)
  - Automatic health monitoring with configurable intervals
  - Detailed diagnostic reports
  - Visual status indicators in grid view

### Added - Application Structure
- **AppDelegate.h/m** - Standard macOS application delegate
  - Manages application lifecycle
  - Creates main window with video display
  - Initializes all managers (Dashboard, CameraType, Diagnostics)
  - Loads configuration and starts playback
  - Status menu integration

- **main.m** - Standard application entry point
  - Replaces old screensaver main() function
  - Initializes NSApplication
  - Sets activation policy to regular app
  - Proper app lifecycle management

- **Info.plist** - Application property list
  - Bundle type: APPL (application, not screensaver)
  - Camera and microphone usage descriptions
  - Proper entitlements for network and camera access

### Changed - RTSPWallpaperController
- Added dual-mode operation:
  - **Standalone Mode**: Creates own window (legacy behavior)
  - **Integrated Mode**: Uses external view/window (new app mode)
- New methods:
  - `setupWithView:` - Initialize with external view
  - `setupWithWindow:` - Initialize with external window
  - `setFeeds:` - Update feeds dynamically
- Public properties:
  - `rotationInterval` - Configurable rotation time
  - `parentView` - External view for integrated mode
- Modified lifecycle methods to support both modes

### Added - Documentation
- **MULTI_DASHBOARD_GUIDE.md** - Complete multi-dashboard documentation
- **REFACTORING_SUMMARY.md** - Detailed refactoring documentation
- Updated **README.md** with all new features and architecture
- Updated **INSTALL.md** for standard app installation (no VLCKit needed)
- **MULTI_DASHBOARD_EXAMPLE.m** - Example implementation code

### Fixed - Deprecation Warnings
- Replaced deprecated `tracksWithMediaType:` with async `loadTracksWithMediaType:completionHandler:`
  - Fixed in RTSPCameraDiagnostics.m
  - Fixed in RTSPAudioMonitor.m
- Replaced deprecated NSUserNotification with UserNotifications framework
  - Updated RTSPStatusMenuController.m
  - Added modern notification authorization and delivery
- Fixed nullable parameter warnings
- Fixed unused variable warnings
- Fixed non-null parameter warnings

### Fixed - Build Errors
- Removed duplicate main() function from RTSP_RotatorView.m
- Fixed RTSPFeedMetadata property name (feedURL → url)
- Fixed RTSPPreferencesController method names
- Fixed RTSPStatusMenuController initialization
- All compilation errors resolved (0 errors, 0 warnings)

### Removed
- VLCKit framework dependency
- CocoaPods requirement
- Screensaver bundle structure
- Old main() function in RTSP_RotatorView.m
- All VLC-specific code and options
- Deprecated API usage

### Technical Details
- Build Status: ✅ **BUILD SUCCEEDED**
- Errors: 0
- Warnings: 0
- Product Type: macOS Application (.app)
- Bundle Identifier: DisneyGPT.RTSP-Rotator
- Deployment Target: macOS 10.15+
- Recommended: macOS 11.0+ for UserNotifications
- New Files Created: 11
- Files Modified: ~20
- Lines Changed: ~2000+
- Architecture: Fully modular with singleton managers

### Migration Notes
For users upgrading from v1.x:
- Application is now a standard .app instead of .saver
- No CocoaPods installation required
- Configuration migrates automatically
- New preferences UI with dashboard management
- Camera configuration separated by type
- Enable diagnostics for health monitoring

## [1.1.0] - 2025-10-29

### Added
- Comprehensive inline documentation with HeaderDoc/AppleDoc style comments
- External configuration file support (`~/rtsp_feeds.txt`)
- `loadFeedsFromFile()` function for parsing feed configuration
- Comment support in configuration files (lines starting with #)
- Proper error handling for VLC media creation
- VLCMediaPlayerDelegate implementation for state tracking
- Detailed NSLog statements throughout for debugging
- `stringForPlayerState:` helper method for readable state logging
- `dealloc` method for proper resource cleanup
- Thread-safe operations using dispatch_async
- Feed array validation (nil/empty array handling)
- Rotation interval validation (negative/zero handling)
- README.md with comprehensive documentation
- CHANGELOG.md for version tracking
- Unit test suite with 20+ test cases
- Performance tests for feed rotation and loading

### Changed
- Refactored `RTSPWallpaperController` into separate lifecycle methods:
  - `start` - Initializes and starts the application
  - `stop` - Cleans up resources
  - `setupWindow` - Window creation logic
  - `setupPlayer` - VLC player initialization
  - `startRotationTimer` - Timer setup
- Improved initialization with custom `initWithFeeds:rotationInterval:`
- Made feeds array immutable (copied on initialization)
- Enhanced `playCurrentFeed` with:
  - URL validation
  - VLCMedia creation error handling
  - RTSP-specific media options (TCP, caching)
  - Better logging
- Moved window setup to main thread explicitly
- Changed `toggleMute` to dispatch on main queue
- Set application activation policy to NSApplicationActivationPolicyAccessory
- Added black background color to window

### Fixed
- Memory leak from timer not being invalidated
- Thread safety issues with UI operations
- Missing error handling for media loading failures
- Hardcoded feed URLs (now loadable from file)
- Missing cleanup in controller destruction
- Potential crashes from invalid feed indices

### Security
- Added validation for feed URLs before playback
- Sanitized configuration file input (trim whitespace, ignore comments)

## [1.0.0] - 2025-10-10

### Added
- Initial release
- Basic RTSP feed rotation functionality
- VLCKit integration for video playback
- Desktop-level window display (kCGDesktopWindowLevel)
- 60-second automatic feed rotation
- Mute/unmute toggle via console input
- Custom RTSPWallpaperWindow class for window management
- RTSPWallpaperController for application logic
- Support for multiple RTSP streams
- Borderless fullscreen window

### Known Issues
- Hardcoded feed URLs in source code
- No error handling for network failures
- No cleanup on application termination
- Timer not invalidated (memory leak)
- No configuration file support
- Limited logging for debugging

---

## Version Comparison

### v1.0.0 vs v1.1.0

**Lines of Code:**
- v1.0.0: ~96 lines
- v1.1.0: ~311 lines (3.2x increase for robustness)

**Test Coverage:**
- v1.0.0: No tests
- v1.1.0: 20+ unit tests, 2 performance tests

**Documentation:**
- v1.0.0: Basic inline comments only
- v1.1.0: Full README, CHANGELOG, inline documentation

**Features:**
- v1.0.0: Basic rotation
- v1.1.0: + Configuration files, error handling, logging, proper cleanup

---

## Future Versions (Planned)

### [1.2.0] - Planned
- Preferences UI with NSPreferencePane
- Menu bar controls
- Multiple screen support
- Configuration file auto-reload
- Remote configuration URL support

### [1.3.0] - Planned
- Grid layout (multiple simultaneous feeds)
- Recording functionality
- Snapshot capture
- Feed health monitoring
- Auto-reconnect on stream failure

### [2.0.0] - Planned
- Swift rewrite
- SwiftUI preferences interface
- Combine framework integration
- Modern concurrency (async/await)
- App Sandbox compatibility
- Mac App Store distribution
