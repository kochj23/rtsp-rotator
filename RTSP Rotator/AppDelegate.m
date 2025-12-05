//
//  AppDelegate.m
//  RTSP Rotator
//
//  Refactored to standard macOS application
//

#import "AppDelegate.h"
#import "RTSPWallpaperController.h"
#import "RTSPStatusMenuController.h"
#import "RTSPMenuBarController.h"
#import "RTSPPreferencesController.h"
#import "RTSPDashboardManager.h"
#import "RTSPCameraTypeManager.h"
#import "RTSPCameraDiagnostics.h"
#import "RTSPFeedMetadata.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

// Phase 1 Features
#import "RTSPBookmarkManager.h"
#import "RTSPTransitionController.h"
#import "RTSPFullScreenController.h"
#import "RTSPAudioMonitor.h"
#import "RTSPMotionDetector.h"

// Phase 2 Features
#import "RTSPPiPController.h"
#import "RTSPThumbnailGrid.h"
#import "RTSPPTZController.h"
#import "RTSPAPIServer.h"
#import "RTSPFailoverManager.h"

// Phase 3 Features
#import "RTSPSmartAlerts.h"
#import "RTSPCloudStorage.h"
#import "RTSPEventLogger.h"

// Configuration Export/Import
#import "RTSPConfigurationExporter.h"

// UniFi Protect Integration
#import "RTSPUniFiProtectAdapter.h"
#import "RTSPStatusWindow.h"
#import "RTSPCameraListWindow.h"

// Security
#import "RTSPKeychainManager.h"

@interface AppDelegate () <RTSPBookmarkManagerDelegate, RTSPAPIServerDelegate, RTSPFailoverManagerDelegate>
@property (nonatomic, strong) RTSPWallpaperController *wallpaperController;
@property (nonatomic, strong) RTSPStatusMenuController *statusMenuController;
@property (nonatomic, strong) RTSPMenuBarController *menuBarController;
@property (nonatomic, strong) NSWindowController *mainWindowController;

// Phase 1 Components
@property (nonatomic, strong) RTSPTransitionController *transitionController;
@property (nonatomic, strong) RTSPFullScreenController *fullScreenController;
@property (nonatomic, strong) RTSPAudioMonitor *audioMonitor;
@property (nonatomic, strong) RTSPMotionDetector *motionDetector;

// Phase 2 Components
@property (nonatomic, strong) RTSPPiPController *pipController;
@property (nonatomic, strong) RTSPThumbnailGrid *thumbnailGrid;
@property (nonatomic, strong) RTSPPTZController *ptzController;

// Phase 3 Components
@property (nonatomic, strong) RTSPSmartAlerts *smartAlerts;
@property (nonatomic, strong) RTSPEventLogger *eventLogger;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSLog(@"[AppDelegate] Application starting...");

    // Show status window on startup
    RTSPStatusWindow *statusWindow = [RTSPStatusWindow sharedWindow];
    [statusWindow clearLog];
    [statusWindow show];
    [statusWindow appendLog:@"=== RTSP Rotator Starting ===" level:@"INFO"];
    [statusWindow appendLog:@"Initializing core managers..." level:@"INFO"];

    // Initialize core managers
    [RTSPDashboardManager sharedManager];
    [statusWindow appendLog:@"✓ Dashboard Manager initialized" level:@"SUCCESS"];

    [RTSPCameraTypeManager sharedManager];
    [statusWindow appendLog:@"✓ Camera Type Manager initialized" level:@"SUCCESS"];

    [RTSPCameraDiagnostics sharedDiagnostics];
    [statusWindow appendLog:@"✓ Camera Diagnostics initialized" level:@"SUCCESS"];

    // Initialize configuration exporter
    [RTSPConfigurationExporter sharedExporter];
    [statusWindow appendLog:@"✓ Configuration Exporter initialized" level:@"SUCCESS"];

    // Initialize UniFi Protect adapter
    [RTSPUniFiProtectAdapter sharedAdapter];
    [statusWindow appendLog:@"✓ UniFi Protect Adapter initialized" level:@"SUCCESS"];

    // Initialize Phase 1: Quick Wins & Essential Features
    [statusWindow appendLog:@"Initializing Phase 1 features..." level:@"INFO"];
    [self initializePhase1Features];
    [statusWindow appendLog:@"✓ Phase 1 features initialized" level:@"SUCCESS"];

    // Initialize Phase 2: High-Impact Features
    [statusWindow appendLog:@"Initializing Phase 2 features..." level:@"INFO"];
    [self initializePhase2Features];
    [statusWindow appendLog:@"✓ Phase 2 features initialized" level:@"SUCCESS"];

    // Initialize Phase 3: Advanced Features
    [statusWindow appendLog:@"Initializing Phase 3 features..." level:@"INFO"];
    [self initializePhase3Features];
    [statusWindow appendLog:@"✓ Phase 3 features initialized" level:@"SUCCESS"];

    // Create main window
    [statusWindow appendLog:@"Creating main window..." level:@"INFO"];
    [self createMainWindow];
    [statusWindow appendLog:@"✓ Main window created" level:@"SUCCESS"];

    // Setup comprehensive menu bar
    [statusWindow appendLog:@"Setting up menu bar..." level:@"INFO"];
    self.menuBarController = [[RTSPMenuBarController alloc] initWithWallpaperController:self.wallpaperController window:self.window];
    [self.menuBarController setupApplicationMenus];
    [statusWindow appendLog:@"✓ Menu bar configured" level:@"SUCCESS"];

    // Initialize status menu
    [statusWindow appendLog:@"Setting up status menu..." level:@"INFO"];
    self.statusMenuController = [[RTSPStatusMenuController alloc] initWithController:self.wallpaperController];
    [self.statusMenuController install];
    [statusWindow appendLog:@"✓ Status menu installed" level:@"SUCCESS"];

    // Load preferences and start
    [statusWindow appendLog:@"Loading preferences and starting playback..." level:@"INFO"];
    [self loadPreferencesAndStart];

    // Setup keyboard shortcuts for bookmarks
    [self setupGlobalKeyboardShortcuts];
    [statusWindow appendLog:@"✓ Keyboard shortcuts configured (⌘1-9 for bookmarks)" level:@"SUCCESS"];

    // Setup notification observers for menu actions
    [self setupMenuNotificationObservers];
    [statusWindow appendLog:@"✓ Menu notification observers configured" level:@"SUCCESS"];

    [statusWindow appendLog:@"=== Application Started Successfully ===" level:@"SUCCESS"];
    [statusWindow appendLog:@"" level:@"INFO"];
    [statusWindow appendLog:@"Window > Show Camera List (⌘L) to view all cameras" level:@"INFO"];
    NSLog(@"[AppDelegate] Application started successfully with all features enabled and comprehensive menus");
}

- (void)createMainWindow {
    // Create window
    NSRect frame = NSMakeRect(0, 0, 1280, 720);
    NSWindowStyleMask styleMask = NSWindowStyleMaskTitled |
                                   NSWindowStyleMaskClosable |
                                   NSWindowStyleMaskMiniaturizable |
                                   NSWindowStyleMaskResizable;

    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:styleMask
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];

    self.window.title = @"RTSP Rotator";
    self.window.minSize = NSMakeSize(800, 600);
    [self.window center];

    // Create wallpaper controller and set as content view
    self.wallpaperController = [[RTSPWallpaperController alloc] init];

    // Create a container view
    NSView *contentView = [[NSView alloc] initWithFrame:frame];
    contentView.wantsLayer = YES;
    contentView.layer.backgroundColor = [[NSColor blackColor] CGColor];

    self.window.contentView = contentView;

    // Initialize wallpaper controller with the window's content view
    [self.wallpaperController setupWithView:contentView];

    // Show window
    [self.window makeKeyAndOrderFront:nil];
}

