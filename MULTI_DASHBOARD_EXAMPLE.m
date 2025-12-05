//
//  MULTI_DASHBOARD_EXAMPLE.m
//  RTSP Rotator
//
//  Example code for setting up multi-dashboard system with 36 cameras
//

#import <Foundation/Foundation.h>
#import "RTSPDashboardManager.h"
#import "RTSPMultiViewGrid.h"
#import "RTSPGoogleHomeAdapter.h"

@interface DashboardExample : NSObject <RTSPDashboardManagerDelegate, RTSPGoogleHomeAdapterDelegate>
@property (nonatomic, strong) RTSPMultiViewGrid *gridView;
@end

@implementation DashboardExample

#pragma mark - Quick Start: 36 Cameras in 3 Dashboards

- (void)setup36CamerasExample {
    RTSPDashboardManager *manager = [RTSPDashboardManager sharedManager];
    manager.delegate = self;

    // DASHBOARD 1: External Cameras (12 cameras)
    RTSPDashboard *externalDash = [[RTSPDashboard alloc] init];
    externalDash.name = @"External Cameras";
    externalDash.layout = RTSPDashboardLayout4x3; // 4×3 grid = 12 cameras
    externalDash.showLabels = YES;
    externalDash.showTimestamp = YES;
    externalDash.rotationInterval = 10.0;

    // Add your 12 external camera URLs here
    NSArray *externalURLs = @[
        @"rtsp://192.168.1.10:554/stream1",
        @"rtsp://192.168.1.11:554/stream1",
        @"rtsp://192.168.1.12:554/stream1",
        @"rtsp://192.168.1.13:554/stream1",
        @"rtsp://192.168.1.14:554/stream1",
        @"rtsp://192.168.1.15:554/stream1",
        @"rtsp://192.168.1.16:554/stream1",
        @"rtsp://192.168.1.17:554/stream1",
        @"rtsp://192.168.1.18:554/stream1",
        @"rtsp://192.168.1.19:554/stream1",
        @"rtsp://192.168.1.20:554/stream1",
        @"rtsp://192.168.1.21:554/stream1"
    ];

    for (int i = 0; i < externalURLs.count; i++) {
        RTSPCameraConfig *camera = [[RTSPCameraConfig alloc] init];
        camera.name = [NSString stringWithFormat:@"External Cam %d", i + 1];
        camera.feedURL = [NSURL URLWithString:externalURLs[i]];
        camera.location = @"Exterior";
        camera.cameraType = @"RTSP";
        camera.username = @"admin"; // Set your camera username
        camera.password = @"password"; // Set your camera password
        camera.isMuted = YES;
        [externalDash addCamera:camera];
    }

    [manager addDashboard:externalDash];

    // DASHBOARD 2: Internal Cameras (12 cameras)
    RTSPDashboard *internalDash = [[RTSPDashboard alloc] init];
    internalDash.name = @"Internal Cameras";
    internalDash.layout = RTSPDashboardLayout4x3;
    internalDash.showLabels = YES;
    internalDash.showTimestamp = YES;

    NSArray *internalURLs = @[
        @"rtsp://192.168.1.30:554/stream1",
        @"rtsp://192.168.1.31:554/stream1",
        @"rtsp://192.168.1.32:554/stream1",
        @"rtsp://192.168.1.33:554/stream1",
        @"rtsp://192.168.1.34:554/stream1",
        @"rtsp://192.168.1.35:554/stream1",
        @"rtsp://192.168.1.36:554/stream1",
        @"rtsp://192.168.1.37:554/stream1",
        @"rtsp://192.168.1.38:554/stream1",
        @"rtsp://192.168.1.39:554/stream1",
        @"rtsp://192.168.1.40:554/stream1",
        @"rtsp://192.168.1.41:554/stream1"
    ];

    for (int i = 0; i < internalURLs.count; i++) {
        RTSPCameraConfig *camera = [[RTSPCameraConfig alloc] init];
        camera.name = [NSString stringWithFormat:@"Internal Cam %d", i + 1];
        camera.feedURL = [NSURL URLWithString:internalURLs[i]];
        camera.location = @"Interior";
        camera.cameraType = @"RTSP";
        camera.username = @"admin";
        camera.password = @"password";
        camera.isMuted = YES;
        [internalDash addCamera:camera];
    }

    [manager addDashboard:internalDash];

    // DASHBOARD 3: Additional Cameras (12 cameras)
    RTSPDashboard *additionalDash = [[RTSPDashboard alloc] init];
    additionalDash.name = @"Additional Cameras";
    additionalDash.layout = RTSPDashboardLayout4x3;
    additionalDash.showLabels = YES;
    additionalDash.showTimestamp = YES;

    NSArray *additionalURLs = @[
        @"rtsp://192.168.1.50:554/stream1",
        @"rtsp://192.168.1.51:554/stream1",
        @"rtsp://192.168.1.52:554/stream1",
        @"rtsp://192.168.1.53:554/stream1",
        @"rtsp://192.168.1.54:554/stream1",
        @"rtsp://192.168.1.55:554/stream1",
        @"rtsp://192.168.1.56:554/stream1",
        @"rtsp://192.168.1.57:554/stream1",
        @"rtsp://192.168.1.58:554/stream1",
        @"rtsp://192.168.1.59:554/stream1",
        @"rtsp://192.168.1.60:554/stream1",
        @"rtsp://192.168.1.61:554/stream1"
    ];

    for (int i = 0; i < additionalURLs.count; i++) {
        RTSPCameraConfig *camera = [[RTSPCameraConfig alloc] init];
        camera.name = [NSString stringWithFormat:@"Additional Cam %d", i + 1];
        camera.feedURL = [NSURL URLWithString:additionalURLs[i]];
        camera.cameraType = @"RTSP";
        camera.username = @"admin";
        camera.password = @"password";
        camera.isMuted = YES;
        [additionalDash addCamera:camera];
    }

    [manager addDashboard:additionalDash];

    // Activate first dashboard
    [manager activateDashboard:externalDash];

    // Setup auto-rotation between dashboards (optional)
    manager.autoCycleDashboards = YES;
    manager.dashboardCycleInterval = 300; // Switch dashboards every 5 minutes
    [manager startDashboardCycling];

    NSLog(@"Setup complete: 3 dashboards with 36 total cameras");
}

