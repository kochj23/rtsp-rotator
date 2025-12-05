//
//  RTSPAudioMonitor.h
//  RTSP Rotator
//
//  Real-time audio level monitoring and alerts
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTSPAudioAlertType) {
    RTSPAudioAlertTypeLoudNoise,
    RTSPAudioAlertTypeSilence,
    RTSPAudioAlertTypeFrequencyDetected
};

@class RTSPAudioMonitor;

/// Audio monitoring delegate
@protocol RTSPAudioMonitorDelegate <NSObject>
@optional
- (void)audioMonitor:(RTSPAudioMonitor *)monitor didDetectAudioLevel:(CGFloat)level;
- (void)audioMonitor:(RTSPAudioMonitor *)monitor didTriggerAlert:(RTSPAudioAlertType)alertType level:(CGFloat)level;
- (void)audioMonitor:(RTSPAudioMonitor *)monitor didUpdatePeakLevel:(CGFloat)peak averageLevel:(CGFloat)average;
@end

/// Real-time audio level monitoring
@interface RTSPAudioMonitor : NSObject

/// Initialize with AVPlayer
- (instancetype)initWithPlayer:(AVPlayer *)player;

/// Delegate for audio callbacks
@property (nonatomic, weak) id<RTSPAudioMonitorDelegate> delegate;

/// Enable audio monitoring
@property (nonatomic, assign) BOOL enabled;

/// Update interval in seconds (default: 0.1)
@property (nonatomic, assign) NSTimeInterval updateInterval;

/// Loud noise threshold (0.0-1.0, default: 0.8)
@property (nonatomic, assign) CGFloat loudNoiseThreshold;

/// Silence threshold (0.0-1.0, default: 0.1)
@property (nonatomic, assign) CGFloat silenceThreshold;

/// Silence detection duration in seconds (default: 2.0)
@property (nonatomic, assign) NSTimeInterval silenceDuration;

/// Current audio level (0.0-1.0)
@property (nonatomic, assign, readonly) CGFloat currentLevel;

/// Peak level (0.0-1.0)
@property (nonatomic, assign, readonly) CGFloat peakLevel;

/// Average level (0.0-1.0)
@property (nonatomic, assign, readonly) CGFloat averageLevel;

/// Whether currently detecting silence
@property (nonatomic, assign, readonly) BOOL isSilent;

/// Start monitoring
- (void)startMonitoring;

/// Stop monitoring
- (void)stopMonitoring;

/// Reset peak level
- (void)resetPeakLevel;

@end

NS_ASSUME_NONNULL_END