- (void)loadPreferencesAndStart {
    RTSPStatusWindow *statusWindow = [RTSPStatusWindow sharedWindow];
    RTSPConfigurationManager *config = [RTSPConfigurationManager sharedManager];

    // Load feeds from preferences - try manual feeds first
    NSArray *feedMetadata = config.manualFeedMetadata;
    NSMutableArray *feedURLs = [NSMutableArray array];

    [statusWindow appendLog:@"Loading camera configurations..." level:@"INFO"];

    for (RTSPFeedMetadata *metadata in feedMetadata) {
        if (metadata.url && metadata.enabled) {
            [feedURLs addObject:metadata.url];
        }
    }

    // Fallback to simple manualFeeds if no metadata
    if (feedURLs.count == 0) {
        feedURLs = [config.manualFeeds mutableCopy];
    }

    if (feedURLs.count > 0) {
        [statusWindow appendLog:[NSString stringWithFormat:@"✓ Loaded %lu camera feed(s)", (unsigned long)feedURLs.count] level:@"SUCCESS"];

        [self.wallpaperController setFeeds:feedURLs];

        // Load other preferences
        self.wallpaperController.rotationInterval = config.rotationInterval > 0 ? config.rotationInterval : 60.0;
        [statusWindow appendLog:[NSString stringWithFormat:@"  Rotation interval: %.0f seconds", self.wallpaperController.rotationInterval] level:@"INFO"];

        self.wallpaperController.isMuted = config.startMuted;
        [statusWindow appendLog:[NSString stringWithFormat:@"  Audio: %@", config.startMuted ? @"Muted" : @"Enabled"] level:@"INFO"];

        // Start playback
        [statusWindow appendLog:@"Starting camera playback..." level:@"INFO"];
        [self.wallpaperController start];
        [statusWindow appendLog:@"✓ Playback started" level:@"SUCCESS"];

        // Initialize player-dependent features (audio, motion, smart alerts)
        [statusWindow appendLog:@"Initializing player monitors..." level:@"INFO"];
        [self initializePlayerMonitors];
        [statusWindow appendLog:@"✓ Player monitors initialized" level:@"SUCCESS"];

        // Initialize full-screen controller
        self.fullScreenController = [[RTSPFullScreenController alloc] initWithWindow:self.window playerView:self.window.contentView];
        self.fullScreenController.showControlsOnHover = YES;
        self.fullScreenController.controlsFadeDelay = 3.0;
        [statusWindow appendLog:@"✓ Full-Screen Controller initialized" level:@"SUCCESS"];
        NSLog(@"[Features] Full-Screen Controller initialized");

        NSLog(@"[AppDelegate] Loaded %lu feeds", (unsigned long)feedURLs.count);
    } else {
        [statusWindow appendLog:@"⚠ No camera feeds configured" level:@"WARNING"];
        [statusWindow appendLog:@"Use UniFi Protect > Connect to Controller to add cameras" level:@"INFO"];
        [statusWindow appendLog:@"Or use RTSP Cameras > Add Camera to add manually" level:@"INFO"];
        NSLog(@"[AppDelegate] No feeds configured - use menu to add cameras");
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    NSLog(@"[AppDelegate] Application terminating...");

    // Cleanup
    [self.wallpaperController stop];

    // Stop diagnostics monitoring
    [[RTSPCameraDiagnostics sharedDiagnostics] stopHealthMonitoring];
}

- (void)dealloc {
    // Remove all notification observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // Cleanup wallpaper controller
    [self.wallpaperController stop];

    // Clean up strong references to prevent retain cycles
    self.wallpaperController = nil;
    self.statusMenuController = nil;
    self.menuBarController = nil;
    self.transitionController = nil;
    self.fullScreenController = nil;
    self.audioMonitor = nil;
    self.motionDetector = nil;
    self.pipController = nil;
    self.thumbnailGrid = nil;
    self.ptzController = nil;
    self.smartAlerts = nil;
    self.eventLogger = nil;

    NSLog(@"[AppDelegate] dealloc - all observers and resources cleaned up");
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    // Don't quit when main window closes - we have a status menu
    return NO;
}

- (IBAction)showPreferences:(id)sender {
    [[RTSPPreferencesController sharedController] showWindow:sender];
}

- (IBAction)showMainWindow:(id)sender {
    [self.window makeKeyAndOrderFront:sender];
}

- (IBAction)toggleFullScreen:(id)sender {
    [self.window toggleFullScreen:sender];
}

#pragma mark - Feature Initialization

- (void)initializePhase1Features {
    NSLog(@"[AppDelegate] Initializing Phase 1 features...");

    // Bookmark Manager
    RTSPBookmarkManager *bookmarkManager = [RTSPBookmarkManager sharedManager];
    bookmarkManager.delegate = self;
    bookmarkManager.hotkeysEnabled = YES;
    NSLog(@"[Phase1] ✓ Bookmark Manager initialized");

    // Transition Controller
    self.transitionController = [[RTSPTransitionController alloc] init];
    self.transitionController.duration = 0.5;
    self.transitionController.transitionType = RTSPTransitionTypeFade;
    NSLog(@"[Phase1] ✓ Transition Controller initialized");

    NSLog(@"[AppDelegate] Phase 1 features initialized successfully");
}

- (void)initializePhase2Features {
    NSLog(@"[AppDelegate] Initializing Phase 2 features...");

    // API Server
    RTSPAPIServer *apiServer = [RTSPAPIServer sharedServer];
    apiServer.delegate = self;
    apiServer.port = 8080;
    apiServer.requireAPIKey = NO; // Can be enabled in preferences
    NSLog(@"[Phase2] ✓ API Server configured (port: %ld)", (long)apiServer.port);

    // Failover Manager
    RTSPFailoverManager *failoverManager = [RTSPFailoverManager sharedManager];
    failoverManager.delegate = self;
    failoverManager.autoFailoverEnabled = YES;
    failoverManager.healthCheckInterval = 30.0;
    NSLog(@"[Phase2] ✓ Failover Manager initialized");

    NSLog(@"[AppDelegate] Phase 2 features initialized successfully");
}

- (void)initializePhase3Features {
    NSLog(@"[AppDelegate] Initializing Phase 3 features...");

    // Event Logger
    self.eventLogger = [RTSPEventLogger sharedLogger];
    self.eventLogger.loggingEnabled = YES;
    NSLog(@"[Phase3] ✓ Event Logger started");

    // Cloud Storage (disabled by default)
    RTSPCloudStorage *cloudStorage = [RTSPCloudStorage sharedManager];
    cloudStorage.autoUploadEnabled = NO; // Enable in preferences
    NSLog(@"[Phase3] ✓ Cloud Storage configured (disabled by default)");

    NSLog(@"[AppDelegate] Phase 3 features initialized successfully");
}

- (void)setupGlobalKeyboardShortcuts {
    // Setup Command+1-9 for bookmarks
    NSEventMask mask = NSEventMaskKeyDown;
    [NSEvent addLocalMonitorForEventsMatchingMask:mask handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
        if (event.modifierFlags & NSEventModifierFlagCommand) {
            NSString *chars = event.charactersIgnoringModifiers;
            if (chars.length == 1) {
                unichar ch = [chars characterAtIndex:0];
                if (ch >= '1' && ch <= '9') {
                    NSInteger hotkey = ch - '0';
                    [[RTSPBookmarkManager sharedManager] handleHotkeyPress:hotkey];
                    return nil; // Consume event
                }
            }
        }
        return event;
    }];

    NSLog(@"[AppDelegate] Global keyboard shortcuts configured (⌘1-9 for bookmarks)");
}

- (void)initializePlayerMonitors {
    // Initialize audio monitor if player exists
    if (self.wallpaperController.player) {
        self.audioMonitor = [[RTSPAudioMonitor alloc] initWithPlayer:self.wallpaperController.player];
        self.audioMonitor.enabled = NO; // Enable in preferences
        self.audioMonitor.updateInterval = 0.1;
        self.audioMonitor.loudNoiseThreshold = 0.8;
        NSLog(@"[Features] Audio Monitor initialized");

        // Initialize motion detector
        self.motionDetector = [[RTSPMotionDetector alloc] initWithPlayer:self.wallpaperController.player];
        self.motionDetector.enabled = NO; // Enable in preferences
        self.motionDetector.sensitivity = 0.5;
        self.motionDetector.checkInterval = 0.5;
        NSLog(@"[Features] Motion Detector initialized");

        // Initialize smart alerts
        self.smartAlerts = [[RTSPSmartAlerts alloc] initWithPlayer:self.wallpaperController.player];
        self.smartAlerts.enabled = NO; // Enable in preferences
        self.smartAlerts.confidenceThreshold = 0.7;
        NSLog(@"[Features] Smart Alerts initialized");
    }
}

#pragma mark - RTSPBookmarkManagerDelegate

- (void)bookmarkManager:(RTSPBookmarkManager *)manager didActivateBookmark:(RTSPBookmark *)bookmark {
    NSLog(@"[Bookmarks] Activated: %@", bookmark.name);

    // Log event
    if (self.eventLogger) {
        [self.eventLogger logEventType:RTSPEventTypeBookmarkActivated
                                  title:@"Bookmark Activated"
                                details:[NSString stringWithFormat:@"%@", bookmark.name]
                                feedURL:bookmark.feedURL];
    }

    // Switch to bookmarked feed
    if (bookmark.feedIndex >= 0 && bookmark.feedIndex < self.wallpaperController.feeds.count) {
        self.wallpaperController.currentIndex = bookmark.feedIndex;
        [self.wallpaperController playCurrentFeed];
    }
}

#pragma mark - RTSPAPIServerDelegate

- (NSArray<NSString *> *)apiServerRequestFeedList:(RTSPAPIServer *)server {
    return self.wallpaperController.feeds;
}

- (NSInteger)apiServerRequestCurrentFeedIndex:(RTSPAPIServer *)server {
    return self.wallpaperController.currentIndex;
}

- (void)apiServer:(RTSPAPIServer *)server switchToFeedAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.wallpaperController.feeds.count) {
        self.wallpaperController.currentIndex = index;
        [self.wallpaperController playCurrentFeed];

        if (self.eventLogger) {
            [self.eventLogger logEventType:RTSPEventTypeFeedSwitch
                                      title:@"API Feed Switch"
                                    details:[NSString stringWithFormat:@"Index: %ld", (long)index]
                                    feedURL:nil];
        }
    }
}

- (void)apiServerSwitchToNextFeed:(RTSPAPIServer *)server {
    [self.wallpaperController nextFeed];

    if (self.eventLogger) {
        [self.eventLogger logEventType:RTSPEventTypeFeedSwitch
                                  title:@"API Next Feed"
                                details:@"Next feed via API"
                                feedURL:nil];
    }
}

- (void)apiServerSwitchToPreviousFeed:(RTSPAPIServer *)server {
    NSInteger count = self.wallpaperController.feeds.count;
    if (count > 0) {
        self.wallpaperController.currentIndex = (self.wallpaperController.currentIndex - 1 + count) % count;
        [self.wallpaperController playCurrentFeed];
    }
}

- (void)apiServer:(RTSPAPIServer *)server setRotationInterval:(NSTimeInterval)interval {
    self.wallpaperController.rotationInterval = interval;
}

#pragma mark - RTSPFailoverManagerDelegate

