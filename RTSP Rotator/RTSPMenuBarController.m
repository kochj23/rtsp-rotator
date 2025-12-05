//
//  RTSPMenuBarController.m
//  RTSP Rotator
//
//  Comprehensive menu bar controller for all application features
//

#import "RTSPMenuBarController.h"
#import "RTSPWallpaperController.h"
#import "RTSPUniFiProtectAdapter.h"
#import "RTSPDashboardManager.h"
#import "RTSPCameraTypeManager.h"
#import "RTSPPreferencesController.h"
#import "RTSPCameraDiagnostics.h"
#import "RTSPConfigurationExporter.h"

@implementation RTSPMenuBarController

- (instancetype)initWithWallpaperController:(RTSPWallpaperController *)controller window:(NSWindow *)window {
    self = [super init];
    if (self) {
        _wallpaperController = controller;
        _mainWindow = window;
    }
    return self;
}

#pragma mark - Helper Methods

- (NSMenuItem *)menuItem:(NSString *)title action:(SEL)action key:(NSString *)key {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:key];
    item.target = self;
    return item;
}

- (NSMenuItem *)menuItem:(NSString *)title action:(SEL)action key:(NSString *)key target:(id)target {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:key];
    item.target = target;
    return item;
}

- (void)setupApplicationMenus {
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"Main Menu"];

    // 1. Application Menu (RTSP Rotator)
    [mainMenu addItem:[self createApplicationMenu]];

    // 2. File Menu
    [mainMenu addItem:[self createFileMenu]];

    // 3. Google Home Cameras Menu

    // 4. UniFi Protect Menu
    [mainMenu addItem:[self createUniFiProtectMenu]];

    // 5. RTSP Cameras Menu
    [mainMenu addItem:[self createRTSPCamerasMenu]];

    // 6. Dashboard Menu
    [mainMenu addItem:[self createDashboardMenu]];

    // 7. Settings Menu
    [mainMenu addItem:[self createSettingsMenu]];

    // 8. View Menu
    [mainMenu addItem:[self createViewMenu]];

    // 9. Window Menu
    [mainMenu addItem:[self createWindowMenu]];

    // 10. Help Menu
    [mainMenu addItem:[self createHelpMenu]];

    [NSApp setMainMenu:mainMenu];
}

#pragma mark - Application Menu

- (NSMenuItem *)createApplicationMenu {
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"RTSP Rotator"];

    // About
    NSMenuItem *aboutItem = [[NSMenuItem alloc] initWithTitle:@"About RTSP Rotator"
                                                       action:@selector(orderFrontStandardAboutPanel:)
                                                keyEquivalent:@""];
    aboutItem.target = NSApp;
    [appMenu addItem:aboutItem];

    [appMenu addItem:[NSMenuItem separatorItem]];

    // Preferences
    NSMenuItem *prefsItem = [[NSMenuItem alloc] initWithTitle:@"Preferences..."
                                                       action:@selector(showPreferences:)
                                                keyEquivalent:@","];
    prefsItem.target = self;
    [appMenu addItem:prefsItem];

    [appMenu addItem:[NSMenuItem separatorItem]];

    // Services
    NSMenuItem *servicesItem = [[NSMenuItem alloc] initWithTitle:@"Services" action:nil keyEquivalent:@""];
    NSMenu *servicesMenu = [[NSMenu alloc] init];
    servicesItem.submenu = servicesMenu;
    [NSApp setServicesMenu:servicesMenu];
    [appMenu addItem:servicesItem];

    [appMenu addItem:[NSMenuItem separatorItem]];

    // Hide/Show
    [appMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Hide RTSP Rotator"
                                                action:@selector(hide:)
                                         keyEquivalent:@"h"]];

    NSMenuItem *hideOthersItem = [[NSMenuItem alloc] initWithTitle:@"Hide Others"
                                                            action:@selector(hideOtherApplications:)
                                                     keyEquivalent:@"h"];
    hideOthersItem.keyEquivalentModifierMask = NSEventModifierFlagOption | NSEventModifierFlagCommand;
    [appMenu addItem:hideOthersItem];

    [appMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Show All"
                                                action:@selector(unhideAllApplications:)
                                         keyEquivalent:@""]];

    [appMenu addItem:[NSMenuItem separatorItem]];

    // Quit
    [appMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Quit RTSP Rotator"
                                                action:@selector(terminate:)
                                         keyEquivalent:@"q"]];

    appMenuItem.submenu = appMenu;
    return appMenuItem;
}

