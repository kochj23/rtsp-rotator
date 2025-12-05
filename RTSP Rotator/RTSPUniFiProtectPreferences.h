//
//  RTSPUniFiProtectPreferences.h
//  RTSP Rotator
//
//  UniFi Protect configuration and camera import UI
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// Controller for UniFi Protect configuration window
@interface RTSPUniFiProtectPreferences : NSWindowController

/// Singleton instance
+ (instancetype)sharedController;

/// Show the UniFi Protect preferences window
- (void)showWindow:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