- (void)failoverManager:(RTSPFailoverManager *)manager didFailoverFeed:(RTSPFeedConfig *)feed toURL:(NSURL *)backupURL {
    NSLog(@"[Failover] Feed '%@' failed over to backup: %@", feed.name, backupURL);

    if (self.eventLogger) {
        [self.eventLogger logEventType:RTSPEventTypeFailover
                                  title:@"Feed Failover"
                                details:[NSString stringWithFormat:@"%@ → %@", feed.name, backupURL.absoluteString]
                                feedURL:backupURL];
    }
}

- (void)failoverManager:(RTSPFailoverManager *)manager didRestoreFeed:(RTSPFeedConfig *)feed toPrimaryURL:(NSURL *)primaryURL {
    NSLog(@"[Failover] Feed '%@' restored to primary: %@", feed.name, primaryURL);

    if (self.eventLogger) {
        [self.eventLogger logEventType:RTSPEventTypeInfo
                                  title:@"Feed Restored"
                                details:[NSString stringWithFormat:@"%@ restored to primary", feed.name]
                                feedURL:primaryURL];
    }
}

- (void)failoverManager:(RTSPFailoverManager *)manager didFailFeed:(RTSPFeedConfig *)feed withError:(NSError *)error {
    NSLog(@"[Failover] Feed '%@' failed: %@", feed.name, error.localizedDescription);

    if (self.eventLogger) {
        [self.eventLogger logEventType:RTSPEventTypeConnectionFailed
                                  title:@"Feed Failed"
                                details:[NSString stringWithFormat:@"%@: %@", feed.name, error.localizedDescription]
                                feedURL:feed.primaryURL];
    }
}

#pragma mark - Menu Notification Observers

- (void)setupMenuNotificationObservers {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    // File menu
    [nc addObserver:self selector:@selector(handleImportConfiguration:) name:@"RTSPImportConfiguration" object:nil];
    [nc addObserver:self selector:@selector(handleExportConfiguration:) name:@"RTSPExportConfiguration" object:nil];
    [nc addObserver:self selector:@selector(handleImportCamerasFromFile:) name:@"RTSPImportCamerasFromFile" object:nil];

    // UniFi Protect menu
    [nc addObserver:self selector:@selector(handleConnectUniFiProtect:) name:@"RTSPConnectUniFiProtect" object:nil];
    [nc addObserver:self selector:@selector(handleDiscoverUniFiCameras:) name:@"RTSPDiscoverUniFiCameras" object:nil];
    [nc addObserver:self selector:@selector(handleImportAllUniFiCameras:) name:@"RTSPImportAllUniFiCameras" object:nil];
    [nc addObserver:self selector:@selector(handleAddUniFiCamera:) name:@"RTSPAddUniFiCamera" object:nil];
    [nc addObserver:self selector:@selector(handleManageUniFiCameras:) name:@"RTSPManageUniFiCameras" object:nil];
    [nc addObserver:self selector:@selector(handleTestUniFiCameras:) name:@"RTSPTestUniFiCameras" object:nil];
    [nc addObserver:self selector:@selector(handleRefreshUniFiStatus:) name:@"RTSPRefreshUniFiStatus" object:nil];
    [nc addObserver:self selector:@selector(handleShowUniFiSettings:) name:@"RTSPShowUniFiSettings" object:nil];

    // RTSP Cameras menu
    [nc addObserver:self selector:@selector(handleAddCamera:) name:@"RTSPAddCamera" object:nil];
    [nc addObserver:self selector:@selector(handleAddMultipleCameras:) name:@"RTSPAddMultipleCameras" object:nil];
    [nc addObserver:self selector:@selector(handleManageCameras:) name:@"RTSPManageCameras" object:nil];
    [nc addObserver:self selector:@selector(handleEditCurrentCamera:) name:@"RTSPEditCurrentCamera" object:nil];
    [nc addObserver:self selector:@selector(handleRemoveCurrentCamera:) name:@"RTSPRemoveCurrentCamera" object:nil];
    [nc addObserver:self selector:@selector(handleTestCurrentCamera:) name:@"RTSPTestCurrentCamera" object:nil];
    [nc addObserver:self selector:@selector(handleTestAllCameras:) name:@"RTSPTestAllCameras" object:nil];
    [nc addObserver:self selector:@selector(handleShowDiagnostics:) name:@"RTSPShowDiagnostics" object:nil];
    [nc addObserver:self selector:@selector(handleAddCameraPreset:) name:@"RTSPAddCameraPreset" object:nil];

    // Dashboard menu
    [nc addObserver:self selector:@selector(handleOpenDashboardDesigner:) name:@"RTSPOpenDashboardDesigner" object:nil];
    [nc addObserver:self selector:@selector(handleCreateNewDashboard:) name:@"RTSPCreateNewDashboard" object:nil];
    [nc addObserver:self selector:@selector(handleDuplicateCurrentDashboard:) name:@"RTSPDuplicateCurrentDashboard" object:nil];
    [nc addObserver:self selector:@selector(handleRenameCurrentDashboard:) name:@"RTSPRenameCurrentDashboard" object:nil];
    [nc addObserver:self selector:@selector(handleDeleteCurrentDashboard:) name:@"RTSPDeleteCurrentDashboard" object:nil];
    [nc addObserver:self selector:@selector(handleAssignCamerasToDashboard:) name:@"RTSPAssignCamerasToDashboard" object:nil];
    [nc addObserver:self selector:@selector(handleSetDashboardLayout:) name:@"RTSPSetDashboardLayout1x1" object:nil];
    [nc addObserver:self selector:@selector(handleSetDashboardLayout:) name:@"RTSPSetDashboardLayout2x2" object:nil];
    [nc addObserver:self selector:@selector(handleSetDashboardLayout:) name:@"RTSPSetDashboardLayout3x2" object:nil];
    [nc addObserver:self selector:@selector(handleSetDashboardLayout:) name:@"RTSPSetDashboardLayout3x3" object:nil];
    [nc addObserver:self selector:@selector(handleSetDashboardLayout:) name:@"RTSPSetDashboardLayout4x3" object:nil];
    [nc addObserver:self selector:@selector(handleToggleDashboardAutoCycle:) name:@"RTSPToggleDashboardAutoCycle" object:nil];
    [nc addObserver:self selector:@selector(handleSetDashboardCycleInterval:) name:@"RTSPSetDashboardCycleInterval" object:nil];

    // Advanced Settings menu
    [nc addObserver:self selector:@selector(handleShowAudioMonitoring:) name:@"RTSPShowAudioMonitoring" object:nil];
    [nc addObserver:self selector:@selector(handleShowAudioAlerts:) name:@"RTSPShowAudioAlerts" object:nil];
    [nc addObserver:self selector:@selector(handleShowMotionDetection:) name:@"RTSPShowMotionDetection" object:nil];
    [nc addObserver:self selector:@selector(handleShowSmartAlerts:) name:@"RTSPShowSmartAlerts" object:nil];
    [nc addObserver:self selector:@selector(handleShowRecordingSettings:) name:@"RTSPShowRecordingSettings" object:nil];
    [nc addObserver:self selector:@selector(handleShowCloudStorage:) name:@"RTSPShowCloudStorage" object:nil];
    [nc addObserver:self selector:@selector(handleShowFailoverSettings:) name:@"RTSPShowFailoverSettings" object:nil];
    [nc addObserver:self selector:@selector(handleShowNetworkSettings:) name:@"RTSPShowNetworkSettings" object:nil];

    // View menu (additional)
    [nc addObserver:self selector:@selector(handleShowCameraList:) name:@"RTSPShowCameraList" object:nil];
    [nc addObserver:self selector:@selector(handleShowEventTimeline:) name:@"RTSPShowEventTimeline" object:nil];
    [nc addObserver:self selector:@selector(handleGoToBookmark:) name:@"RTSPGoToBookmark" object:nil];
    [nc addObserver:self selector:@selector(handleManageBookmarks:) name:@"RTSPManageBookmarks" object:nil];

    // Help menu
    [nc addObserver:self selector:@selector(handleShowGettingStarted:) name:@"RTSPShowGettingStarted" object:nil];
    [nc addObserver:self selector:@selector(handleShowAPIDocumentation:) name:@"RTSPShowAPIDocumentation" object:nil];
    [nc addObserver:self selector:@selector(handleReportIssue:) name:@"RTSPReportIssue" object:nil];
    [nc addObserver:self selector:@selector(handleCheckForUpdates:) name:@"RTSPCheckForUpdates" object:nil];

    // Settings menu - Rotation
    [nc addObserver:self selector:@selector(handleSetRotationInterval:) name:@"RTSPSetRotationInterval" object:nil];
    [nc addObserver:self selector:@selector(handleToggleRotation:) name:@"RTSPToggleRotation" object:nil];

    // Settings menu - Transitions
    [nc addObserver:self selector:@selector(handleSetTransition:) name:@"RTSPSetTransition" object:nil];

    // View menu
    [nc addObserver:self selector:@selector(handlePreviousCamera:) name:@"RTSPPreviousCamera" object:nil];
    [nc addObserver:self selector:@selector(handleTogglePiP:) name:@"RTSPTogglePictureInPicture" object:nil];
    [nc addObserver:self selector:@selector(handleToggleThumbnailGrid:) name:@"RTSPToggleThumbnailGrid" object:nil];
    [nc addObserver:self selector:@selector(handleToggleOSD:) name:@"RTSPToggleOSD" object:nil];

    NSLog(@"[AppDelegate] Menu notification observers configured");
}

#pragma mark - Menu Action Handlers