#pragma mark - File Menu

- (NSMenuItem *)createFileMenu {
    NSMenuItem *fileMenuItem = [[NSMenuItem alloc] init];
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];

    // Import Configuration
    [fileMenu addItem:[self menuItem:@"Import Configuration..." action:@selector(importConfiguration:) key:@"i"]];

    // Export Configuration
    [fileMenu addItem:[self menuItem:@"Export Configuration..." action:@selector(exportConfiguration:) key:@"e"]];

    [fileMenu addItem:[NSMenuItem separatorItem]];

    // Import Cameras from File
    [fileMenu addItem:[self menuItem:@"Import Cameras from CSV..." action:@selector(importCamerasFromFile:) key:@""]];

    [fileMenu addItem:[NSMenuItem separatorItem]];

    // Close Window
    NSMenuItem *closeItem = [self menuItem:@"Close Window" action:@selector(performClose:) key:@"w" target:self.mainWindow];
    [fileMenu addItem:closeItem];

    fileMenuItem.submenu = fileMenu;
    return fileMenuItem;
}

#pragma mark - Google Home Cameras Menu


#pragma mark - UniFi Protect Menu

- (NSMenuItem *)createUniFiProtectMenu {
    NSMenuItem *unifiMenuItem = [[NSMenuItem alloc] init];
    NSMenu *unifiMenu = [[NSMenu alloc] initWithTitle:@"UniFi Protect"];

    // Connect to Controller
    [unifiMenu addItem:[self menuItem:@"Connect to Controller..."
                               action:@selector(connectUniFiProtect:)
                                  key:@""]];

    [unifiMenu addItem:[NSMenuItem separatorItem]];

    // Discover Cameras
    [unifiMenu addItem:[self menuItem:@"Discover Cameras"
                               action:@selector(discoverUniFiCameras:)
                                  key:@""]];

    // Import All Cameras
    [unifiMenu addItem:[self menuItem:@"Import All Cameras"
                               action:@selector(importAllUniFiCameras:)
                                  key:@""]];

    [unifiMenu addItem:[NSMenuItem separatorItem]];

    // Add Camera Manually
    [unifiMenu addItem:[self menuItem:@"Add Camera Manually..."
                               action:@selector(addUniFiCamera:)
                                  key:@""]];

    // Manage Cameras
    [unifiMenu addItem:[self menuItem:@"Manage Cameras..."
                               action:@selector(manageUniFiCameras:)
                                  key:@""]];

    [unifiMenu addItem:[NSMenuItem separatorItem]];

    // Test Connection
    [unifiMenu addItem:[self menuItem:@"Test All Connections"
                               action:@selector(testUniFiCameras:)
                                  key:@""]];

    // Refresh Status
    [unifiMenu addItem:[self menuItem:@"Refresh Status"
                               action:@selector(refreshUniFiStatus:)
                                  key:@""]];

    [unifiMenu addItem:[NSMenuItem separatorItem]];

    // UniFi Protect Settings
    [unifiMenu addItem:[self menuItem:@"UniFi Protect Settings..."
                               action:@selector(showUniFiSettings:)
                                  key:@""]];

    unifiMenuItem.submenu = unifiMenu;
    return unifiMenuItem;
}

#pragma mark - RTSP Cameras Menu

