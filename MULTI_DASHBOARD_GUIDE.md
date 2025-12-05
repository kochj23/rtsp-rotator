# Multi-Dashboard System Implementation Guide

## Overview

The RTSP Rotator now supports **multiple customizable dashboards** with up to **12 cameras per dashboard**. You can organize your 36 cameras across 3 dashboards (External, Internal, Additional) or create any custom configuration you need.

## Key Features

### 1. Dashboard Management
- **Unlimited dashboards** (recommended: 3-5 for optimal performance)
- **12 cameras maximum per dashboard** (4x3 grid)
- **Customizable layouts**: 1x1, 2x2, 3x2, 3x3, 4x3
- **Auto-rotation** between dashboards
- **Individual dashboard settings** (labels, timestamps, rotation interval)

### 2. Grid Layouts

| Layout | Cameras | Grid Size | Best For |
|--------|---------|-----------|----------|
| 1x1    | 1       | Full screen | Single focus camera |
| 2x2    | 4       | 2×2 grid | Small setup |
| 3x2    | 6       | 3×2 grid | Medium setup |
| 3x3    | 9       | 3×3 grid | Standard security |
| 4x3    | 12      | 4×3 grid | Maximum cameras |

### 3. Camera Configuration
Each camera supports:
- **Name and location** labels
- **Authentication** (username/password for RTSP)
- **Mute control**
- **Grid positioning** (fixed or auto)
- **Custom settings** (per-camera metadata)

### 4. Google Home Integration
- **Nest cameras** support
- **OAuth 2.0** authentication
- **Live streaming** (RTSP)
- **Snapshot capture**
- **Automatic discovery**

## Setup for 36 Cameras

### Option 1: Three 12-Camera Dashboards (Recommended)

```objc
// Initialize dashboard manager
RTSPDashboardManager *manager = [RTSPDashboardManager sharedManager];

// Dashboard 1: External Cameras (12)
RTSPDashboard *externalDash = [[RTSPDashboard alloc] init];
externalDash.name = @"External Cameras";
externalDash.layout = RTSPDashboardLayout4x3; // 4×3 = 12 cameras
externalDash.showLabels = YES;
externalDash.showTimestamp = YES;

// Add 12 external cameras
for (int i = 1; i <= 12; i++) {
    RTSPCameraConfig *camera = [[RTSPCameraConfig alloc] init];
    camera.name = [NSString stringWithFormat:@"External %d", i];
    camera.feedURL = [NSURL URLWithString:@"rtsp://192.168.1.x/stream"];
    camera.location = @"Exterior";
    [externalDash addCamera:camera];
}

[manager addDashboard:externalDash];

// Dashboard 2: Internal Cameras (12)
RTSPDashboard *internalDash = [[RTSPDashboard alloc] init];
internalDash.name = @"Internal Cameras";
internalDash.layout = RTSPDashboardLayout4x3;

for (int i = 1; i <= 12; i++) {
    RTSPCameraConfig *camera = [[RTSPCameraConfig alloc] init];
    camera.name = [NSString stringWithFormat:@"Internal %d", i];
    camera.feedURL = [NSURL URLWithString:@"rtsp://192.168.1.y/stream"];
    camera.location = @"Interior";
    [internalDash addCamera:camera];
}

[manager addDashboard:internalDash];

// Dashboard 3: Additional Cameras (12)
RTSPDashboard *additionalDash = [[RTSPDashboard alloc] init];
additionalDash.name = @"Additional Cameras";
additionalDash.layout = RTSPDashboardLayout4x3;

for (int i = 1; i <= 12; i++) {
    RTSPCameraConfig *camera = [[RTSPCameraConfig alloc] init];
    camera.name = [NSString stringWithFormat:@"Additional %d", i];
    camera.feedURL = [NSURL URLWithString:@"rtsp://192.168.1.z/stream"];
    [additionalDash addCamera:camera];
}

[manager addDashboard:additionalDash];

// Activate first dashboard
[manager activateDashboard:externalDash];

// Optional: Auto-cycle between dashboards every 5 minutes
manager.autoCycleDashboards = YES;
manager.dashboardCycleInterval = 300; // 5 minutes
[manager startDashboardCycling];
```

