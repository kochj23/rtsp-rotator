//
//  RTSPPTZController.h
//  RTSP Rotator
//
//  Pan/Tilt/Zoom camera control via ONVIF
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTSPPTZDirection) {
    RTSPPTZDirectionUp,
    RTSPPTZDirectionDown,
    RTSPPTZDirectionLeft,
    RTSPPTZDirectionRight,
    RTSPPTZDirectionZoomIn,
    RTSPPTZDirectionZoomOut
};

/// PTZ preset position
@interface RTSPPTZPreset : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger presetID;
@property (nonatomic, assign) CGFloat pan;
@property (nonatomic, assign) CGFloat tilt;
@property (nonatomic, assign) CGFloat zoom;
@end

/// PTZ camera controller
@interface RTSPPTZController : NSObject

/// Initialize with camera URL and credentials
- (instancetype)initWithURL:(NSURL *)cameraURL username:(nullable NSString *)username password:(nullable NSString *)password;

/// Camera supports PTZ
@property (nonatomic, assign, readonly) BOOL supportsPTZ;

/// Move camera in direction
- (void)move:(RTSPPTZDirection)direction speed:(CGFloat)speed completion:(nullable void (^)(BOOL success, NSError *_Nullable error))completion;

/// Stop current movement
- (void)stop:(nullable void (^)(BOOL success))completion;

/// Go to absolute position
- (void)goToPosition:(CGFloat)pan tilt:(CGFloat)tilt zoom:(CGFloat)zoom completion:(nullable void (^)(BOOL success, NSError *_Nullable error))completion;

/// Save current position as preset
- (void)savePreset:(NSString *)name completion:(nullable void (^)(RTSPPTZPreset *_Nullable preset, NSError *_Nullable error))completion;

/// Go to preset
- (void)goToPreset:(RTSPPTZPreset *)preset completion:(nullable void (^)(BOOL success, NSError *_Nullable error))completion;

/// List all presets
- (void)listPresetsWithCompletion:(void (^)(NSArray<RTSPPTZPreset *> *_Nullable presets, NSError *_Nullable error))completion;

/// Delete preset
- (void)deletePreset:(RTSPPTZPreset *)preset completion:(nullable void (^)(BOOL success, NSError *_Nullable error))completion;

/// Start auto-tour through presets
- (void)startAutoTourWithInterval:(NSTimeInterval)interval completion:(nullable void (^)(BOOL success))completion;

/// Stop auto-tour
- (void)stopAutoTour;

@end

NS_ASSUME_NONNULL_END
