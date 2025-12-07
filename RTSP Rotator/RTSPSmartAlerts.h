//
//  RTSPSmartAlerts.h
//  RTSP Rotator
//
//  AI-powered object detection alerts using MLX and Vision framework
//

#import <Foundation/Foundation.h>
#import <Vision/Vision.h>
#import <AVFoundation/AVFoundation.h>
#import "RTSPObjectDetector.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTSPDetectedObjectType) {
    RTSPDetectedObjectTypePerson,
    RTSPDetectedObjectTypeVehicle,
    RTSPDetectedObjectTypeAnimal,
    RTSPDetectedObjectTypePackage,
    RTSPDetectedObjectTypeOther
};

typedef NS_ENUM(NSInteger, RTSPAlertMode) {
    RTSPAlertModeDisabled,      // No alerts
    RTSPAlertModeAny,           // Alert on any detection
    RTSPAlertModeSpecific,      // Alert on specific object types
    RTSPAlertModeZone           // Alert only in zones
};

@class RTSPSmartAlerts;

@protocol RTSPSmartAlertsDelegate <NSObject>
@optional
- (void)smartAlerts:(RTSPSmartAlerts *)alerts didDetectObject:(RTSPDetectedObjectType)objectType confidence:(CGFloat)confidence;
- (void)smartAlerts:(RTSPSmartAlerts *)alerts didDetectEvent:(RTSPDetectionEvent *)event;
- (void)smartAlerts:(RTSPSmartAlerts *)alerts didTriggerAlert:(NSString *)message forEvent:(RTSPDetectionEvent *)event;
@end

@interface RTSPSmartAlerts : NSObject

- (instancetype)initWithPlayer:(AVPlayer *)player;
- (instancetype)initWithCameraID:(NSString *)cameraID cameraName:(NSString *)cameraName;

@property (nonatomic, weak) id<RTSPSmartAlertsDelegate> delegate;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) CGFloat confidenceThreshold; // 0.0-1.0, default: 0.5
@property (nonatomic, assign) NSTimeInterval checkInterval; // default: 1.0

// MLX Integration
@property (nonatomic, assign) BOOL useMLX; // Use MLX for detection (default: YES)
@property (nonatomic, strong, readonly) RTSPObjectDetector *objectDetector;

// Alert configuration
@property (nonatomic, assign) RTSPAlertMode alertMode;
@property (nonatomic, strong) NSArray<NSString *> *alertClasses; // Classes to alert on (nil = all)
@property (nonatomic, assign) NSTimeInterval cooldownPeriod; // Seconds between alerts (default: 30)

// Notification settings
@property (nonatomic, assign) BOOL sendSystemNotifications;
@property (nonatomic, assign) BOOL shouldPlayAlertSound;
@property (nonatomic, copy, nullable) NSString *alertSoundName;

// Statistics
@property (nonatomic, readonly) NSInteger alertCount;
@property (nonatomic, readonly) NSDate *lastAlertTime;

- (void)startMonitoring;
- (void)stopMonitoring;

// Process frame from external source (e.g., video player)
- (void)processFrame:(CVPixelBufferRef)pixelBuffer;

// Reset alert statistics
- (void)resetStatistics;

// Get alert history
- (NSArray<RTSPDetectionEvent *> *)alertHistory:(NSInteger)limit;

@end

NS_ASSUME_NONNULL_END
