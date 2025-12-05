//
//  RTSPCameraListWindow.h
//  RTSP Rotator
//
//  Camera list viewer with status and connection testing
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTSPCameraListWindow : NSWindowController

/// Singleton instance
+ (instancetype)sharedWindow;

/// Show the camera list window
- (void)show;

/// Refresh camera list
- (void)refresh;

@end

NS_ASSUME_NONNULL_END
