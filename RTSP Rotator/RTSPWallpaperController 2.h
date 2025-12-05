//
//  RTSPWallpaperController.h
//  RTSP Rotator
//
//  Created by Jordan Koch on 10/29/25.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Main controller for managing RTSP feed rotation and playback
@interface RTSPWallpaperController : NSObject

/// Initialize with feeds and rotation interval
- (instancetype)initWithFeeds:(NSArray<NSString *> *)feeds rotationInterval:(NSTimeInterval)interval;

/// Setup with existing view (for standard app mode)
- (void)setupWithView:(NSView *)view;

/// Setup with existing window (for standard app mode)
- (void)setupWithWindow:(NSWindow *)window;

/// Start playback and rotation
- (void)start;

/// Stop playback and rotation
- (void)stop;

/// Switch to next feed
- (void)nextFeed;

/// Play current feed (useful for API/bookmark integration)
- (void)playCurrentFeed;

/// Toggle audio mute
- (void)toggleMute;

/// Set feeds array
- (void)setFeeds:(NSArray<NSString *> *)feeds;

/// Whether audio is muted
@property (nonatomic, assign) BOOL isMuted;

/// Current feed index
@property (nonatomic, assign) NSUInteger currentIndex;

/// Array of feed URLs
@property (nonatomic, strong, readonly) NSArray<NSString *> *feeds;

/// Rotation interval in seconds
@property (nonatomic, assign) NSTimeInterval rotationInterval;

/// Parent view (when used in standard app mode)
@property (nonatomic, weak, nullable) NSView *parentView;

/// AVPlayer instance (for monitoring features)
@property (nonatomic, strong, readonly, nullable) AVPlayer *player;

@end

NS_ASSUME_NONNULL_END
