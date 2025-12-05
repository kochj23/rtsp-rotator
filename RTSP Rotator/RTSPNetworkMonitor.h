//
//  RTSPNetworkMonitor.h
//  RTSP Rotator
//
//  Network statistics and diagnostics
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Network statistics for a feed
@interface RTSPNetworkStats : NSObject
@property (nonatomic, strong) NSURL *feedURL;
@property (nonatomic, assign) CGFloat bandwidthMbps;
@property (nonatomic, assign) CGFloat latencyMs;
@property (nonatomic, assign) CGFloat packetLossPercent;
@property (nonatomic, assign) NSInteger droppedFrames;
@property (nonatomic, assign) NSInteger totalFrames;
@property (nonatomic, strong) NSDate *lastUpdate;
@property (nonatomic, assign) NSInteger connectionQuality; // 0-100
@end

@class RTSPNetworkMonitor;

/// Network monitor delegate
@protocol RTSPNetworkMonitorDelegate <NSObject>
@optional
- (void)networkMonitor:(RTSPNetworkMonitor *)monitor didUpdateStats:(RTSPNetworkStats *)stats;
- (void)networkMonitor:(RTSPNetworkMonitor *)monitor didDetectPoorQuality:(RTSPNetworkStats *)stats;
@end

/// Real-time network monitoring and diagnostics
@interface RTSPNetworkMonitor : NSObject

/// Initialize with AVPlayer
- (instancetype)initWithPlayer:(AVPlayer *)player feedURL:(NSURL *)feedURL;

/// Delegate for network events
@property (nonatomic, weak) id<RTSPNetworkMonitorDelegate> delegate;

/// Enable monitoring
@property (nonatomic, assign) BOOL enabled;

/// Update interval in seconds (default: 1.0)
@property (nonatomic, assign) NSTimeInterval updateInterval;

/// Poor quality threshold (default: 30)
@property (nonatomic, assign) NSInteger poorQualityThreshold;

/// Current statistics
@property (nonatomic, strong, readonly) RTSPNetworkStats *currentStats;

/// Start monitoring
- (void)startMonitoring;

/// Stop monitoring
- (void)stopMonitoring;

/// Generate diagnostics report
- (NSString *)generateDiagnosticsReport;

/// Export report to file
- (BOOL)exportReportToFile:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