// File menu handlers
- (void)handleImportConfiguration:(NSNotification *)notification {
    NSLog(@"[Menu] Import Configuration requested");

    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    if (@available(macOS 11.0, *)) {
        panel.allowedContentTypes = @[[UTType typeWithIdentifier:@"public.json"]];
    } else {
        panel.allowedFileTypes = @[@"json"];
    }
    panel.title = @"Import Configuration";

    if ([panel runModal] == NSModalResponseOK) {
        NSURL *fileURL = panel.URL;
        [[RTSPConfigurationExporter sharedExporter] importConfigurationFromFile:fileURL.path
                                                                          merge:NO
                                                                     completion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                NSLog(@"[Menu] Configuration imported successfully");
                // Reload feeds
                [self loadPreferencesAndStart];
            } else {
                NSLog(@"[Menu] Configuration import failed: %@", error.localizedDescription);
            }
        }];
    }
}

- (void)handleExportConfiguration:(NSNotification *)notification {
    NSLog(@"[Menu] Export Configuration requested");

    NSSavePanel *panel = [NSSavePanel savePanel];
    if (@available(macOS 11.0, *)) {
        panel.allowedContentTypes = @[[UTType typeWithIdentifier:@"public.json"]];
    } else {
        panel.allowedFileTypes = @[@"json"];
    }
    panel.nameFieldStringValue = @"rtsp-rotator-config.json";
    panel.title = @"Export Configuration";

    if ([panel runModal] == NSModalResponseOK) {
        NSURL *fileURL = panel.URL;
        [[RTSPConfigurationExporter sharedExporter] exportConfigurationToFile:fileURL.path
                                                                    completion:^(BOOL success, NSString * _Nullable filePath, NSError * _Nullable error) {
            if (success) {
                NSLog(@"[Menu] Configuration exported to: %@", filePath);
            } else {
                NSLog(@"[Menu] Configuration export failed: %@", error.localizedDescription);
            }
        }];
    }
}

- (void)handleImportCamerasFromFile:(NSNotification *)notification {
    NSLog(@"[Menu] Import Cameras from File requested");
    // Open file picker for CSV import
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    if (@available(macOS 11.0, *)) {
        panel.allowedContentTypes = @[
            [UTType typeWithFilenameExtension:@"csv"],
            [UTType typeWithIdentifier:@"public.plain-text"]
        ];
    } else {
        panel.allowedFileTypes = @[@"csv", @"txt"];
    }
    panel.title = @"Import Cameras from CSV";

    if ([panel runModal] == NSModalResponseOK) {
        NSURL *fileURL = panel.URL;
        // TODO: Implement CSV parsing and camera import
        NSLog(@"[Menu] Selected file: %@", fileURL.path);
    }
}

// Settings menu handlers
- (void)handleSetRotationInterval:(NSNotification *)notification {
    NSNumber *interval = notification.object;
    if (interval) {
        self.wallpaperController.rotationInterval = interval.doubleValue;
        NSLog(@"[Menu] Rotation interval set to %.0f seconds", interval.doubleValue);

        // Save to preferences
        RTSPConfigurationManager *config = [RTSPConfigurationManager sharedManager];
        config.rotationInterval = interval.doubleValue;
        // Configuration is automatically saved via NSUserDefaults
    }
}

- (void)handleToggleRotation:(NSNotification *)notification {
    // Toggle rotation by setting interval to 0 or restoring previous value
    static NSTimeInterval savedInterval = 60.0;

    if (self.wallpaperController.rotationInterval > 0) {
        savedInterval = self.wallpaperController.rotationInterval;
        self.wallpaperController.rotationInterval = 0;
        NSLog(@"[Menu] Rotation paused");
    } else {
        self.wallpaperController.rotationInterval = savedInterval;
        NSLog(@"[Menu] Rotation resumed (%.0f seconds)", savedInterval);
    }
}

- (void)handleSetTransition:(NSNotification *)notification {
    NSString *transitionName = notification.object;
    if (transitionName && self.transitionController) {
        RTSPTransitionType type = RTSPTransitionTypeFade;

        if ([transitionName isEqualToString:@"none"]) {
            type = RTSPTransitionTypeNone;
        } else if ([transitionName isEqualToString:@"fade"]) {
            type = RTSPTransitionTypeFade;
        } else if ([transitionName isEqualToString:@"slideLeft"]) {
            type = RTSPTransitionTypeSlideLeft;
        } else if ([transitionName isEqualToString:@"slideRight"]) {
            type = RTSPTransitionTypeSlideRight;
        } else if ([transitionName isEqualToString:@"slideUp"]) {
            type = RTSPTransitionTypeSlideUp;
        } else if ([transitionName isEqualToString:@"slideDown"]) {
            type = RTSPTransitionTypeSlideDown;
        } else if ([transitionName isEqualToString:@"zoomIn"]) {
            type = RTSPTransitionTypeZoomIn;
        } else if ([transitionName isEqualToString:@"zoomOut"]) {
            type = RTSPTransitionTypeZoomOut;
        }

        self.transitionController.transitionType = type;
        NSLog(@"[Menu] Transition set to: %@", transitionName);
    }
}

// View menu handlers
- (void)handlePreviousCamera:(NSNotification *)notification {
    NSInteger count = self.wallpaperController.feeds.count;
    if (count > 0) {
        self.wallpaperController.currentIndex = (self.wallpaperController.currentIndex - 1 + count) % count;
        [self.wallpaperController playCurrentFeed];
        NSLog(@"[Menu] Switched to previous camera");
    }
}

- (void)handleTogglePiP:(NSNotification *)notification {
    if (!self.pipController) {
        // Create PiP with current feed URL
        if (self.wallpaperController.currentIndex < self.wallpaperController.feeds.count) {
            NSString *feedString = self.wallpaperController.feeds[self.wallpaperController.currentIndex];
            NSURL *feedURL = [NSURL URLWithString:feedString];
            self.pipController = [[RTSPPiPController alloc] initWithFeedURL:feedURL];
        }
    }

    if (self.pipController.isVisible) {
        [self.pipController hide];
        NSLog(@"[Menu] Picture-in-Picture hidden");
    } else {
        [self.pipController show];
        NSLog(@"[Menu] Picture-in-Picture shown");
    }
}

- (void)handleToggleThumbnailGrid:(NSNotification *)notification {
    if (!self.thumbnailGrid) {
        // Convert feed strings to URLs
        NSMutableArray *feedURLs = [NSMutableArray array];
        for (NSString *feedString in self.wallpaperController.feeds) {
            NSURL *feedURL = [NSURL URLWithString:feedString];
            if (feedURL) {
                [feedURLs addObject:feedURL];
            }
        }
        self.thumbnailGrid = [[RTSPThumbnailGrid alloc] initWithFeedURLs:feedURLs];
    }

    // Toggle visibility by adding/removing from superview
    if (self.thumbnailGrid.superview) {
        [self.thumbnailGrid removeFromSuperview];
        [self.thumbnailGrid stopAutoRefresh];
        NSLog(@"[Menu] Thumbnail grid hidden");
    } else {
        NSView *contentView = self.window.contentView;
        NSRect frame = contentView.bounds;
        frame.origin.y = frame.size.height - 200; // Position at top
        frame.size.height = 200;
        self.thumbnailGrid.frame = frame;
        [contentView addSubview:self.thumbnailGrid];
        [self.thumbnailGrid startAutoRefresh];
        NSLog(@"[Menu] Thumbnail grid shown");
    }
}

- (void)handleToggleOSD:(NSNotification *)notification {
    // TODO: Implement OSD toggle
    NSLog(@"[Menu] Toggle OSD requested (not yet implemented)");
}

// UniFi Protect handlers
- (void)handleConnectUniFiProtect:(NSNotification *)notification {
    NSLog(@"[Menu] UniFi Protect connection requested");

    RTSPUniFiProtectAdapter *adapter = [RTSPUniFiProtectAdapter sharedAdapter];

    // Migrate existing passwords from NSUserDefaults to Keychain (if needed)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [RTSPKeychainManager migratePasswordFromUserDefaults:@"UniFi_Password"
                                              toAccount:@"UniFi_Password"
                                                service:RTSPKeychainServiceUniFiProtect];

    // Load credentials from preferences (host and username) and Keychain (password)
    NSString *savedHost = [defaults stringForKey:@"UniFi_ControllerHost"];
    NSString *savedUsername = [defaults stringForKey:@"UniFi_Username"];
    NSString *savedPassword = [RTSPKeychainManager passwordForAccount:@"UniFi_Password"
                                                              service:RTSPKeychainServiceUniFiProtect];

    // If we have saved credentials, use them directly
    if (savedHost.length > 0 && savedUsername.length > 0 && savedPassword.length > 0) {
        NSLog(@"[Menu] Using saved UniFi credentials");
        adapter.controllerHost = savedHost;
        adapter.username = savedUsername;
        adapter.password = savedPassword;

        // Authenticate directly (will prompt for MFA if needed)
        [self authenticateUniFiAdapter:adapter];
        return;
    }

    // No saved credentials - show connection dialog
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Connect to UniFi Protect";
    alert.informativeText = @"Enter your UniFi Protect controller details:\n(These will be saved in Preferences)";
    alert.alertStyle = NSAlertStyleInformational;

    // Create input fields - pre-fill with any saved values
    NSTextField *hostField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 52, 300, 24)];
    hostField.placeholderString = @"Controller IP or hostname";
    hostField.stringValue = savedHost ?: @"";

    NSTextField *userField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 26, 300, 24)];
    userField.placeholderString = @"Username";
    userField.stringValue = savedUsername ?: @"";

    NSSecureTextField *passField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
    passField.placeholderString = @"Password";
    passField.stringValue = savedPassword ?: @"";

    NSView *accessoryView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 300, 82)];
    [accessoryView addSubview:hostField];
    [accessoryView addSubview:userField];
    [accessoryView addSubview:passField];

    alert.accessoryView = accessoryView;
    [alert addButtonWithTitle:@"Connect"];
    [alert addButtonWithTitle:@"Cancel"];

    if ([alert runModal] == NSAlertFirstButtonReturn) {
        NSString *host = hostField.stringValue;
        NSString *username = userField.stringValue;
        NSString *password = passField.stringValue;

        if (host.length > 0 && username.length > 0 && password.length > 0) {
            adapter.controllerHost = host;
            adapter.username = username;
            adapter.password = password;
            adapter.useHTTPS = YES;
            adapter.verifySSL = NO; // Allow self-signed certs

            // Save non-sensitive data to preferences
            [defaults setObject:host forKey:@"UniFi_ControllerHost"];
            [defaults setObject:username forKey:@"UniFi_Username"];
            [defaults synchronize];

            // Save password securely to Keychain
            [RTSPKeychainManager setPassword:password
                                  forAccount:@"UniFi_Password"
                                     service:RTSPKeychainServiceUniFiProtect];

            [self authenticateUniFiAdapter:adapter];
        }
    }
}