- (NSMenuItem *)createRTSPCamerasMenu {
    NSMenuItem *rtspMenuItem = [[NSMenuItem alloc] init];
    NSMenu *rtspMenu = [[NSMenu alloc] initWithTitle:@"RTSP Cameras"];

    // Add Camera
    [rtspMenu addItem:[self menuItem:@"Add Camera..."
                              action:@selector(addRTSPCamera:)
                                 key:@"n"]];

    // Add Multiple Cameras
    [rtspMenu addItem:[self menuItem:@"Add Multiple Cameras..."
                              action:@selector(addMultipleRTSPCameras:)
                                 key:@""]];

    [rtspMenu addItem:[NSMenuItem separatorItem]];

    // Manage Cameras
    [rtspMenu addItem:[self menuItem:@"Manage Cameras..."
                              action:@selector(manageRTSPCameras:)
                                 key:@"m"]];

    // Edit Camera
    [rtspMenu addItem:[self menuItem:@"Edit Current Camera..."
                              action:@selector(editCurrentRTSPCamera:)
                                 key:@""]];

    // Remove Camera
    [rtspMenu addItem:[self menuItem:@"Remove Current Camera"
                              action:@selector(removeCurrentRTSPCamera:)
                                 key:@""]];

    [rtspMenu addItem:[NSMenuItem separatorItem]];

    // Test Current Camera
    [rtspMenu addItem:[self menuItem:@"Test Current Camera"
                              action:@selector(testCurrentRTSPCamera:)
                                 key:@"t"]];

    // Test All Cameras
    [rtspMenu addItem:[self menuItem:@"Test All Cameras"
                              action:@selector(testAllRTSPCameras:)
                                 key:@""]];

    [rtspMenu addItem:[NSMenuItem separatorItem]];

    // Camera Diagnostics
    [rtspMenu addItem:[self menuItem:@"Camera Diagnostics..."
                              action:@selector(showRTSPDiagnostics:)
                                 key:@"d"]];

    // Camera Presets
    NSMenuItem *presetsItem = [[NSMenuItem alloc] initWithTitle:@"Camera Presets" action:nil keyEquivalent:@""];
    NSMenu *presetsMenu = [[NSMenu alloc] init];
    [presetsMenu addItem:[self menuItem:@"Hikvision Cameras" action:@selector(addHikvisionPreset:) key:@""]];
    [presetsMenu addItem:[self menuItem:@"Dahua Cameras" action:@selector(addDahuaPreset:) key:@""]];
    [presetsMenu addItem:[self menuItem:@"Axis Cameras" action:@selector(addAxisPreset:) key:@""]];
    [presetsMenu addItem:[self menuItem:@"Amcrest Cameras" action:@selector(addAmcrestPreset:) key:@""]];
    [presetsMenu addItem:[self menuItem:@"Reolink Cameras" action:@selector(addReolinkPreset:) key:@""]];
    presetsItem.submenu = presetsMenu;
    [rtspMenu addItem:presetsItem];

    rtspMenuItem.submenu = rtspMenu;
    return rtspMenuItem;
}

#pragma mark - Dashboard Menu

