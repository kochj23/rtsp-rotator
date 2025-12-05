//
//  RTSPCameraTypeManager.h
//  RTSP Rotator
//
//  Separate management for different camera types with detailed configuration
//

#import <Foundation/Foundation.h>
#import "RTSPDashboardManager.h"
#import "RTSPUniFiProtectAdapter.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTSPCameraConnectionStatus) {
    RTSPCameraConnectionStatusUnknown,
    RTSPCameraConnectionStatusConnecting,
    RTSPCameraConnectionStatusConnected,
    RTSPCameraConnectionStatusDisconnected,
    RTSPCameraConnectionStatusFailed,
    RTSPCameraConnectionStatusAuthenticationFailed,
    RTSPCameraConnectionStatusTimeout
};

/// Detailed RTSP camera configuration
@interface RTSPStandardCameraConfig : RTSPCameraConfig

// Connection settings
@property (nonatomic, assign) NSInteger port; // Default: 554
@property (nonatomic, strong, nullable) NSString *streamPath; // e.g., "/stream1"
@property (nonatomic, assign) BOOL usesTLS; // RTSPS instead of RTSP
@property (nonatomic, assign) NSTimeInterval connectionTimeout; // Default: 10s
@property (nonatomic, assign) NSInteger maxRetries; // Default: 3

// Video settings
@property (nonatomic, strong, nullable) NSString *preferredResolution; // "1080p", "720p", etc.
@property (nonatomic, assign) NSInteger preferredFramerate; // Default: 30
@property (nonatomic, strong, nullable) NSString *codecPreference; // "H264", "H265", etc.

// Audio settings
@property (nonatomic, assign) BOOL hasAudio;
@property (nonatomic, assign) BOOL enableAudio;
@property (nonatomic, assign) float audioVolume; // 0.0 - 1.0

// Network settings
@property (nonatomic, assign) BOOL useUDP; // vs TCP
@property (nonatomic, assign) NSInteger bufferSize; // milliseconds

// PTZ support
@property (nonatomic, assign) BOOL supportsPTZ;
@property (nonatomic, strong, nullable) NSString *ptzProtocol; // "ONVIF", "Pelco-D", etc.

/// Build full RTSP URL from components
- (NSURL *)buildRTSPURL;

/// Test connection without creating player
- (void)testConnectionWithCompletion:(void (^)(BOOL success, NSError *_Nullable error))completion;

@end

@class RTSPCameraTypeManager;

/// Camera type manager delegate
@protocol RTSPCameraTypeManagerDelegate <NSObject>
@optional
- (void)cameraTypeManager:(RTSPCameraTypeManager *)manager didUpdateCamera:(RTSPCameraConfig *)camera;
- (void)cameraTypeManager:(RTSPCameraTypeManager *)manager cameraConnectionChanged:(RTSPCameraConfig *)camera status:(RTSPCameraConnectionStatus)status;
@end

/// Manager for different camera types
@interface RTSPCameraTypeManager : NSObject

/// Shared instance
+ (instancetype)sharedManager;

/// Delegate
@property (nonatomic, weak) id<RTSPCameraTypeManagerDelegate> delegate;

/// All RTSP cameras
- (NSArray<RTSPStandardCameraConfig *> *)rtspCameras;

/// Add RTSP camera
- (void)addRTSPCamera:(RTSPStandardCameraConfig *)camera;

/// Remove camera by ID
- (void)removeCameraWithID:(NSString *)cameraID;

/// Get camera by ID
- (nullable RTSPCameraConfig *)cameraWithID:(NSString *)cameraID;

/// Test camera connection
- (void)testCameraConnection:(RTSPCameraConfig *)camera completion:(void (^)(BOOL success, NSDictionary *_Nullable diagnostics, NSError *_Nullable error))completion;

/// Get all cameras by type
- (NSArray<RTSPCameraConfig *> *)camerasOfType:(NSString *)type;

/// Import cameras from configuration file
- (BOOL)importCamerasFromFile:(NSString *)filePath error:(NSError **)error;

/// Export cameras to configuration file
- (BOOL)exportCamerasToFile:(NSString *)filePath error:(NSError **)error;

/// Discover RTSP cameras on network (ONVIF discovery)
- (void)discoverRTSPCamerasWithCompletion:(void (^)(NSArray<RTSPStandardCameraConfig *> *cameras))completion;

/// Save cameras
- (BOOL)saveCameras;

/// Load cameras
- (BOOL)loadCameras;

@end

NS_ASSUME_NONNULL_END