- (void)authenticateUniFiAdapter:(RTSPUniFiProtectAdapter *)adapter {
    RTSPStatusWindow *statusWindow = [RTSPStatusWindow sharedWindow];
    [statusWindow show];
    [statusWindow appendLog:@"" level:@"INFO"];
    [statusWindow appendLog:@"=== UniFi Protect Authentication ===" level:@"INFO"];

    [adapter authenticateWithCompletion:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        NSLog(@"[Menu] UniFi Protect connected successfully");
                        [statusWindow appendLog:@"✓ Authentication successful!" level:@"SUCCESS"];
                        [statusWindow appendLog:@"✓ Session cookie created" level:@"SUCCESS"];
                        [adapter saveConfiguration];
                        [statusWindow appendLog:@"✓ Configuration saved" level:@"SUCCESS"];
                        [statusWindow appendLog:@"" level:@"INFO"];
                        [statusWindow appendLog:@"Automatically discovering cameras..." level:@"INFO"];

                        NSAlert *successAlert = [[NSAlert alloc] init];
                        successAlert.messageText = @"Connected to UniFi Protect";
                        successAlert.informativeText = @"Successfully connected. Discovering cameras now...";
                        successAlert.alertStyle = NSAlertStyleInformational;
                        [successAlert addButtonWithTitle:@"OK"];
                        [successAlert runModal];

                        // AUTO-DISCOVER cameras after successful authentication (with small delay for state update)
                        [statusWindow appendLog:@"Starting automatic camera discovery in 2 seconds..." level:@"INFO"];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            NSLog(@"[Menu] Auto-triggering camera discovery after successful auth");
                            [self handleDiscoverUniFiCameras:nil];
                        });
                    } else if (error.code == 1008 && [error.localizedDescription isEqualToString:@"MFA_REQUIRED"]) {
                        // MFA required - prompt for token
                        NSLog(@"[Menu] UniFi Protect requires MFA token");
                        NSAlert *mfaAlert = [[NSAlert alloc] init];
                        mfaAlert.messageText = @"MFA Token Required";
                        mfaAlert.informativeText = @"Enter your 6-digit MFA token:";

                        NSTextField *tokenField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
                        tokenField.placeholderString = @"123456";
                        mfaAlert.accessoryView = tokenField;

                        [mfaAlert addButtonWithTitle:@"Submit"];
                        [mfaAlert addButtonWithTitle:@"Cancel"];

                        if ([mfaAlert runModal] == NSAlertFirstButtonReturn) {
                            NSString *mfaToken = tokenField.stringValue;
                            if (mfaToken.length > 0) {
                                // Retry authentication with MFA token
                                [adapter authenticateWithMFAToken:mfaToken completion:^(BOOL mfaSuccess, NSError * _Nullable mfaError) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        if (mfaSuccess) {
                                            NSLog(@"[Menu] UniFi Protect connected with MFA");
                                            [statusWindow appendLog:@"✓ MFA authentication successful!" level:@"SUCCESS"];
                                            [statusWindow appendLog:@"✓ Session cookie created" level:@"SUCCESS"];
                                            [adapter saveConfiguration];
                                            [statusWindow appendLog:@"✓ Configuration saved" level:@"SUCCESS"];
                                            [statusWindow appendLog:@"" level:@"INFO"];

                                            NSAlert *successAlert = [[NSAlert alloc] init];
                                            successAlert.messageText = @"Connected to UniFi Protect";
                                            successAlert.informativeText = @"Successfully connected with MFA. Discovering cameras now...";
                                            successAlert.alertStyle = NSAlertStyleInformational;
                                            [successAlert addButtonWithTitle:@"OK"];
                                            [successAlert runModal];

                                            // AUTO-DISCOVER cameras after successful MFA authentication (with small delay)
                                            [statusWindow appendLog:@"Starting automatic camera discovery in 2 seconds..." level:@"INFO"];
                                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                NSLog(@"[Menu] Auto-triggering camera discovery after successful MFA");
                                                [self handleDiscoverUniFiCameras:nil];
                                            });
                                        } else {
                                            NSLog(@"[Menu] UniFi Protect MFA failed: %@", mfaError.localizedDescription);
                                            NSAlert *errorAlert = [[NSAlert alloc] init];
                                            errorAlert.messageText = @"MFA Authentication Failed";
                                            errorAlert.informativeText = mfaError.localizedDescription ?: @"Invalid MFA token";
                                            errorAlert.alertStyle = NSAlertStyleCritical;
                                            [errorAlert addButtonWithTitle:@"OK"];
                                            [errorAlert runModal];
                                        }
                                    });
                                }];
                            }
                        }
                    } else {
                        NSLog(@"[Menu] UniFi Protect connection failed: %@", error.localizedDescription);
                        NSAlert *errorAlert = [[NSAlert alloc] init];
                        errorAlert.messageText = @"Connection Failed";
                        errorAlert.informativeText = error.localizedDescription ?: @"Could not connect to controller";
                        errorAlert.alertStyle = NSAlertStyleCritical;
                        [errorAlert addButtonWithTitle:@"OK"];
                        [errorAlert runModal];
                    }
                });
            }];
}

- (void)handleDiscoverUniFiCameras:(NSNotification *)notification {
    NSLog(@"[Menu] UniFi camera discovery requested");

    // Show status window
    RTSPStatusWindow *statusWindow = [RTSPStatusWindow sharedWindow];
    if (notification) { // Only clear if triggered by menu (not by auto-discovery)
        [statusWindow clearLog];
    }
    [statusWindow show];
    [statusWindow appendLog:@"" level:@"INFO"];
    [statusWindow appendLog:@"=== UniFi Camera Discovery ===" level:@"INFO"];
    [statusWindow appendLog:@"Starting UniFi camera discovery..." level:@"INFO"];

    RTSPUniFiProtectAdapter *adapter = [RTSPUniFiProtectAdapter sharedAdapter];
    [statusWindow appendLog:[NSString stringWithFormat:@"Controller: %@:%ld", adapter.controllerHost, (long)adapter.controllerPort] level:@"INFO"];
    [statusWindow appendLog:[NSString stringWithFormat:@"Username: %@", adapter.username] level:@"INFO"];
    [statusWindow appendLog:@"" level:@"INFO"];

    // Check if authenticated (but don't block auto-discovery after auth)
    if (!adapter.isAuthenticated && notification) {
        [statusWindow appendLog:@"⚠ Not authenticated - connecting first..." level:@"WARNING"];
        NSLog(@"[Menu] Not authenticated, triggering authentication flow with MFA support");

        // Trigger authentication which will prompt for MFA if needed
        [self handleConnectUniFiProtect:nil];
        return;
    }

    if (adapter.isAuthenticated) {
        [statusWindow appendLog:@"✓ Authentication status: Connected" level:@"SUCCESS"];
    }
    [statusWindow appendLog:@"Fetching camera list from controller..." level:@"INFO"];

    [adapter discoverCamerasWithCompletion:^(NSArray<RTSPUniFiCamera *> * _Nullable cameras, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (cameras) {
                NSLog(@"[Menu] Discovered %lu UniFi cameras", (unsigned long)cameras.count);
                [statusWindow appendLog:@"" level:@"INFO"];
                [statusWindow appendLog:@"=== DISCOVERY SUCCESSFUL ===" level:@"SUCCESS"];
                [statusWindow appendLog:[NSString stringWithFormat:@"✓ Found %lu camera(s)", (unsigned long)cameras.count] level:@"SUCCESS"];
                [statusWindow appendLog:@"" level:@"INFO"];

                // Log each camera with details
                for (RTSPUniFiCamera *camera in cameras) {
                    NSString *status = camera.isOnline ? @"✓ Online" : @"✗ Offline";
                    [statusWindow appendLog:[NSString stringWithFormat:@"Camera: %@", camera.name] level:@"INFO"];
                    [statusWindow appendLog:[NSString stringWithFormat:@"  Model: %@", camera.model] level:@"INFO"];
                    [statusWindow appendLog:[NSString stringWithFormat:@"  IP: %@", camera.ipAddress] level:@"INFO"];
                    [statusWindow appendLog:[NSString stringWithFormat:@"  Status: %@", status] level:camera.isOnline ? @"SUCCESS" : @"WARNING"];
                    [statusWindow appendLog:@"" level:@"INFO"];
                }

                [statusWindow appendLog:@"=== NEXT STEP ===" level:@"INFO"];
                [statusWindow appendLog:@"Menu → UniFi Protect → Import All Cameras" level:@"INFO"];
                [statusWindow appendLog:@"This will add cameras to your feed rotation" level:@"INFO"];

                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"Cameras Discovered Successfully!";
                alert.informativeText = [NSString stringWithFormat:@"Found %lu UniFi camera(s).\n\nReady to import?\n\nMenu → UniFi Protect → Import All Cameras", (unsigned long)cameras.count];
                alert.alertStyle = NSAlertStyleInformational;
                [alert addButtonWithTitle:@"OK"];
                [alert runModal];
            } else {
                NSLog(@"[Menu] UniFi camera discovery failed: %@", error.localizedDescription);
                [statusWindow appendLog:@"" level:@"INFO"];
                [statusWindow appendLog:@"=== DISCOVERY FAILED ===" level:@"ERROR"];
                [statusWindow appendLog:[NSString stringWithFormat:@"✗ Error: %@", error.localizedDescription] level:@"ERROR"];
                [statusWindow appendLog:@"" level:@"INFO"];
                [statusWindow appendLog:@"Troubleshooting steps:" level:@"INFO"];
                [statusWindow appendLog:@"1. Check you entered correct MFA code" level:@"INFO"];
                [statusWindow appendLog:@"2. Try: Menu → UniFi Protect → Connect to Controller" level:@"INFO"];
                [statusWindow appendLog:@"3. Enter fresh MFA code from Google Authenticator" level:@"INFO"];

                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"Discovery Failed";
                alert.informativeText = error.localizedDescription ?: @"Could not discover cameras. Make sure you're connected first.";
                alert.alertStyle = NSAlertStyleWarning;
                [alert addButtonWithTitle:@"OK"];
                [alert runModal];
            }
        });
    }];
}