- (NSMenuItem *)createDashboardMenu {
    NSMenuItem *dashboardMenuItem = [[NSMenuItem alloc] init];
    NSMenu *dashboardMenu = [[NSMenu alloc] initWithTitle:@"Dashboards"];

    // Dashboard Designer
    [dashboardMenu addItem:[self menuItem:@"Dashboard Designer..."
                                   action:@selector(openDashboardDesigner:)
                                      key:@"b"]];

    [dashboardMenu addItem:[NSMenuItem separatorItem]];

    // New Dashboard
    [dashboardMenu addItem:[self menuItem:@"New Dashboard..."
                                   action:@selector(createNewDashboard:)
                                      key:@""]];

    // Duplicate Current Dashboard
    [dashboardMenu addItem:[self menuItem:@"Duplicate Current Dashboard"
                                   action:@selector(duplicateCurrentDashboard:)
                                      key:@""]];

    // Rename Dashboard
    [dashboardMenu addItem:[self menuItem:@"Rename Current Dashboard..."
                                   action:@selector(renameCurrentDashboard:)
                                      key:@""]];

    // Delete Dashboard
    [dashboardMenu addItem:[self menuItem:@"Delete Current Dashboard"
                                   action:@selector(deleteCurrentDashboard:)
                                      key:@""]];

    [dashboardMenu addItem:[NSMenuItem separatorItem]];

    // Assign Cameras
    [dashboardMenu addItem:[self menuItem:@"Assign Cameras to Dashboard..."
                                   action:@selector(assignCamerasToDashboard:)
                                      key:@""]];

    // Dashboard Layout
    NSMenuItem *layoutItem = [[NSMenuItem alloc] initWithTitle:@"Layout" action:nil keyEquivalent:@""];
    NSMenu *layoutMenu = [[NSMenu alloc] init];
    [layoutMenu addItem:[self menuItem:@"Single Camera (1×1)" action:@selector(setDashboardLayout1x1:) key:@"1"]];
    [layoutMenu addItem:[self menuItem:@"2×2 Grid (4 Cameras)" action:@selector(setDashboardLayout2x2:) key:@"2"]];
    [layoutMenu addItem:[self menuItem:@"3×2 Grid (6 Cameras)" action:@selector(setDashboardLayout3x2:) key:@"3"]];
    [layoutMenu addItem:[self menuItem:@"3×3 Grid (9 Cameras)" action:@selector(setDashboardLayout3x3:) key:@"4"]];
    [layoutMenu addItem:[self menuItem:@"4×3 Grid (12 Cameras)" action:@selector(setDashboardLayout4x3:) key:@"5"]];
    layoutItem.submenu = layoutMenu;
    [dashboardMenu addItem:layoutItem];

    [dashboardMenu addItem:[NSMenuItem separatorItem]];

    // Switch Dashboard (will be populated dynamically)
    NSMenuItem *switchItem = [[NSMenuItem alloc] initWithTitle:@"Switch Dashboard" action:nil keyEquivalent:@""];
    NSMenu *switchMenu = [[NSMenu alloc] init];
    [self populateDashboardSwitchMenu:switchMenu];
    switchItem.submenu = switchMenu;
    [dashboardMenu addItem:switchItem];

    [dashboardMenu addItem:[NSMenuItem separatorItem]];

    // Auto-Cycle Dashboards
    [dashboardMenu addItem:[self menuItem:@"Auto-Cycle Dashboards"
                                   action:@selector(toggleDashboardAutoCycle:)
                                      key:@""]];

    // Auto-Cycle Interval
    [dashboardMenu addItem:[self menuItem:@"Set Auto-Cycle Interval..."
                                   action:@selector(setDashboardCycleInterval:)
                                      key:@""]];

    dashboardMenuItem.submenu = dashboardMenu;
    return dashboardMenuItem;
}

#pragma mark - Settings Menu