### Option 2: Flexible Layout (Mixed Grid Sizes)

```objc
// Dashboard 1: Priority Cameras (9 cameras in 3×3)
RTSPDashboard *priorityDash = [[RTSPDashboard alloc] init];
priorityDash.name = @"Priority Cameras";
priorityDash.layout = RTSPDashboardLayout3x3;
// Add 9 cameras...

// Dashboard 2: Front Entrance (4 cameras in 2×2)
RTSPDashboard *frontDash = [[RTSPDashboard alloc] init];
frontDash.name = @"Front Entrance";
frontDash.layout = RTSPDashboardLayout2x2;
// Add 4 cameras...

// Dashboard 3: Main Floor (12 cameras in 4×3)
RTSPDashboard *mainFloorDash = [[RTSPDashboard alloc] init];
mainFloorDash.name = @"Main Floor";
mainFloorDash.layout = RTSPDashboardLayout4x3;
// Add 12 cameras...

// Dashboard 4: Upper Floor (11 cameras in 4×3)
RTSPDashboard *upperFloorDash = [[RTSPDashboard alloc] init];
upperFloorDash.name = @"Upper Floor";
upperFloorDash.layout = RTSPDashboardLayout4x3;
// Add 11 cameras...
// Total: 9 + 4 + 12 + 11 = 36 cameras
```

## Using Multi-View Grid

```objc
// Create grid view for dashboard
RTSPMultiViewGrid *gridView = [[RTSPMultiViewGrid alloc] initWithDashboard:externalDash];
gridView.frame = windowFrame;
gridView.gridSpacing = 2.0; // pixels between cameras

// Add to window
[window.contentView addSubview:gridView];

// Start all camera feeds
[gridView startAllFeeds];

// Switch dashboards
[gridView loadDashboard:internalDash];

// Refresh specific camera
[gridView refreshCameraAtIndex:5];

// Stop all feeds
[gridView stopAllFeeds];
```

## Google Home Camera Integration

### Setup Authentication

1. **Create Google Cloud Project**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create new project
   - Enable "Smart Device Management API"
   - Create OAuth 2.0 credentials (Desktop app)
   - Note your Client ID and Client Secret