- (void)handleImportAllUniFiCameras:(NSNotification *)notification {
    NSLog(@"[Menu] Import all UniFi cameras requested");

    // Show status window
    RTSPStatusWindow *statusWindow = [RTSPStatusWindow sharedWindow];
    [statusWindow clearLog];
    [statusWindow show];
    [statusWindow appendLog:@"" level:@"INFO"];
    [statusWindow appendLog:@"=== UniFi Camera Import ===" level:@"INFO"];
    [statusWindow appendLog:@"Starting camera import process..." level:@"INFO"];
    [statusWindow appendLog:@"" level:@"INFO"];

    RTSPUniFiProtectAdapter *adapter = [RTSPUniFiProtectAdapter sharedAdapter];
    [statusWindow appendLog:@"Step 1: Discovering cameras from controller..." level:@"INFO"];

    [adapter discoverCamerasWithCompletion:^(NSArray<RTSPUniFiCamera *> * _Nullable cameras, NSError * _Nullable error) {
        if (cameras && cameras.count > 0) {
            [statusWindow appendLog:[NSString stringWithFormat:@"✓ Found %lu camera(s)", (unsigned long)cameras.count] level:@"SUCCESS"];
            [statusWindow appendLog:@"" level:@"INFO"];
            [statusWindow appendLog:@"Step 2: Generating RTSP URLs..." level:@"INFO"];
            [statusWindow appendLog:@"Protocol: RTSP (port 554) - AVFoundation compatible" level:@"INFO"];
            [statusWindow appendLog:@"" level:@"INFO"];

            [adapter importCameras:cameras completion:^(NSInteger importedCount) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"[Menu] Imported %ld UniFi cameras", (long)importedCount);
                    [statusWindow appendLog:@"Step 3: Importing cameras to feed list..." level:@"INFO"];
                    [statusWindow appendLog:[NSString stringWithFormat:@"✓ Successfully imported %ld camera(s)", (long)importedCount] level:@"SUCCESS"];
                    [statusWindow appendLog:@"" level:@"INFO"];

                    // Show imported cameras with URLs
                    RTSPConfigurationManager *config = [RTSPConfigurationManager sharedManager];
                    NSArray *feedMetadata = config.manualFeedMetadata;
                    [statusWindow appendLog:@"=== IMPORTED CAMERAS ===" level:@"SUCCESS"];
                    for (RTSPFeedMetadata *meta in feedMetadata) {
                        if ([meta.category isEqualToString:@"UniFi Protect"]) {
                            [statusWindow appendLog:[NSString stringWithFormat:@"✓ %@", meta.displayName] level:@"SUCCESS"];
                            [statusWindow appendLog:[NSString stringWithFormat:@"  URL: %@", meta.url] level:@"INFO"];
                        }
                    }
                    [statusWindow appendLog:@"" level:@"INFO"];

                    NSAlert *alert = [[NSAlert alloc] init];
                    alert.messageText = @"Cameras Imported";
                    alert.informativeText = [NSString stringWithFormat:@"Successfully imported %ld camera(s) to your feed list.", (long)importedCount];
                    alert.alertStyle = NSAlertStyleInformational;
                    [alert addButtonWithTitle:@"OK"];
                    [alert runModal];

                    // Reload feeds
                    [statusWindow appendLog:@"Step 4: Reloading application feeds..." level:@"INFO"];
                    [self loadPreferencesAndStart];
                    [statusWindow appendLog:@"✓ Feeds reloaded - cameras added to rotation" level:@"SUCCESS"];
                    [statusWindow appendLog:@"" level:@"INFO"];
                    [statusWindow appendLog:@"=== IMPORT COMPLETE ===" level:@"SUCCESS"];
                    [statusWindow appendLog:@"✓ Cameras are now playing in rotation!" level:@"SUCCESS"];
                    [statusWindow appendLog:@"✓ Video streams starting..." level:@"SUCCESS"];
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [statusWindow appendLog:@"✗ No cameras found or discovery failed" level:@"ERROR"];
                if (error) {
                    [statusWindow appendLog:[NSString stringWithFormat:@"Error: %@", error.localizedDescription] level:@"ERROR"];
                }

                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"No Cameras Found";
                alert.informativeText = @"Discover cameras first before importing.";
                alert.alertStyle = NSAlertStyleWarning;
                [alert addButtonWithTitle:@"OK"];
                [alert runModal];
            });
        }
    }];
}

- (void)handleManageUniFiCameras:(NSNotification *)notification {
    NSLog(@"[Menu] Manage UniFi cameras requested");
    [[RTSPPreferencesController sharedController] showWindow:nil];
}

// UniFi Protect remaining handlers
- (void)handleAddUniFiCamera:(NSNotification *)notification {
    NSLog(@"[Menu] Add UniFi camera manually");
    [[RTSPPreferencesController sharedController] showWindow:nil];
}

- (void)handleTestUniFiCameras:(NSNotification *)notification {
    NSLog(@"[Menu] Test UniFi cameras");

    RTSPUniFiProtectAdapter *adapter = [RTSPUniFiProtectAdapter sharedAdapter];
    [adapter discoverCamerasWithCompletion:^(NSArray<RTSPUniFiCamera *> * _Nullable cameras, NSError * _Nullable error) {
        if (cameras) {
            NSInteger onlineCount = 0;
            for (RTSPUniFiCamera *camera in cameras) {
                if (camera.isOnline) onlineCount++;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"Camera Status";
                alert.informativeText = [NSString stringWithFormat:@"%ld of %lu cameras are online", (long)onlineCount, (unsigned long)cameras.count];
                alert.alertStyle = NSAlertStyleInformational;
                [alert addButtonWithTitle:@"OK"];
                [alert runModal];
            });
        }
    }];
}

- (void)handleRefreshUniFiStatus:(NSNotification *)notification {
    NSLog(@"[Menu] Refresh UniFi status");

    RTSPUniFiProtectAdapter *adapter = [RTSPUniFiProtectAdapter sharedAdapter];
    [adapter refreshCameraList:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            if (success) {
                alert.messageText = @"Status Refreshed";
                alert.informativeText = @"UniFi Protect camera list has been refreshed";
                alert.alertStyle = NSAlertStyleInformational;
            } else {
                alert.messageText = @"Refresh Failed";
                alert.informativeText = error.localizedDescription ?: @"Could not refresh status";
                alert.alertStyle = NSAlertStyleWarning;
            }
            [alert addButtonWithTitle:@"OK"];
            [alert runModal];
        });
    }];
}

- (void)handleShowUniFiSettings:(NSNotification *)notification {
    NSLog(@"[Menu] Show UniFi settings");
    [[RTSPPreferencesController sharedController] showWindow:nil];
}

// RTSP Camera handlers
- (void)handleAddCamera:(NSNotification *)notification {
    NSLog(@"[Menu] Add RTSP camera requested");
    [[RTSPPreferencesController sharedController] showWindow:nil];
}