#pragma mark - Display Grid View

- (void)displayDashboardInWindow:(NSWindow *)window {
    RTSPDashboardManager *manager = [RTSPDashboardManager sharedManager];

    // Create grid view
    self.gridView = [[RTSPMultiViewGrid alloc] initWithDashboard:manager.activeDashboard];
    self.gridView.frame = window.contentView.bounds;
    self.gridView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.gridView.gridSpacing = 2.0;

    // Add to window
    [window.contentView addSubview:self.gridView];

    // Start all camera feeds
    [self.gridView startAllFeeds];

    NSLog(@"Grid view displayed with %lu cameras", self.gridView.cameraCells.count);
}

#pragma mark - Dashboard Navigation

- (void)switchToNextDashboard {
    RTSPDashboardManager *manager = [RTSPDashboardManager sharedManager];
    [manager switchToNextDashboard];

    // Update grid view
    [self.gridView stopAllFeeds];
    [self.gridView loadDashboard:manager.activeDashboard];
    [self.gridView startAllFeeds];
}

- (void)switchToPreviousDashboard {
    RTSPDashboardManager *manager = [RTSPDashboardManager sharedManager];
    [manager switchToPreviousDashboard];

    // Update grid view
    [self.gridView stopAllFeeds];
    [self.gridView loadDashboard:manager.activeDashboard];
    [self.gridView startAllFeeds];
}

- (void)switchToDashboardNamed:(NSString *)name {
    RTSPDashboardManager *manager = [RTSPDashboardManager sharedManager];

    for (RTSPDashboard *dashboard in manager.dashboards) {
        if ([dashboard.name isEqualToString:name]) {
            [manager activateDashboard:dashboard];

            // Update grid view
            [self.gridView stopAllFeeds];
            [self.gridView loadDashboard:dashboard];
            [self.gridView startAllFeeds];
            break;
        }
    }
}

#pragma mark - Google Home Integration Example

- (void)setupGoogleHomeCameras {
    RTSPGoogleHomeAdapter *adapter = [RTSPGoogleHomeAdapter sharedAdapter];
    adapter.delegate = self;

    // Configure authentication (get these from Google Cloud Console)
    adapter.authentication = [[RTSPGoogleHomeAuth alloc] init];
    adapter.authentication.clientID = @"YOUR_CLIENT_ID_HERE";
    adapter.authentication.clientSecret = @"YOUR_CLIENT_SECRET_HERE";
    adapter.authentication.projectID = @"YOUR_PROJECT_ID_HERE";

    // Authenticate
    [adapter authenticateWithCompletionHandler:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"Google Home authentication failed: %@", error);
            return;
        }

        // Discover cameras
        [adapter discoverCamerasWithCompletionHandler:^(NSArray<RTSPGoogleHomeCamera *> *cameras, NSError *error) {
            if (error) {
                NSLog(@"Camera discovery failed: %@", error);
                return;
            }

            NSLog(@"Found %lu Google Home cameras", cameras.count);

            // Create dashboard for Google Home cameras
            RTSPDashboard *googleDash = [[RTSPDashboard alloc] init];
            googleDash.name = @"Google Home Cameras";
            googleDash.layout = RTSPDashboardLayout3x3;

            // Import cameras into dashboard
            [adapter importCamerasIntoDashboard:googleDash completionHandler:^(NSInteger importedCount, NSError *error) {
                if (error) {
                    NSLog(@"Import failed: %@", error);
                    return;
                }

                NSLog(@"Imported %ld Google Home cameras", importedCount);

                // Add to dashboard manager
                [[RTSPDashboardManager sharedManager] addDashboard:googleDash];
            }];
        }];
    }];
}

