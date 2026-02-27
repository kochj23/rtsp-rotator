//
//  RTSPFFmpegProxy.h
//  RTSP Rotator
//
//  FFmpeg-based proxy for RTSPS streams with self-signed certificate support
//  Converts RTSPS → local RTSP for AVFoundation compatibility
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief FFmpeg proxy that converts RTSPS streams to local RTSP streams
 *
 * This class solves the AVFoundation + RTSPS + self-signed certificate limitation
 * by running local FFmpeg processes that:
 * 1. Accept RTSPS streams with self-signed certificates
 * 2. Transcode to local RTSP streams
 * 3. AVFoundation plays the local streams
 *
 * Architecture:
 * @code
 * RTSPS Camera → FFmpeg Process → rtsp://localhost:PORT → AVFoundation ✅
 *    (port 7441)     (handles cert)     (local stream)      (can play!)
 * @endcode
 *
 * Usage:
 * @code
 * RTSPFFmpegProxy *proxy = [RTSPFFmpegProxy sharedProxy];
 *
 * // Convert RTSPS URL to local RTSP
 * NSURL *rtspsURL = [NSURL URLWithString:@"rtsps://10.0.0.1:7441/alias"];
 * NSURL *localURL = [proxy startProxyForURL:rtspsURL cameraName:@"Front Door"];
 *
 * // Use local URL with AVPlayer
 * AVPlayerItem *item = [AVPlayerItem playerItemWithURL:localURL];
 * [player replaceCurrentItemWithPlayerItem:item];
 * @endcode
 */
@interface RTSPFFmpegProxy : NSObject

#pragma mark - Singleton

/**
 * Shared proxy manager instance
 */
+ (instancetype)sharedProxy;

#pragma mark - Proxy Management

/**
 * Start FFmpeg proxy for an RTSPS URL
 *
 * Creates a local RTSP stream that AVFoundation can play
 *
 * @param rtspsURL Original RTSPS URL (with self-signed cert)
 * @param cameraName Camera name for logging
 * @return Local RTSP URL (rtsp://localhost:PORT) or nil on failure
 */
- (nullable NSURL *)startProxyForURL:(NSURL *)rtspsURL cameraName:(NSString *)cameraName;

/**
 * Stop proxy for a specific URL
 *
 * @param rtspsURL Original RTSPS URL
 */
- (void)stopProxyForURL:(NSURL *)rtspsURL;

/**
 * Stop all proxies
 */
- (void)stopAllProxies;

/**
 * Check if proxy is running for URL
 *
 * @param rtspsURL Original RTSPS URL
 * @return YES if proxy is active
 */
- (BOOL)isProxyRunningForURL:(NSURL *)rtspsURL;

/**
 * Get local URL for an RTSPS URL
 *
 * @param rtspsURL Original RTSPS URL
 * @return Local RTSP URL if proxy is running, nil otherwise
 */
- (nullable NSURL *)localURLForRTSPSURL:(NSURL *)rtspsURL;

#pragma mark - Configuration

/**
 * Base port for local RTSP servers
 * Default: 18554
 * Each proxy gets basePort + index
 */
@property (nonatomic, assign) NSInteger basePort;

/**
 * Enable verbose FFmpeg logging
 * Default: NO
 */
@property (nonatomic, assign) BOOL verboseLogging;

/**
 * FFmpeg path
 * Default: /opt/homebrew/bin/ffmpeg or /usr/local/bin/ffmpeg
 */
@property (nonatomic, strong) NSString *ffmpegPath;

#pragma mark - Status

/**
 * Number of active proxies
 */
@property (nonatomic, readonly) NSInteger activeProxyCount;

/**
 * Get status information for all proxies
 *
 * @return Array of dictionaries with proxy status
 */
- (NSArray<NSDictionary *> *)proxyStatus;

@end

NS_ASSUME_NONNULL_END