- (NSMenuItem *)createSettingsMenu {
    NSMenuItem *settingsMenuItem = [[NSMenuItem alloc] init];
    NSMenu *settingsMenu = [[NSMenu alloc] initWithTitle:@"Settings"];

    // Rotation Settings
    NSMenuItem *rotationItem = [[NSMenuItem alloc] initWithTitle:@"Rotation" action:nil keyEquivalent:@""];
    NSMenu *rotationMenu = [[NSMenu alloc] init];

    [rotationMenu addItem:[self menuItem:@"Set Rotation Interval..."
                                  action:@selector(setRotationInterval:)
                                     key:@""]];
    [rotationMenu addItem:[NSMenuItem separatorItem]];
    [rotationMenu addItem:[self menuItem:@"10 seconds" action:@selector(setRotationInterval10:) key:@""]];
    [rotationMenu addItem:[self menuItem:@"30 seconds" action:@selector(setRotationInterval30:) key:@""]];
    [rotationMenu addItem:[self menuItem:@"60 seconds" action:@selector(setRotationInterval60:) key:@""]];
    [rotationMenu addItem:[self menuItem:@"2 minutes" action:@selector(setRotationInterval120:) key:@""]];
    [rotationMenu addItem:[self menuItem:@"5 minutes" action:@selector(setRotationInterval300:) key:@""]];
    [rotationMenu addItem:[NSMenuItem separatorItem]];
    [rotationMenu addItem:[self menuItem:@"Pause Rotation"
                                  action:@selector(toggleRotation:)
                                     key:@"p"]];

    rotationItem.submenu = rotationMenu;
    [settingsMenu addItem:rotationItem];

    [settingsMenu addItem:[NSMenuItem separatorItem]];

    // Transition Effects
    NSMenuItem *transitionsItem = [[NSMenuItem alloc] initWithTitle:@"Transitions" action:nil keyEquivalent:@""];
    NSMenu *transitionsMenu = [[NSMenu alloc] init];
    [transitionsMenu addItem:[self menuItem:@"None (Instant)" action:@selector(setTransitionNone:) key:@""]];
    [transitionsMenu addItem:[self menuItem:@"Fade" action:@selector(setTransitionFade:) key:@""]];
    [transitionsMenu addItem:[self menuItem:@"Slide Left" action:@selector(setTransitionSlideLeft:) key:@""]];
    [transitionsMenu addItem:[self menuItem:@"Slide Right" action:@selector(setTransitionSlideRight:) key:@""]];
    [transitionsMenu addItem:[self menuItem:@"Slide Up" action:@selector(setTransitionSlideUp:) key:@""]];
    [transitionsMenu addItem:[self menuItem:@"Slide Down" action:@selector(setTransitionSlideDown:) key:@""]];
    [transitionsMenu addItem:[self menuItem:@"Zoom In" action:@selector(setTransitionZoomIn:) key:@""]];
    [transitionsMenu addItem:[self menuItem:@"Zoom Out" action:@selector(setTransitionZoomOut:) key:@""]];
    transitionsItem.submenu = transitionsMenu;
    [settingsMenu addItem:transitionsItem];

    [settingsMenu addItem:[NSMenuItem separatorItem]];

    // Audio Settings
    NSMenuItem *audioItem = [[NSMenuItem alloc] initWithTitle:@"Audio" action:nil keyEquivalent:@""];
    NSMenu *audioMenu = [[NSMenu alloc] init];
    [audioMenu addItem:[self menuItem:@"Mute All Cameras"
                               action:@selector(toggleMute:)
                                  key:@""]];
    [audioMenu addItem:[self menuItem:@"Audio Monitoring..."
                               action:@selector(showAudioMonitoring:)
                                  key:@""]];
    [audioMenu addItem:[self menuItem:@"Audio Alerts Settings..."
                               action:@selector(showAudioAlerts:)
                                  key:@""]];
    audioItem.submenu = audioMenu;
    [settingsMenu addItem:audioItem];

    [settingsMenu addItem:[NSMenuItem separatorItem]];

    // Motion Detection
    [settingsMenu addItem:[self menuItem:@"Motion Detection..."
                                  action:@selector(showMotionDetection:)
                                     key:@""]];

    // Smart Alerts
    [settingsMenu addItem:[self menuItem:@"Smart Alerts..."
                                  action:@selector(showSmartAlerts:)
                                     key:@""]];

    [settingsMenu addItem:[NSMenuItem separatorItem]];

    // Recording
    [settingsMenu addItem:[self menuItem:@"Recording Settings..."
                                  action:@selector(showRecordingSettings:)
                                     key:@""]];

    // Cloud Storage
    [settingsMenu addItem:[self menuItem:@"Cloud Storage..."
                                  action:@selector(showCloudStorage:)
                                     key:@""]];

    [settingsMenu addItem:[NSMenuItem separatorItem]];

    // Failover
    [settingsMenu addItem:[self menuItem:@"Failover Settings..."
                                  action:@selector(showFailoverSettings:)
                                     key:@""]];

    // Network
    [settingsMenu addItem:[self menuItem:@"Network Settings..."
                                  action:@selector(showNetworkSettings:)
                                     key:@""]];

    settingsMenuItem.submenu = settingsMenu;
    return settingsMenuItem;
}

#pragma mark - View Menu

