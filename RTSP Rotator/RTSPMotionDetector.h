//
//  RTSPMotionDetector.h
//  RTSP Rotator
//
//  Motion detection using Vision framework
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Vision/Vision.h>

NS_ASSUME_NONNULL_BEGIN

@class RTSPMotionDetector;

/// Motion detection delegate
@protocol RTSPMotionDetectorDelegate <NSObject>
@optional
- (void)motionDetector:(RTSPMotionDetector *)detector didDetectMotionWithConfidence:(CGFloat)confidence;
- (void)motionDetectorDidStopMotion:(RTSPMotionDetector *)detector;
@end

/// Motion detection for RTSP streams
@interface RTSPMotionDetector : NSObject

/// Initialize with AVPlayer
- (instancetype)initWithPlayer:(AVPlayer *)player;

/// Delegate for motion callbacks
@property (nonatomic, weak) id<RTSPMotionDetectorDelegate> delegate;

/// Enable motion detection
@property (nonatomic, assign) BOOL enabled;

/// Sensitivity (0.0 - 1.0, default 0.5)
@property (nonatomic, assign) CGFloat sensitivity;

/// Check interval in seconds (default 0.5)
@property (nonatomic, assign) NSTimeInterval checkInterval;

/// Whether motion is currently detected
@property (nonatomic, assign, readonly) BOOL motionDetected;

/// Start monitoring
- (void)startMonitoring;

/// Stop monitoring
- (void)stopMonitoring;

@end

NS_ASSUME_NONNULL_END