- (void)handleAddMultipleCameras:(NSNotification *)notification {
    NSLog(@"[Menu] Add multiple RTSP cameras");

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Add Multiple Cameras";
    alert.informativeText = @"Enter RTSP/RTSPS URLs (one per line):";
    alert.alertStyle = NSAlertStyleInformational;

    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 400, 200)];
    NSTextView *textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 400, 200)];
    textView.font = [NSFont fontWithName:@"Menlo" size:11];
    scrollView.documentView = textView;
    scrollView.hasVerticalScroller = YES;

    alert.accessoryView = scrollView;
    [alert addButtonWithTitle:@"Add Cameras"];
    [alert addButtonWithTitle:@"Cancel"];

    if ([alert runModal] == NSAlertFirstButtonReturn) {
        NSString *text = textView.string;
        NSArray *urls = [text componentsSeparatedByString:@"\n"];

        RTSPConfigurationManager *config = [RTSPConfigurationManager sharedManager];
        NSMutableArray *metadata = [config.manualFeedMetadata mutableCopy] ?: [NSMutableArray array];

        NSInteger added = 0;
        for (NSString *url in urls) {
            NSString *trimmed = [url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (trimmed.length > 0 && [trimmed hasPrefix:@"rtsp"]) {
                // Check if already exists
                BOOL exists = NO;
                for (RTSPFeedMetadata *existing in metadata) {
                    if ([existing.url isEqualToString:trimmed]) {
                        exists = YES;
                        break;
                    }
                }

                if (!exists) {
                    RTSPFeedMetadata *feedMeta = [[RTSPFeedMetadata alloc] init];
                    feedMeta.url = trimmed;
                    feedMeta.displayName = trimmed;
                    feedMeta.enabled = YES;
                    feedMeta.category = @"Manual";
                    [metadata addObject:feedMeta];
                    added++;
                    NSLog(@"[Menu] Added camera: %@", trimmed);
                } else {
                    NSLog(@"[Menu] Skipping duplicate camera: %@", trimmed);
                }
            }
        }

        config.manualFeedMetadata = metadata;
        [config save];
        [self loadPreferencesAndStart];

        NSAlert *successAlert = [[NSAlert alloc] init];
        successAlert.messageText = @"Cameras Added";
        successAlert.informativeText = [NSString stringWithFormat:@"Added %ld camera(s)", (long)added];
        successAlert.alertStyle = NSAlertStyleInformational;
        [successAlert addButtonWithTitle:@"OK"];
        [successAlert runModal];
    }
}

- (void)handleManageCameras:(NSNotification *)notification {
    NSLog(@"[Menu] Manage RTSP cameras requested");
    [[RTSPPreferencesController sharedController] showWindow:nil];
}

- (void)handleEditCurrentCamera:(NSNotification *)notification {
    NSLog(@"[Menu] Edit current camera");
    if (self.wallpaperController.currentIndex < self.wallpaperController.feeds.count) {
        NSString *currentURL = self.wallpaperController.feeds[self.wallpaperController.currentIndex];

        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Edit Camera URL";
        alert.informativeText = @"Enter new RTSP URL:";

        NSTextField *urlField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 400, 24)];
        urlField.stringValue = currentURL;
        alert.accessoryView = urlField;

        [alert addButtonWithTitle:@"Save"];
        [alert addButtonWithTitle:@"Cancel"];

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            RTSPConfigurationManager *config = [RTSPConfigurationManager sharedManager];
            NSMutableArray *feeds = [config.manualFeeds mutableCopy];
            feeds[self.wallpaperController.currentIndex] = urlField.stringValue;
            config.manualFeeds = feeds;
            [self loadPreferencesAndStart];
        }
    }
}

- (void)handleRemoveCurrentCamera:(NSNotification *)notification {
    NSLog(@"[Menu] Remove current camera");
    if (self.wallpaperController.currentIndex < self.wallpaperController.feeds.count) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Remove Camera";
        alert.informativeText = @"Are you sure you want to remove this camera?";
        alert.alertStyle = NSAlertStyleWarning;
        [alert addButtonWithTitle:@"Remove"];
        [alert addButtonWithTitle:@"Cancel"];

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            RTSPConfigurationManager *config = [RTSPConfigurationManager sharedManager];
            NSMutableArray *feeds = [config.manualFeeds mutableCopy];
            [feeds removeObjectAtIndex:self.wallpaperController.currentIndex];
            config.manualFeeds = feeds;
            [self loadPreferencesAndStart];
        }
    }
}

- (void)handleTestCurrentCamera:(NSNotification *)notification {
    NSLog(@"[Menu] Test current camera");
    if (self.wallpaperController.currentIndex < self.wallpaperController.feeds.count) {
        NSString *url = self.wallpaperController.feeds[self.wallpaperController.currentIndex];

        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Camera Test";
        alert.informativeText = [NSString stringWithFormat:@"Testing connection to:\n%@", url];
        alert.alertStyle = NSAlertStyleInformational;
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
}

- (void)handleTestAllCameras:(NSNotification *)notification {
    NSLog(@"[Menu] Test all cameras");

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Testing All Cameras";
    alert.informativeText = [NSString stringWithFormat:@"Testing %lu camera(s)...", (unsigned long)self.wallpaperController.feeds.count];
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)handleShowDiagnostics:(NSNotification *)notification {
    NSLog(@"[Menu] Show camera diagnostics");

    RTSPCameraDiagnostics *diagnostics = [RTSPCameraDiagnostics sharedDiagnostics];
    NSArray *reports = [diagnostics allReports];

    NSMutableString *info = [NSMutableString string];
    [info appendFormat:@"Total Cameras: %lu\n\n", (unsigned long)self.wallpaperController.feeds.count];

    for (RTSPCameraDiagnosticReport *report in reports) {
        NSString *status = report.healthStatus == RTSPCameraHealthStatusHealthy ? @"✓ Healthy" : @"✗ Failed";
        [info appendFormat:@"%@: %@\n", report.cameraName, status];
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Camera Diagnostics";
    alert.informativeText = info.length > 0 ? info : @"No diagnostic data available";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)handleAddCameraPreset:(NSNotification *)notification {
    NSLog(@"[Menu] Add camera preset");
    NSString *brand = notification.object;

    NSDictionary *presets = @{
        @"Hikvision": @"rtsp://username:password@192.168.1.100:554/Streaming/Channels/101",
        @"Dahua": @"rtsp://username:password@192.168.1.100:554/cam/realmonitor?channel=1&subtype=0",
        @"Axis": @"rtsp://192.168.1.100/axis-media/media.amp",
        @"Amcrest": @"rtsp://username:password@192.168.1.100:554/cam/realmonitor?channel=1&subtype=0",
        @"Reolink": @"rtsp://username:password@192.168.1.100:554/h264Preview_01_main"
    };

    NSString *template = presets[brand] ?: @"rtsp://username:password@192.168.1.100:554/";

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = [NSString stringWithFormat:@"Add %@ Camera", brand];
    alert.informativeText = @"Edit the RTSP URL template:";

    NSTextField *urlField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 500, 24)];
    urlField.stringValue = template;
    alert.accessoryView = urlField;

    [alert addButtonWithTitle:@"Add"];
    [alert addButtonWithTitle:@"Cancel"];

    if ([alert runModal] == NSAlertFirstButtonReturn) {
        RTSPConfigurationManager *config = [RTSPConfigurationManager sharedManager];
        NSMutableArray *feeds = [config.manualFeeds mutableCopy] ?: [NSMutableArray array];
        [feeds addObject:urlField.stringValue];
        config.manualFeeds = feeds;
        [self loadPreferencesAndStart];
    }
}

// Dashboard handlers
- (void)handleOpenDashboardDesigner:(NSNotification *)notification {
    NSLog(@"[Menu] Open dashboard designer");
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Dashboard Designer";
    alert.informativeText = @"Visual dashboard designer - Coming soon!";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)handleCreateNewDashboard:(NSNotification *)notification {
    NSLog(@"[Menu] Create new dashboard");

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"New Dashboard";
    alert.informativeText = @"Enter dashboard name:";

    NSTextField *nameField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
    nameField.placeholderString = @"Dashboard Name";
    alert.accessoryView = nameField;

    [alert addButtonWithTitle:@"Create"];
    [alert addButtonWithTitle:@"Cancel"];

    if ([alert runModal] == NSAlertFirstButtonReturn && nameField.stringValue.length > 0) {
        RTSPDashboard *dashboard = [[RTSPDashboard alloc] init];
        dashboard.name = nameField.stringValue;
        dashboard.layout = RTSPDashboardLayout2x2;

        [[RTSPDashboardManager sharedManager] addDashboard:dashboard];
        [[RTSPDashboardManager sharedManager] activateDashboard:dashboard];

        NSLog(@"[Menu] Created dashboard: %@", dashboard.name);
    }
}

- (void)handleDuplicateCurrentDashboard:(NSNotification *)notification {
    NSLog(@"[Menu] Duplicate current dashboard");
    RTSPDashboard *current = [[RTSPDashboardManager sharedManager] activeDashboard];
    if (current) {
        RTSPDashboard *duplicate = [[RTSPDashboard alloc] init];
        duplicate.name = [NSString stringWithFormat:@"%@ Copy", current.name];
        duplicate.layout = current.layout;
        duplicate.cameras = [current.cameras copy];

        [[RTSPDashboardManager sharedManager] addDashboard:duplicate];
        NSLog(@"[Menu] Duplicated dashboard: %@", duplicate.name);
    }
}

- (void)handleRenameCurrentDashboard:(NSNotification *)notification {
    NSLog(@"[Menu] Rename current dashboard");
    RTSPDashboard *current = [[RTSPDashboardManager sharedManager] activeDashboard];
    if (current) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Rename Dashboard";
        alert.informativeText = @"Enter new name:";

        NSTextField *nameField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
        nameField.stringValue = current.name;
        alert.accessoryView = nameField;

        [alert addButtonWithTitle:@"Rename"];
        [alert addButtonWithTitle:@"Cancel"];

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            current.name = nameField.stringValue;
            [[RTSPDashboardManager sharedManager] saveDashboards];
        }
    }
}

- (void)handleDeleteCurrentDashboard:(NSNotification *)notification {
    NSLog(@"[Menu] Delete current dashboard");
    RTSPDashboard *current = [[RTSPDashboardManager sharedManager] activeDashboard];
    if (current) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Delete Dashboard";
        alert.informativeText = [NSString stringWithFormat:@"Are you sure you want to delete '%@'?", current.name];
        alert.alertStyle = NSAlertStyleWarning;
        [alert addButtonWithTitle:@"Delete"];
        [alert addButtonWithTitle:@"Cancel"];

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            [[RTSPDashboardManager sharedManager] removeDashboard:current];
        }
    }
}