- (NSMenuItem *)createViewMenu {
    NSMenuItem *viewMenuItem = [[NSMenuItem alloc] init];
    NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:@"View"];

    // Full Screen
    NSMenuItem *fullScreenItem = [self menuItem:@"Enter Full Screen"
                                         action:@selector(toggleFullScreen:)
                                            key:@"f"];
    fullScreenItem.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagControl;
    [viewMenu addItem:fullScreenItem];

    [viewMenu addItem:[NSMenuItem separatorItem]];

    // Picture-in-Picture
    [viewMenu addItem:[self menuItem:@"Picture in Picture"
                              action:@selector(togglePictureInPicture:)
                                 key:@""]];

    // Thumbnail Grid
    [viewMenu addItem:[self menuItem:@"Show Thumbnail Grid"
                              action:@selector(toggleThumbnailGrid:)
                                 key:@"g"]];

    [viewMenu addItem:[NSMenuItem separatorItem]];

    // On-Screen Display
    [viewMenu addItem:[self menuItem:@"Show Camera Info Overlay"
                              action:@selector(toggleOSD:)
                                 key:@"i"]];

    // Event Timeline
    [viewMenu addItem:[self menuItem:@"Event Timeline..."
                              action:@selector(showEventTimeline:)
                                 key:@""]];

    [viewMenu addItem:[NSMenuItem separatorItem]];

    // Next/Previous Camera
    [viewMenu addItem:[self menuItem:@"Next Camera"
                              action:@selector(nextCamera:)
                                 key:@"]"]];

    [viewMenu addItem:[self menuItem:@"Previous Camera"
                              action:@selector(previousCamera:)
                                 key:@"["]];

    [viewMenu addItem:[NSMenuItem separatorItem]];

    // Bookmarks
    NSMenuItem *bookmarksItem = [[NSMenuItem alloc] initWithTitle:@"Bookmarks" action:nil keyEquivalent:@""];
    NSMenu *bookmarksMenu = [[NSMenu alloc] init];
    for (int i = 1; i <= 9; i++) {
        NSString *title = [NSString stringWithFormat:@"Go to Bookmark %d", i];
        NSString *key = [NSString stringWithFormat:@"%d", i];
        NSMenuItem *bookmarkItem = [[NSMenuItem alloc] initWithTitle:title
                                                              action:@selector(goToBookmark:)
                                                       keyEquivalent:key];
        bookmarkItem.target = self;
        [bookmarksMenu addItem:bookmarkItem];
    }
    [bookmarksMenu addItem:[NSMenuItem separatorItem]];
    [bookmarksMenu addItem:[self menuItem:@"Manage Bookmarks..."
                                   action:@selector(manageBookmarks:)
                                      key:@""]];
    bookmarksItem.submenu = bookmarksMenu;
    [viewMenu addItem:bookmarksItem];

    viewMenuItem.submenu = viewMenu;
    return viewMenuItem;
}

#pragma mark - Window Menu

- (NSMenuItem *)createWindowMenu {
    NSMenuItem *windowMenuItem = [[NSMenuItem alloc] init];
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];

    [windowMenu addItem:[self menuItem:@"Minimize"
                                action:@selector(performMiniaturize:)
                                   key:@"m" target:self.mainWindow]];

    [windowMenu addItem:[self menuItem:@"Zoom"
                                action:@selector(performZoom:)
                                   key:@"" target:self.mainWindow]];

    [windowMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *cameraListItem = [self menuItem:@"Show Camera List"
                                         action:@selector(showCameraList:)
                                            key:@"L"];
    [windowMenu addItem:cameraListItem];

    [windowMenu addItem:[NSMenuItem separatorItem]];

    [windowMenu addItem:[self menuItem:@"Bring All to Front"
                                action:@selector(arrangeInFront:)
                                   key:@"" target:NSApp]];

    [NSApp setWindowsMenu:windowMenu];
    windowMenuItem.submenu = windowMenu;
    return windowMenuItem;
}

#pragma mark - Help Menu

- (NSMenuItem *)createHelpMenu {
    NSMenuItem *helpMenuItem = [[NSMenuItem alloc] init];
    NSMenu *helpMenu = [[NSMenu alloc] initWithTitle:@"Help"];

    [helpMenu addItem:[self menuItem:@"RTSP Rotator Help"
                              action:@selector(showHelp:)
                                 key:@"?"]];

    [helpMenu addItem:[NSMenuItem separatorItem]];

    [helpMenu addItem:[self menuItem:@"Getting Started Guide"
                              action:@selector(showGettingStarted:)
                                 key:@""]];

    [helpMenu addItem:[self menuItem:@"API Documentation"
                              action:@selector(showAPIDocumentation:)
                                 key:@""]];

    [helpMenu addItem:[NSMenuItem separatorItem]];

    [helpMenu addItem:[self menuItem:@"Report an Issue..."
                              action:@selector(reportIssue:)
                                 key:@""]];

    [helpMenu addItem:[self menuItem:@"Check for Updates..."
                              action:@selector(checkForUpdates:)
                                 key:@""]];

    helpMenuItem.submenu = helpMenu;
    return helpMenuItem;
}

#pragma mark - Helper Methods

