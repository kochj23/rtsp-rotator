//
//  RTSPVLCPlayerController.h
//  RTSP Rotator
//
//  VLCKit-based player for RTSPS streams with self-signed certificate support
//  Alternative to AVPlayer when RTSPS is required
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief VLCKit-based video player controller for RTSPS stream support
 *
 * This controller uses VLCKit instead of AVFoundation to play RTSPS streams.
 * VLCKit fully supports RTSPS with self-signed certificates, making it ideal
 * for UniFi Protect, Hikvision, Dahua, and other cameras with secure RTSP.
 *
 * @discussion AVFoundation's AVPlayer cannot handle RTSPS with self-signed
 * certificates. VLCKit solves this limitation and provides superior codec support.
 *
 * @note REQUIRES VLCKit framework to be installed. Install via:
 * - CocoaPods: pod 'VLCKit'
 * - Manual: Download from https://code.videolan.org/videolan/VLCKit
 *
 * Usage:
 * @code
 * RTSPVLCPlayerController *player = [[RTSPVLCPlayerController alloc] init];
 * player.allowSelfSignedCertificates = YES;
 * [player setupWithView:self.videoView];
 * [player playURL:[NSURL URLWithString:@"rtsps://camera.local:7441/stream"]];
 * @endcode
 */
@interface RTSPVLCPlayerController : NSObject

#pragma mark - Configuration

/**
 * Allow self-signed SSL certificates for RTSPS
 * Default: YES (required for local camera systems)
 */
@property (nonatomic, assign) BOOL allowSelfSignedCertificates;

/**
 * Whether audio is muted
 */
@property (nonatomic, assign) BOOL isMuted;

/**
 * Current playback URL
 */
@property (nonatomic, strong, readonly, nullable) NSURL *currentURL;

/**
 * Is player currently playing
 */
@property (nonatomic, assign, readonly) BOOL isPlaying;

#pragma mark - Setup

/**
 * Setup player with a target view for video display
 *
 * @param view View to display video in
 */
- (void)setupWithView:(NSView *)view;

#pragma mark - Playback Control

/**
 * Play an RTSP or RTSPS URL
 *
 * @param url RTSP or RTSPS URL to play
 */
- (void)playURL:(NSURL *)url;

/**
 * Stop playback and clean up resources
 */
- (void)stop;

/**
 * Toggle audio mute
 */
- (void)toggleMute;

#pragma mark - VLCKit Availability

/**
 * Check if VLCKit framework is available
 *
 * @return YES if VLCKit is installed and available, NO otherwise
 */
+ (BOOL)isVLCKitAvailable;

@end

NS_ASSUME_NONNULL_END
