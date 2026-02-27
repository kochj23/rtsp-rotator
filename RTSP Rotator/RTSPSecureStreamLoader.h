//
//  RTSPSecureStreamLoader.h
//  RTSP Rotator
//
//  Custom resource loader for RTSPS streams with self-signed certificate support
//  Enables secure RTSP (RTSPS) playback with UniFi Protect and other cameras
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Custom resource loader that handles RTSPS URLs with self-signed certificates
 *
 * This class enables AVPlayer to play RTSPS streams from cameras with self-signed
 * SSL certificates (common with UniFi Protect, Hikvision, Dahua, etc.)
 *
 * @discussion AVFoundation's AVPlayer doesn't natively support RTSPS with self-signed
 * certificates. This class acts as a bridge, handling the TLS connection and certificate
 * validation, then feeding the stream data to AVPlayer.
 *
 * Usage:
 * @code
 * // Create loader for a camera
 * RTSPSecureStreamLoader *loader = [[RTSPSecureStreamLoader alloc] init];
 * loader.allowSelfSignedCertificates = YES;
 *
 * // Convert rtsps:// URL to custom scheme
 * NSURL *originalURL = [NSURL URLWithString:@"rtsps://10.0.0.1:7441/stream"];
 * NSURL *customURL = [loader customURLForRTSPSURL:originalURL];
 *
 * // Create asset with resource loader
 * AVURLAsset *asset = [AVURLAsset URLAssetWithURL:customURL options:nil];
 * [asset.resourceLoader setDelegate:loader queue:dispatch_get_main_queue()];
 *
 * // Create player item and play
 * AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
 * AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
 * [player play];
 * @endcode
 */
@interface RTSPSecureStreamLoader : NSObject <AVAssetResourceLoaderDelegate, NSURLSessionDataDelegate>

#pragma mark - Configuration

/**
 * Allow self-signed SSL certificates
 * Default: YES (for local camera systems)
 */
@property (nonatomic, assign) BOOL allowSelfSignedCertificates;

/**
 * Allow expired certificates
 * Default: NO
 */
@property (nonatomic, assign) BOOL allowExpiredCertificates;

/**
 * Custom SSL certificate to trust (optional)
 * If provided, only this specific certificate will be trusted
 */
@property (nonatomic, strong, nullable) NSData *trustedCertificateData;

/**
 * Enable verbose logging for debugging
 * Default: NO
 */
@property (nonatomic, assign) BOOL verboseLogging;

#pragma mark - URL Conversion

/**
 * Convert RTSPS URL to custom scheme URL for AVPlayer
 *
 * This method converts an rtsps:// URL to a custom scheme (rtspssecure://)
 * that AVPlayer will send to our resource loader delegate.
 *
 * @param rtspsURL Original RTSPS URL (rtsps://...)
 * @return Custom scheme URL that routes through this loader
 */
- (NSURL *)customURLForRTSPSURL:(NSURL *)rtspsURL;

/**
 * Convert custom scheme URL back to original RTSPS URL
 *
 * @param customURL Custom scheme URL (rtspssecure://...)
 * @return Original RTSPS URL
 */
- (NSURL *)rtspsURLFromCustomURL:(NSURL *)customURL;

#pragma mark - Stream Testing

/**
 * Test if an RTSPS URL is accessible with current certificate settings
 *
 * @param url RTSPS URL to test
 * @param completion Completion handler with success status and error
 */
- (void)testRTSPSURL:(NSURL *)url
          completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