- (void)populateDashboardSwitchMenu:(NSMenu *)menu {
    RTSPDashboardManager *manager = [RTSPDashboardManager sharedManager];
    NSArray *dashboards = manager.dashboards;

    if (dashboards.count == 0) {
        NSMenuItem *noDashboards = [[NSMenuItem alloc] initWithTitle:@"No Dashboards"
                                                              action:nil
                                                       keyEquivalent:@""];
        noDashboards.enabled = NO;
        [menu addItem:noDashboards];
    } else {
        for (int i = 0; i < dashboards.count; i++) {
            RTSPDashboard *dashboard = dashboards[i];
            NSString *title = dashboard.name;
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title
                                                          action:@selector(switchToDashboard:)
                                                   keyEquivalent:@""];
            item.target = self;
            item.tag = i;
            if (dashboard == manager.activeDashboard) {
                item.state = NSControlStateValueOn;
            }
            [menu addItem:item];
        }
    }
}

#pragma mark - Menu Action Methods

// These methods will delegate to appropriate controllers
// The actual implementation will be in AppDelegate

- (void)showPreferences:(id)sender {
    [[RTSPPreferencesController sharedController] showWindow:sender];
}

- (void)importConfiguration:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPImportConfiguration" object:nil];
}

- (void)exportConfiguration:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPExportConfiguration" object:nil];
}

- (void)importCamerasFromFile:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPImportCamerasFromFile" object:nil];
}


- (void)connectUniFiProtect:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPConnectUniFiProtect" object:nil];
}

- (void)discoverUniFiCameras:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPDiscoverUniFiCameras" object:nil];
}

- (void)importAllUniFiCameras:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPImportAllUniFiCameras" object:nil];
}

- (void)addUniFiCamera:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPAddUniFiCamera" object:nil];
}

- (void)manageUniFiCameras:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPManageUniFiCameras" object:nil];
}

- (void)testUniFiCameras:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPTestUniFiCameras" object:nil];
}

- (void)refreshUniFiStatus:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPRefreshUniFiStatus" object:nil];
}

- (void)showUniFiSettings:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPShowUniFiSettings" object:nil];
}

- (void)addRTSPCamera:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPAddCamera" object:nil];
}

- (void)addMultipleRTSPCameras:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPAddMultipleCameras" object:nil];
}

- (void)manageRTSPCameras:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPManageCameras" object:nil];
}

- (void)editCurrentRTSPCamera:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPEditCurrentCamera" object:nil];
}

- (void)removeCurrentRTSPCamera:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPRemoveCurrentCamera" object:nil];
}

- (void)testCurrentRTSPCamera:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPTestCurrentCamera" object:nil];
}

- (void)testAllRTSPCameras:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPTestAllCameras" object:nil];
}

- (void)showRTSPDiagnostics:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPShowDiagnostics" object:nil];
}

- (void)openDashboardDesigner:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPOpenDashboardDesigner" object:nil];
}

- (void)createNewDashboard:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPCreateNewDashboard" object:nil];
}

- (void)duplicateCurrentDashboard:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPDuplicateCurrentDashboard" object:nil];
}

- (void)renameCurrentDashboard:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPRenameCurrentDashboard" object:nil];
}

- (void)deleteCurrentDashboard:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPDeleteCurrentDashboard" object:nil];
}

- (void)assignCamerasToDashboard:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPAssignCamerasToDashboard" object:nil];
}

- (void)switchToDashboard:(id)sender {
    NSInteger index = [(NSMenuItem *)sender tag];
    RTSPDashboardManager *manager = [RTSPDashboardManager sharedManager];
    NSArray *dashboards = manager.dashboards;
    if (index >= 0 && index < dashboards.count) {
        [manager activateDashboard:dashboards[index]];
    }
}

- (void)toggleDashboardAutoCycle:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPToggleDashboardAutoCycle" object:nil];
}

- (void)setDashboardCycleInterval:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetDashboardCycleInterval" object:nil];
}

- (void)setRotationInterval:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetRotationInterval" object:nil];
}

- (void)toggleRotation:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPToggleRotation" object:nil];
}

- (void)toggleMute:(id)sender {
    if (self.wallpaperController) {
        self.wallpaperController.isMuted = !self.wallpaperController.isMuted;
    }
}

