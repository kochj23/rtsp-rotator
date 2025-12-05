//
//  RTSPMenuBarController.h
//  RTSP Rotator
//
//  Comprehensive menu bar controller for all application features
//

#import <Cocoa/Cocoa.h>

@class RTSPWallpaperController;
@class RTSPGoogleHomeAdapter;
@class RTSPUniFiProtectAdapter;
@class RTSPDashboardManager;
@class RTSPCameraTypeManager;

@interface RTSPMenuBarController : NSObject

@property (nonatomic, weak) RTSPWallpaperController *wallpaperController;
@property (nonatomic, strong) NSWindow *mainWindow;

- (instancetype)initWithWallpaperController:(RTSPWallpaperController *)controller window:(NSWindow *)window;
- (void)setupApplicationMenus;

@end