#pragma mark - Advanced: Custom Grid Positioning

- (void)setupCustomGridPositions {
    RTSPDashboard *dashboard = [[RTSPDashboard alloc] init];
    dashboard.name = @"Custom Layout";
    dashboard.layout = RTSPDashboardLayout4x3;

    // Front entrance (top-left)
    RTSPCameraConfig *frontDoor = [[RTSPCameraConfig alloc] init];
    frontDoor.name = @"Front Door";
    frontDoor.feedURL = [NSURL URLWithString:@"rtsp://192.168.1.100/stream"];
    frontDoor.gridRow = 0;
    frontDoor.gridColumn = 0;
    [dashboard addCamera:frontDoor];

    // Back entrance (top-right)
    RTSPCameraConfig *backDoor = [[RTSPCameraConfig alloc] init];
    backDoor.name = @"Back Door";
    backDoor.feedURL = [NSURL URLWithString:@"rtsp://192.168.1.101/stream"];
    backDoor.gridRow = 0;
    backDoor.gridColumn = 3;
    [dashboard addCamera:backDoor];

    // Driveway (bottom-left)
    RTSPCameraConfig *driveway = [[RTSPCameraConfig alloc] init];
    driveway.name = @"Driveway";
    driveway.feedURL = [NSURL URLWithString:@"rtsp://192.168.1.102/stream"];
    driveway.gridRow = 2;
    driveway.gridColumn = 0;
    [dashboard addCamera:driveway];

    // Add remaining cameras...
}

#pragma mark - Dashboard Manager Delegate

- (void)dashboardManager:(RTSPDashboardManager *)manager didActivateDashboard:(RTSPDashboard *)dashboard {
    NSLog(@"Dashboard activated: %@", dashboard.name);

    // Update UI
    [self.gridView loadDashboard:dashboard];
    [self.gridView startAllFeeds];
}

- (void)dashboardManager:(RTSPDashboardManager *)manager didDeactivateDashboard:(RTSPDashboard *)dashboard {
    NSLog(@"Dashboard deactivated: %@", dashboard.name);

    // Stop feeds to save resources
    [self.gridView stopAllFeeds];
}

#pragma mark - Google Home Adapter Delegate

- (void)googleHomeAdapter:(RTSPGoogleHomeAdapter *)adapter didAuthenticateSuccessfully:(RTSPGoogleHomeAuth *)auth {
    NSLog(@"Google Home authenticated successfully");
}

- (void)googleHomeAdapter:(RTSPGoogleHomeAdapter *)adapter authenticationFailedWithError:(NSError *)error {
    NSLog(@"Google Home authentication failed: %@", error);
}

- (void)googleHomeAdapter:(RTSPGoogleHomeAdapter *)adapter didDiscoverCameras:(NSArray<RTSPGoogleHomeCamera *> *)cameras {
    NSLog(@"Discovered %lu Google Home cameras:", cameras.count);
    for (RTSPGoogleHomeCamera *camera in cameras) {
        NSLog(@"  - %@ (%@)", camera.displayName, camera.deviceType);
    }
}

#pragma mark - Performance Optimization

- (void)optimizeFor36Cameras {
    // 1. Use staggered loading
    RTSPDashboard *dashboard = [RTSPDashboardManager sharedManager].activeDashboard;
    dashboard.syncPlayback = NO; // Load cameras sequentially

    // 2. Lower quality for grid view
    for (RTSPCameraConfig *camera in dashboard.cameras) {
        camera.customSettings = @{
            @"resolution": @"720p",    // Lower than 1080p
            @"framerate": @"15",       // Lower than 30fps
            @"bitrate": @"2000"        // 2 Mbps per stream
        };
    }

    // 3. Use auto-rotation to reduce memory
    RTSPDashboardManager *manager = [RTSPDashboardManager sharedManager];
    manager.dashboardCycleInterval = 300; // 5 minutes per dashboard
    [manager startDashboardCycling];
}

@end

/*
 * USAGE INSTRUCTIONS:
 *
 * 1. Update the camera URLs in setup36CamerasExample with your actual RTSP URLs
 * 2. Set correct usernames and passwords for your cameras
 * 3. Call setup36CamerasExample from your app delegate or view controller
 * 4. Call displayDashboardInWindow to show the grid view
 * 5. Use switchToNextDashboard/switchToPreviousDashboard for navigation
 *
 * For Google Home:
 * 1. Get credentials from Google Cloud Console and Device Access Console
 * 2. Update setupGoogleHomeCameras with your credentials
 * 3. Call setupGoogleHomeCameras to authenticate and import cameras
 *
 * Network Requirements:
 * - Gigabit ethernet recommended (1000 Mbps)
 * - Estimated bandwidth: 48-96 Mbps for 12 simultaneous 1080p streams
 * - Consider using 720p @ 15fps for better performance (24-48 Mbps)
 *
 * Hardware Requirements:
 * - 16GB RAM recommended for 36 cameras
 * - Dedicated GPU for hardware video decoding
 * - macOS 11.0 or later
 */