- (void)toggleFullScreen:(id)sender {
    [self.mainWindow toggleFullScreen:sender];
}

- (void)togglePictureInPicture:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPTogglePictureInPicture" object:nil];
}

- (void)toggleThumbnailGrid:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPToggleThumbnailGrid" object:nil];
}

- (void)toggleOSD:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPToggleOSD" object:nil];
}

- (void)nextCamera:(id)sender {
    if (self.wallpaperController) {
        [self.wallpaperController nextFeed];
    }
}

- (void)previousCamera:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPPreviousCamera" object:nil];
}

- (void)showCameraList:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPShowCameraList" object:nil];
}

#pragma mark - Stub implementations for menu items (will be implemented via notifications)

// Dashboard Layouts
- (void)setDashboardLayout1x1:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetDashboardLayout1x1" object:nil]; }
- (void)setDashboardLayout2x2:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetDashboardLayout2x2" object:nil]; }
- (void)setDashboardLayout3x2:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetDashboardLayout3x2" object:nil]; }
- (void)setDashboardLayout3x3:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetDashboardLayout3x3" object:nil]; }
- (void)setDashboardLayout4x3:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetDashboardLayout4x3" object:nil]; }

// Rotation Intervals
- (void)setRotationInterval10:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetRotationInterval" object:@(10)]; }
- (void)setRotationInterval30:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetRotationInterval" object:@(30)]; }
- (void)setRotationInterval60:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetRotationInterval" object:@(60)]; }
- (void)setRotationInterval120:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetRotationInterval" object:@(120)]; }
- (void)setRotationInterval300:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetRotationInterval" object:@(300)]; }

// Transitions
- (void)setTransitionNone:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetTransition" object:@"none"]; }
- (void)setTransitionFade:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetTransition" object:@"fade"]; }
- (void)setTransitionSlideLeft:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetTransition" object:@"slideLeft"]; }
- (void)setTransitionSlideRight:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetTransition" object:@"slideRight"]; }
- (void)setTransitionSlideUp:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetTransition" object:@"slideUp"]; }
- (void)setTransitionSlideDown:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetTransition" object:@"slideDown"]; }
- (void)setTransitionZoomIn:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetTransition" object:@"zoomIn"]; }
- (void)setTransitionZoomOut:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPSetTransition" object:@"zoomOut"]; }

// Camera Presets
- (void)addHikvisionPreset:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPAddCameraPreset" object:@"Hikvision"]; }
- (void)addDahuaPreset:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPAddCameraPreset" object:@"Dahua"]; }
- (void)addAxisPreset:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPAddCameraPreset" object:@"Axis"]; }
- (void)addAmcrestPreset:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPAddCameraPreset" object:@"Amcrest"]; }
- (void)addReolinkPreset:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPAddCameraPreset" object:@"Reolink"]; }

// Audio/Motion/Alerts
- (void)showAudioMonitoring:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPShowAudioMonitoring" object:nil]; }
- (void)showAudioAlerts:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPShowAudioAlerts" object:nil]; }
- (void)showMotionDetection:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPShowMotionDetection" object:nil]; }
- (void)showSmartAlerts:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPShowSmartAlerts" object:nil]; }
- (void)showRecordingSettings:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPShowRecordingSettings" object:nil]; }
- (void)showCloudStorage:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPShowCloudStorage" object:nil]; }
- (void)showFailoverSettings:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPShowFailoverSettings" object:nil]; }
- (void)showNetworkSettings:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPShowNetworkSettings" object:nil]; }
- (void)showEventTimeline:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPShowEventTimeline" object:nil]; }
- (void)goToBookmark:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPGoToBookmark" object:sender]; }
- (void)manageBookmarks:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPManageBookmarks" object:nil]; }
- (void)showGettingStarted:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPShowGettingStarted" object:nil]; }
- (void)showAPIDocumentation:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPShowAPIDocumentation" object:nil]; }
- (void)reportIssue:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPReportIssue" object:nil]; }
- (void)checkForUpdates:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPCheckForUpdates" object:nil]; }
- (void)showHelp:(id)sender { [NSApp showHelp:sender]; }

@end