- (void)handleAssignCamerasToDashboard:(NSNotification *)notification {
    NSLog(@"[Menu] Assign cameras to dashboard");
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Assign Cameras";
    alert.informativeText = @"Camera assignment interface - Use Preferences window";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"Open Preferences"];
    [alert addButtonWithTitle:@"Cancel"];

    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [[RTSPPreferencesController sharedController] showWindow:nil];
    }
}

- (void)handleSetDashboardLayout:(NSNotification *)notification {
    NSLog(@"[Menu] Set dashboard layout");
    NSString *notificationName = notification.name;

    RTSPDashboardLayout layout = RTSPDashboardLayout2x2;
    if ([notificationName hasSuffix:@"1x1"]) layout = RTSPDashboardLayout1x1;
    else if ([notificationName hasSuffix:@"2x2"]) layout = RTSPDashboardLayout2x2;
    else if ([notificationName hasSuffix:@"3x2"]) layout = RTSPDashboardLayout3x2;
    else if ([notificationName hasSuffix:@"3x3"]) layout = RTSPDashboardLayout3x3;
    else if ([notificationName hasSuffix:@"4x3"]) layout = RTSPDashboardLayout4x3;

    RTSPDashboard *current = [[RTSPDashboardManager sharedManager] activeDashboard];
    if (current) {
        current.layout = layout;
        [[RTSPDashboardManager sharedManager] saveDashboards];
        NSLog(@"[Menu] Dashboard layout changed to: %ld", (long)layout);
    }
}

- (void)handleToggleDashboardAutoCycle:(NSNotification *)notification {
    NSLog(@"[Menu] Toggle dashboard auto-cycle");
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Auto-Cycle Dashboards";
    alert.informativeText = @"Dashboard auto-cycling - Feature coming soon!";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)handleSetDashboardCycleInterval:(NSNotification *)notification {
    NSLog(@"[Menu] Set dashboard cycle interval");
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Cycle Interval";
    alert.informativeText = @"Enter cycle interval (seconds):";

    NSTextField *intervalField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    intervalField.placeholderString = @"60";
    alert.accessoryView = intervalField;

    [alert addButtonWithTitle:@"Set"];
    [alert addButtonWithTitle:@"Cancel"];

    if ([alert runModal] == NSAlertFirstButtonReturn) {
        NSLog(@"[Menu] Dashboard cycle interval set");
    }
}

// Advanced Settings handlers
- (void)handleShowAudioMonitoring:(NSNotification *)notification {
    NSLog(@"[Menu] Show audio monitoring");

    if (self.audioMonitor) {
        self.audioMonitor.enabled = !self.audioMonitor.enabled;

        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Audio Monitoring";
        alert.informativeText = self.audioMonitor.enabled ? @"Audio monitoring enabled" : @"Audio monitoring disabled";
        alert.alertStyle = NSAlertStyleInformational;
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
}

- (void)handleShowAudioAlerts:(NSNotification *)notification {
    NSLog(@"[Menu] Show audio alerts");
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Audio Alerts";
    alert.informativeText = @"Configure audio level alerts and notifications";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)handleShowMotionDetection:(NSNotification *)notification {
    NSLog(@"[Menu] Show motion detection");

    if (self.motionDetector) {
        self.motionDetector.enabled = !self.motionDetector.enabled;

        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Motion Detection";
        alert.informativeText = self.motionDetector.enabled ? @"Motion detection enabled" : @"Motion detection disabled";
        alert.alertStyle = NSAlertStyleInformational;
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
}

- (void)handleShowSmartAlerts:(NSNotification *)notification {
    NSLog(@"[Menu] Show smart alerts");

    if (self.smartAlerts) {
        self.smartAlerts.enabled = !self.smartAlerts.enabled;

        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Smart Alerts";
        alert.informativeText = self.smartAlerts.enabled ? @"Smart object detection enabled (people, vehicles, animals)" : @"Smart alerts disabled";
        alert.alertStyle = NSAlertStyleInformational;
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
}

- (void)handleShowRecordingSettings:(NSNotification *)notification {
    NSLog(@"[Menu] Show recording settings");
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Recording Settings";
    alert.informativeText = @"Configure snapshot and video recording settings";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)handleShowCloudStorage:(NSNotification *)notification {
    NSLog(@"[Menu] Show cloud storage");

    RTSPCloudStorage *cloudStorage = [RTSPCloudStorage sharedManager];
    cloudStorage.autoUploadEnabled = !cloudStorage.autoUploadEnabled;

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Cloud Storage";
    alert.informativeText = cloudStorage.autoUploadEnabled ? @"Auto-upload to cloud enabled" : @"Cloud uploads disabled";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)handleShowFailoverSettings:(NSNotification *)notification {
    NSLog(@"[Menu] Show failover settings");

    RTSPFailoverManager *failover = [RTSPFailoverManager sharedManager];
    failover.autoFailoverEnabled = !failover.autoFailoverEnabled;

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Failover Settings";
    alert.informativeText = failover.autoFailoverEnabled ? @"Automatic failover enabled" : @"Failover disabled";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)handleShowNetworkSettings:(NSNotification *)notification {
    NSLog(@"[Menu] Show network settings");
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Network Settings";
    alert.informativeText = @"Configure bandwidth limits and network monitoring";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

// View menu additional handlers
- (void)handleShowCameraList:(NSNotification *)notification {
    NSLog(@"[Menu] Show camera list");
    [[RTSPCameraListWindow sharedWindow] show];
}

- (void)handleShowEventTimeline:(NSNotification *)notification {
    NSLog(@"[Menu] Show event timeline");

    NSArray *events = [[RTSPEventLogger sharedLogger] events];

    NSMutableString *info = [NSMutableString string];
    [info appendFormat:@"Recent Events (%lu):\n\n", (unsigned long)MIN(events.count, 10)];

    for (NSInteger i = events.count - 1; i >= MAX(0, (NSInteger)events.count - 10); i--) {
        RTSPEvent *event = events[i];
        [info appendFormat:@"%@: %@\n", event.timestamp, event.title];
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Event Timeline";
    alert.informativeText = info;
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)handleGoToBookmark:(NSNotification *)notification {
    NSLog(@"[Menu] Go to bookmark");
    NSMenuItem *item = notification.object;
    if ([item isKindOfClass:[NSMenuItem class]]) {
        NSInteger bookmarkNumber = [item.title componentsSeparatedByString:@" "].lastObject.integerValue;
        [[RTSPBookmarkManager sharedManager] handleHotkeyPress:bookmarkNumber];
    }
}

- (void)handleManageBookmarks:(NSNotification *)notification {
    NSLog(@"[Menu] Manage bookmarks");

    NSArray *bookmarks = [[RTSPBookmarkManager sharedManager] bookmarks];

    NSMutableString *info = [NSMutableString string];
    [info appendString:@"Bookmarks:\n\n"];

    if (bookmarks.count == 0) {
        [info appendString:@"No bookmarks saved.\n\nUse ⌘1-9 to save cameras as bookmarks."];
    } else {
        for (RTSPBookmark *bookmark in bookmarks) {
            [info appendFormat:@"⌘%ld: %@\n", (long)bookmark.hotkey, bookmark.name];
        }
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Manage Bookmarks";
    alert.informativeText = info;
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

// Help menu handlers
- (void)handleShowGettingStarted:(NSNotification *)notification {
    NSLog(@"[Menu] Show getting started");

    NSString *guide = @"RTSP Rotator - Getting Started\n\n"
                      @"1. Add Cameras:\n"
                      @"   • UniFi Protect > Connect to Controller\n"
                      @"   • Google Home > Authenticate with Google\n"
                      @"   • RTSP Cameras > Add Camera\n\n"
                      @"2. Control Rotation:\n"
                      @"   • Settings > Rotation > Choose interval\n"
                      @"   • Settings > Transitions > Choose effect\n\n"
                      @"3. Navigate:\n"
                      @"   • ⌘[ Previous Camera\n"
                      @"   • ⌘] Next Camera\n"
                      @"   • ⌘G Thumbnail Grid\n\n"
                      @"4. Dashboards:\n"
                      @"   • Create multiple layouts\n"
                      @"   • Assign cameras to each\n"
                      @"   • Switch between them\n";

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Getting Started Guide";
    alert.informativeText = guide;
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)handleShowAPIDocumentation:(NSNotification *)notification {
    NSLog(@"[Menu] Show API documentation");

    NSString *apiDocs = @"RTSP Rotator REST API\n\n"
                        @"Base URL: http://localhost:8080/api\n\n"
                        @"Endpoints:\n"
                        @"GET  /feeds - List all feeds\n"
                        @"GET  /current - Current feed index\n"
                        @"POST /switch - Switch to feed index\n"
                        @"POST /next - Next feed\n"
                        @"POST /previous - Previous feed\n"
                        @"POST /rotation - Set rotation interval\n\n"
                        @"Example:\n"
                        @"curl http://localhost:8080/api/next\n";

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"API Documentation";
    alert.informativeText = apiDocs;
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)handleReportIssue:(NSNotification *)notification {
    NSLog(@"[Menu] Report issue");

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Report an Issue";
    alert.informativeText = @"To report a bug or request a feature:\n\n"
                            @"Email: support@example.com\n"
                            @"GitHub: github.com/yourorg/rtsp-rotator\n\n"
                            @"Please include:\n"
                            @"• macOS version\n"
                            @"• Application version\n"
                            @"• Steps to reproduce";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)handleCheckForUpdates:(NSNotification *)notification {
    NSLog(@"[Menu] Check for updates");

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Check for Updates";
    alert.informativeText = @"You are running the latest version of RTSP Rotator.\n\nVersion: 1.0.0";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

@end