2. **Configure Device Access**
   - Go to [Device Access Console](https://console.nest.google.com/device-access/)
   - Create a new project ($5 one-time fee)
   - Note your Project ID

3. **Authenticate in App**

```objc
RTSPGoogleHomeAdapter *adapter = [RTSPGoogleHomeAdapter sharedAdapter];

// Set credentials
adapter.authentication = [[RTSPGoogleHomeAuth alloc] init];
adapter.authentication.clientID = @"YOUR_CLIENT_ID";
adapter.authentication.clientSecret = @"YOUR_CLIENT_SECRET";
adapter.authentication.projectID = @"YOUR_PROJECT_ID";

// Authenticate (opens browser for OAuth)
[adapter authenticateWithCompletionHandler:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"Authenticated successfully!");
    }
}];
```

### Discover and Import Google Home Cameras

```objc
// Discover cameras
[adapter discoverCamerasWithCompletionHandler:^(NSArray<RTSPGoogleHomeCamera *> *cameras, NSError *error) {
    if (error) {
        NSLog(@"Discovery failed: %@", error);
        return;
    }

    NSLog(@"Found %lu cameras", cameras.count);

    // Import into dashboard
    RTSPDashboard *nestDash = [[RTSPDashboard alloc] init];
    nestDash.name = @"Google Home Cameras";
    nestDash.layout = RTSPDashboardLayout3x3;

    [adapter importCamerasIntoDashboard:nestDash completionHandler:^(NSInteger importedCount, NSError *error) {
        NSLog(@"Imported %ld cameras", importedCount);

        // Add to manager
        [[RTSPDashboardManager sharedManager] addDashboard:nestDash];
    }];
}];
```

### Manual Camera Import

```objc
// Convert Google Home cameras to standard configs
NSArray<RTSPCameraConfig *> *configs = [adapter convertCamerasToConfigs:cameras];

for (RTSPCameraConfig *config in configs) {
    [dashboard addCamera:config];
}
```

## Performance Considerations for 36 Cameras

### 1. Network Bandwidth

**Calculation:**
- Each 1080p RTSP stream: ~4-8 Mbps
- 12 simultaneous streams: 48-96 Mbps
- Recommended: Gigabit ethernet (1000 Mbps)

**Optimization:**
```objc
// Use lower resolution for grid view
camera.customSettings = @{
    @"resolution": @"720p",  // Instead of 1080p
    @"framerate": @"15"      // Instead of 30fps
};

// Stagger feed loading
dashboard.syncPlayback = NO; // Load sequentially with 200ms delay
```

### 2. CPU/GPU Usage

**Tips:**
- Use **hardware-accelerated decoding** (AVFoundation does this automatically)
- Limit to **1-2 active dashboards** at a time
- Use **auto-rotation** instead of showing all 36 simultaneously
- Consider **lower framerates** (15fps vs 30fps)

### 3. Memory Usage

**Estimated:**
- Each camera feed: ~50-100 MB
- 12 cameras: ~600-1200 MB
- 36 cameras (all loaded): ~1.8-3.6 GB

**Recommendation:**
- Keep only **active dashboard loaded** in memory
- Use **dashboard cycling** (5-10 minute intervals)
- **Stop feeds** when switching dashboards

```objc
// Efficient dashboard switching
- (void)switchToDashboard:(RTSPDashboard *)newDashboard {
    // Stop current dashboard feeds
    [currentGridView stopAllFeeds];

    // Load new dashboard
    [currentGridView loadDashboard:newDashboard];
    [currentGridView startAllFeeds];

    // Update manager
    [[RTSPDashboardManager sharedManager] activateDashboard:newDashboard];
}
```

## Dashboard Controls

### Keyboard Shortcuts (Recommended)

```objc
// In your view controller
- (void)keyDown:(NSEvent *)event {
    switch (event.keyCode) {
        case 124: // Right arrow
            [[RTSPDashboardManager sharedManager] switchToNextDashboard];
            break;
        case 123: // Left arrow
            [[RTSPDashboardManager sharedManager] switchToPreviousDashboard];
            break;
        case 49: // Spacebar
            [self toggleDashboardCycling];
            break;
    }
}
```

### Menu Items

```objc
// Create dashboard menu
NSMenu *dashboardMenu = [[NSMenu alloc] initWithTitle:@"Dashboards"];

for (RTSPDashboard *dashboard in manager.dashboards) {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:dashboard.name
                                                  action:@selector(selectDashboard:)
                                           keyEquivalent:@""];
    item.representedObject = dashboard;
    [dashboardMenu addItem:item];
}

- (void)selectDashboard:(NSMenuItem *)sender {
    RTSPDashboard *dashboard = sender.representedObject;
    [[RTSPDashboardManager sharedManager] activateDashboard:dashboard];
}
```

## Persistence

All dashboards are automatically saved to:
```
~/Library/Application Support/RTSP Rotator/dashboards.dat
```

Google Home authentication:
```
~/Library/Application Support/RTSP Rotator/googlehome_auth.dat
```

## API Reference

### RTSPDashboardManager

```objc
// Dashboard management
- (NSArray<RTSPDashboard *> *)dashboards;
- (void)addDashboard:(RTSPDashboard *)dashboard;
- (void)removeDashboard:(RTSPDashboard *)dashboard;
- (void)activateDashboard:(RTSPDashboard *)dashboard;

// Navigation
- (void)switchToNextDashboard;
- (void)switchToPreviousDashboard;

// Auto-cycling
- (void)startDashboardCycling;
- (void)stopDashboardCycling;
@property (nonatomic, assign) NSTimeInterval dashboardCycleInterval;

// Persistence
- (BOOL)saveDashboards;
- (BOOL)loadDashboards;
```

### RTSPDashboard

```objc
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) RTSPDashboardLayout layout;
@property (nonatomic, strong) NSArray<RTSPCameraConfig *> *cameras;
@property (nonatomic, assign) BOOL showLabels;
@property (nonatomic, assign) BOOL showTimestamp;
@property (nonatomic, assign) BOOL syncPlayback;

- (void)addCamera:(RTSPCameraConfig *)camera;
- (void)removeCamera:(RTSPCameraConfig *)camera;
- (BOOL)canAddMoreCameras;
- (NSInteger)maxCamerasForLayout;
```

### RTSPCameraConfig

```objc
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSURL *feedURL;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *cameraType;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL isMuted;
```

### RTSPMultiViewGrid

```objc
- (instancetype)initWithDashboard:(RTSPDashboard *)dashboard;
- (void)loadDashboard:(RTSPDashboard *)dashboard;
- (void)startAllFeeds;
- (void)stopAllFeeds;
- (void)refreshCameraAtIndex:(NSInteger)index;
- (void)refreshAllCameras;
- (RTSPCameraCell *)cellAtRow:(NSInteger)row column:(NSInteger)column;
```

## Troubleshooting

### Issue: Feeds not loading
**Solution:**
1. Check network connectivity
2. Verify RTSP URLs are correct
3. Check camera authentication
4. Review logs for specific errors

### Issue: Performance degradation with 12+ cameras
**Solution:**
1. Lower resolution/framerate
2. Use hardware-accelerated players
3. Check network bandwidth
4. Ensure Mac meets minimum specs (16GB RAM recommended)

### Issue: Google Home cameras not appearing
**Solution:**
1. Verify OAuth credentials
2. Check Device Access project status
3. Ensure cameras are online in Google Home app
4. Check API quotas in Google Cloud Console

### Issue: Dashboard not saving
**Solution:**
1. Check file permissions in ~/Library/Application Support
2. Verify disk space
3. Review console for error messages

## Example: Complete 36-Camera Setup

```objc
- (void)setupComplete36CameraSystem {
    RTSPDashboardManager *manager = [RTSPDashboardManager sharedManager];

    // External cameras (12)
    RTSPDashboard *external = [self createDashboard:@"External"
                                           cameras:@[
        @"rtsp://192.168.1.10/stream",
        @"rtsp://192.168.1.11/stream",
        // ... 12 total
    ]];

    // Internal cameras (12)
    RTSPDashboard *internal = [self createDashboard:@"Internal"
                                           cameras:@[
        @"rtsp://192.168.1.20/stream",
        @"rtsp://192.168.1.21/stream",
        // ... 12 total
    ]];

    // Additional cameras (12)
    RTSPDashboard *additional = [self createDashboard:@"Additional"
                                             cameras:@[
        @"rtsp://192.168.1.30/stream",
        @"rtsp://192.168.1.31/stream",
        // ... 12 total
    ]];

    [manager addDashboard:external];
    [manager addDashboard:internal];
    [manager addDashboard:additional];

    // Setup auto-rotation
    manager.dashboardCycleInterval = 300; // 5 minutes
    [manager startDashboardCycling];

    // Activate first dashboard
    [manager activateDashboard:external];
}

- (RTSPDashboard *)createDashboard:(NSString *)name cameras:(NSArray<NSString *> *)urls {
    RTSPDashboard *dashboard = [[RTSPDashboard alloc] init];
    dashboard.name = name;
    dashboard.layout = RTSPDashboardLayout4x3;
    dashboard.showLabels = YES;
    dashboard.showTimestamp = YES;

    for (NSInteger i = 0; i < urls.count; i++) {
        RTSPCameraConfig *camera = [[RTSPCameraConfig alloc] init];
        camera.name = [NSString stringWithFormat:@"%@ Camera %ld", name, i + 1];
        camera.feedURL = [NSURL URLWithString:urls[i]];
        [dashboard addCamera:camera];
    }

    return dashboard;
}
```

## Next Steps

1. **Build and test** the new multi-dashboard system
2. **Configure your 36 cameras** into appropriate dashboards
3. **Set up Google Home integration** (if using Nest cameras)
4. **Optimize performance** based on your hardware
5. **Customize layouts** to match your security monitoring needs

The system is designed to scale from a few cameras to 50+ with proper configuration. Start with 3 dashboards of 12 cameras each and adjust based on your needs!
