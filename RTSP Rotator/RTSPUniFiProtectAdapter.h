//
//  RTSPUniFiProtectAdapter.h
//  RTSP Rotator
//
//  UniFi Protect integration for automatic camera discovery and configuration
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RTSPUniFiProtectAdapter;
@class RTSPUniFiCamera;

#pragma mark - UniFi Camera Model

/// Represents a UniFi Protect camera
@interface RTSPUniFiCamera : NSObject <NSCoding, NSSecureCoding>

/// Camera ID (unique identifier from UniFi)
@property (nonatomic, strong) NSString *cameraId;

/// Camera name (from UniFi Protect)
@property (nonatomic, strong) NSString *name;

/// Camera model (e.g., "UVC-G3-FLEX", "UVC-G4-PRO")
@property (nonatomic, strong) NSString *model;

/// Camera MAC address
@property (nonatomic, strong) NSString *macAddress;

/// Camera IP address
@property (nonatomic, strong) NSString *ipAddress;

/// Camera firmware version
@property (nonatomic, strong, nullable) NSString *firmwareVersion;

/// Is camera online
@property (nonatomic, assign) BOOL isOnline;

/// Camera supports RTSP
@property (nonatomic, assign) BOOL supportsRTSP;

/// RTSP port (default: 7447 for UniFi)
@property (nonatomic, assign) NSInteger rtspPort;

/// RTSP channel (default: 0 for main stream, 1 for sub stream)
@property (nonatomic, assign) NSInteger rtspChannel;

/// Generated RTSP URL
@property (nonatomic, strong, nullable) NSString *rtspURL;

/// Camera type (fixed, dome, bullet, etc.)
@property (nonatomic, strong, nullable) NSString *cameraType;

/// Last seen timestamp
@property (nonatomic, strong, nullable) NSDate *lastSeen;

/// Raw JSON data from UniFi Protect API
@property (nonatomic, strong, nullable) NSDictionary *rawData;

@end

#pragma mark - Delegate Protocol

/// Delegate for UniFi Protect adapter events
@protocol RTSPUniFiProtectAdapterDelegate <NSObject>
@optional

/// Called when authentication succeeds
- (void)unifiProtectAdapterDidAuthenticate:(RTSPUniFiProtectAdapter *)adapter;

/// Called when authentication fails
- (void)unifiProtectAdapter:(RTSPUniFiProtectAdapter *)adapter didFailAuthenticationWithError:(NSError *)error;

/// Called when cameras are discovered
- (void)unifiProtectAdapter:(RTSPUniFiProtectAdapter *)adapter didDiscoverCameras:(NSArray<RTSPUniFiCamera *> *)cameras;

/// Called when camera discovery fails
- (void)unifiProtectAdapter:(RTSPUniFiProtectAdapter *)adapter didFailDiscoveryWithError:(NSError *)error;

@end

#pragma mark - UniFi Protect Adapter

/// Adapter for UniFi Protect camera integration
@interface RTSPUniFiProtectAdapter : NSObject

#pragma mark - Singleton

/// Shared instance
+ (instancetype)sharedAdapter;

#pragma mark - Configuration

/// UniFi Protect controller host (IP or hostname)
@property (nonatomic, strong, nullable) NSString *controllerHost;

/// UniFi Protect controller port (default: 443)
@property (nonatomic, assign) NSInteger controllerPort;

/// Username for UniFi Protect
@property (nonatomic, strong, nullable) NSString *username;

/// Password for UniFi Protect
@property (nonatomic, strong, nullable) NSString *password;

/// Use HTTPS (default: YES)
@property (nonatomic, assign) BOOL useHTTPS;

/// Verify SSL certificate (default: NO for self-signed certs)
@property (nonatomic, assign) BOOL verifySSL;

/// Delegate for adapter events
@property (nonatomic, weak, nullable) id<RTSPUniFiProtectAdapterDelegate> delegate;

#pragma mark - Authentication

/// Check if currently authenticated
@property (nonatomic, readonly) BOOL isAuthenticated;

/// Authentication token (if authenticated)
@property (nonatomic, strong, nullable, readonly) NSString *authToken;

/// Authenticate with UniFi Protect
/// @param completion Completion handler with success status
- (void)authenticateWithCompletion:(void (^)(BOOL success, NSError * _Nullable error))completion;

/// Authenticate with UniFi Protect using MFA token
/// @param mfaToken 6-digit MFA token (or nil for first attempt)
/// @param completion Completion handler with success status
- (void)authenticateWithMFAToken:(nullable NSString *)mfaToken
                      completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

/// Logout from UniFi Protect
- (void)logout;

#pragma mark - Camera Discovery

/// Discover all cameras on UniFi Protect
/// @param completion Completion handler with camera array
- (void)discoverCamerasWithCompletion:(void (^)(NSArray<RTSPUniFiCamera *> * _Nullable cameras, NSError * _Nullable error))completion;

/// Get specific camera by ID
/// @param cameraId Camera ID
/// @param completion Completion handler with camera object
- (void)getCameraById:(NSString *)cameraId
           completion:(void (^)(RTSPUniFiCamera * _Nullable camera, NSError * _Nullable error))completion;

/// Refresh camera list (re-authenticate and discover)
/// @param completion Completion handler
- (void)refreshCameraList:(void (^)(BOOL success, NSError * _Nullable error))completion;

#pragma mark - RTSP URL Generation

/// Generate RTSP URL for camera
/// @param camera UniFi camera object
/// @param streamType Stream type: "high" (main) or "low" (sub)
/// @return RTSP URL string
- (NSString *)generateRTSPURLForCamera:(RTSPUniFiCamera *)camera
                            streamType:(NSString *)streamType;

/// Generate RTSP URL with custom parameters
/// @param camera UniFi camera object
/// @param streamType Stream type: "high" or "low"
/// @param username RTSP username (usually same as UniFi username)
/// @param password RTSP password (usually same as UniFi password)
/// @return RTSP URL string
- (NSString *)generateRTSPURLForCamera:(RTSPUniFiCamera *)camera
                            streamType:(NSString *)streamType
                              username:(NSString *)username
                              password:(NSString *)password;

#pragma mark - Camera Import

/// Import cameras to feed list
/// @param cameras Array of UniFi cameras to import
/// @param completion Completion handler with number of cameras imported
- (void)importCameras:(NSArray<RTSPUniFiCamera *> *)cameras
           completion:(void (^)(NSInteger importedCount))completion;

#pragma mark - Health Monitoring

/// Test connection to specific camera
/// @param camera Camera to test
/// @param completion Completion handler with success status
- (void)testCameraConnection:(RTSPUniFiCamera *)camera
                  completion:(void (^)(BOOL success, NSTimeInterval latency, NSError * _Nullable error))completion;

/// Get camera snapshot URL
/// @param camera Camera object
/// @return Snapshot URL (HTTPS)
- (nullable NSString *)getSnapshotURLForCamera:(RTSPUniFiCamera *)camera;

#pragma mark - Configuration Persistence

/// Save UniFi Protect configuration
- (void)saveConfiguration;

/// Load UniFi Protect configuration
- (void)loadConfiguration;

/// Clear stored credentials
- (void)clearCredentials;

@end

NS_ASSUME_NONNULL_END
