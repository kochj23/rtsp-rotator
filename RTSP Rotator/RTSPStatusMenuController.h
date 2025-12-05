//
//  RTSPStatusMenuController.h
//  RTSP Rotator
//
//  Created by Jordan Koch on 10/29/25.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class RTSPWallpaperController;

/// Manages the status bar menu item
@interface RTSPStatusMenuController : NSObject

/// Initialize with controller reference
- (instancetype)initWithController:(RTSPWallpaperController *)controller;

/// Install status item in menu bar
- (void)install;

/// Remove status item from menu bar
- (void)uninstall;

/// Update status item with current feed info
- (void)updateWithFeedName:(NSString *)feedName index:(NSInteger)index total:(NSInteger)total;

/// Update health status indicator
- (void)updateHealthStatus:(NSString *)status;

/// Whether status item is installed
@property (nonatomic, assign, readonly) BOOL isInstalled;

@end

NS_ASSUME_NONNULL_END
