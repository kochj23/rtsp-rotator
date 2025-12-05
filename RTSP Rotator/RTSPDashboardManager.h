//
//  RTSPDashboardManager.h
//  RTSP Rotator
//
//  Multi-dashboard management system
//  Supports up to 36 cameras across multiple dashboards
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTSPDashboardLayout) {
    RTSPDashboardLayout1x1 = 1,   // 1 camera (full screen)
    RTSPDashboardLayout2x2 = 4,   // 4 cameras (2x2 grid)
    RTSPDashboardLayout3x2 = 6,   // 6 cameras (3x2 grid)
    RTSPDashboardLayout3x3 = 9,   // 9 cameras (3x3 grid)
    RTSPDashboardLayout4x3 = 12   // 12 cameras (4x3 grid)
};

@class RTSPDashboard;

/// Individual camera configuration
@interface RTSPCameraConfig : NSObject <NSCoding, NSSecureCoding>

@property (nonatomic, strong) NSString *cameraID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSURL *feedURL;
@property (nonatomic, strong, nullable) NSString *username;
@property (nonatomic, strong, nullable) NSString *password;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL isMuted;

// Camera metadata
@property (nonatomic, strong, nullable) NSString *location;
@property (nonatomic, strong, nullable) NSString *cameraType; // "RTSP", "GoogleHome", "HTTP", etc.
@property (nonatomic, strong, nullable) NSDictionary *customSettings;

// Grid position (optional, for fixed layouts)
@property (nonatomic, assign) NSInteger gridRow;
@property (nonatomic, assign) NSInteger gridColumn;

@end

/// Dashboard configuration
@interface RTSPDashboard : NSObject <NSCoding, NSSecureCoding>

@property (nonatomic, strong) NSString *dashboardID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray<RTSPCameraConfig *> *cameras;
@property (nonatomic, assign) RTSPDashboardLayout layout;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) NSTimeInterval rotationInterval;
@property (nonatomic, assign) BOOL autoRotate;

// Display options
@property (nonatomic, assign) BOOL showLabels;
@property (nonatomic, assign) BOOL showTimestamp;
@property (nonatomic, assign) BOOL syncPlayback; // Start all feeds at same time

/// Add camera to dashboard
- (void)addCamera:(RTSPCameraConfig *)camera;

/// Remove camera from dashboard
- (void)removeCamera:(RTSPCameraConfig *)camera;

/// Validate camera count for layout
- (BOOL)canAddMoreCameras;

/// Get maximum cameras for current layout
- (NSInteger)maxCamerasForLayout;

@end

@class RTSPDashboardManager;

/// Dashboard manager delegate
@protocol RTSPDashboardManagerDelegate <NSObject>
@optional
- (void)dashboardManager:(RTSPDashboardManager *)manager didActivateDashboard:(RTSPDashboard *)dashboard;
- (void)dashboardManager:(RTSPDashboardManager *)manager didDeactivateDashboard:(RTSPDashboard *)dashboard;
- (void)dashboardManager:(RTSPDashboardManager *)manager didUpdateDashboard:(RTSPDashboard *)dashboard;
@end

/// Multi-dashboard management system
@interface RTSPDashboardManager : NSObject

/// Shared instance
+ (instancetype)sharedManager;

/// Delegate for dashboard events
@property (nonatomic, weak) id<RTSPDashboardManagerDelegate> delegate;

/// All dashboards
- (NSArray<RTSPDashboard *> *)dashboards;

/// Currently active dashboard
@property (nonatomic, strong, nullable) RTSPDashboard *activeDashboard;

/// Auto-rotation between dashboards
@property (nonatomic, assign) BOOL autoCycleDashboards;
@property (nonatomic, assign) NSTimeInterval dashboardCycleInterval; // Default: 300 (5 minutes)

/// Add dashboard
- (void)addDashboard:(RTSPDashboard *)dashboard;

/// Remove dashboard
- (void)removeDashboard:(RTSPDashboard *)dashboard;

/// Update dashboard
- (void)updateDashboard:(RTSPDashboard *)dashboard;

/// Get dashboard by ID
- (nullable RTSPDashboard *)dashboardWithID:(NSString *)dashboardID;

/// Activate specific dashboard
- (void)activateDashboard:(RTSPDashboard *)dashboard;

/// Switch to next dashboard
- (void)switchToNextDashboard;

/// Switch to previous dashboard
- (void)switchToPreviousDashboard;

/// Start auto-cycling between dashboards
- (void)startDashboardCycling;

/// Stop auto-cycling
- (void)stopDashboardCycling;

/// Save dashboards to disk
- (BOOL)saveDashboards;

/// Load dashboards from disk
- (BOOL)loadDashboards;

/// Import cameras from array of URLs
- (NSArray<RTSPCameraConfig *> *)importCamerasFromURLs:(NSArray<NSString *> *)urls;

/// Create default dashboards (example setup)
- (void)createDefaultDashboards;

@end

NS_ASSUME_NONNULL_END
