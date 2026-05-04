//
//  RTSPWidgetBridge.h
//  RTSP Rotator
//
//  Bridge for updating widget data from the main Objective-C app
//  Created by Jordan Koch
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Widget camera health status - mirrors CameraHealthStatus in Swift
typedef NS_ENUM(NSInteger, RTSPWidgetHealthStatus) {
    RTSPWidgetHealthStatusUnknown = 0,
    RTSPWidgetHealthStatusHealthy = 1,
    RTSPWidgetHealthStatusDegraded = 2,
    RTSPWidgetHealthStatusUnhealthy = 3
};

/// Widget camera data structure
@interface RTSPWidgetCameraInfo : NSObject

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, assign) RTSPWidgetHealthStatus healthStatus;
@property (nonatomic, assign) NSInteger detectionCount;
@property (nonatomic, strong, nullable) NSDate *lastDetectionTime;
@property (nonatomic, copy, nullable) NSString *lastDetectionType;
@property (nonatomic, assign) BOOL isEnabled;
@property (nonatomic, assign) double uptimePercentage;
@property (nonatomic, assign) NSInteger consecutiveFailures;
@property (nonatomic, strong, nullable) NSDate *lastSuccessfulConnection;

@end

/// Bridge class for updating widget data from Objective-C
@interface RTSPWidgetBridge : NSObject

/// Shared instance
+ (instancetype)sharedBridge;

/// App Group identifier for data sharing
@property (nonatomic, readonly) NSString *appGroupIdentifier;

/// Update all camera data
- (void)updateCameras:(NSArray<RTSPWidgetCameraInfo *> *)cameras;

/// Update current camera index
- (void)updateCurrentCameraIndex:(NSInteger)index;

/// Update total detection count
- (void)updateTotalDetections:(NSInteger)count;

/// Update app running state
- (void)updateAppRunningState:(BOOL)isRunning;

/// Perform full widget update
- (void)updateWidgetWithCameras:(NSArray<RTSPWidgetCameraInfo *> *)cameras
             currentCameraIndex:(NSInteger)currentIndex
                totalDetections:(NSInteger)totalDetections
                   isAppRunning:(BOOL)isRunning;

/// Update single camera health
- (void)updateCameraHealth:(NSString *)cameraID status:(RTSPWidgetHealthStatus)status;

/// Update detection for camera
- (void)updateCameraDetection:(NSString *)cameraID detectionType:(NSString *)type;

/// Clear all widget data
- (void)clearWidgetData;

/// Request widget timeline refresh
- (void)refreshWidgetTimeline;

@end

NS_ASSUME_NONNULL_END
