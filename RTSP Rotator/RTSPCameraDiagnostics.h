//
//  RTSPCameraDiagnostics.h
//  RTSP Rotator
//
//  Comprehensive camera health monitoring and diagnostics
//

#import <Foundation/Foundation.h>
#import "RTSPCameraTypeManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTSPCameraHealthStatus) {
    RTSPCameraHealthStatusUnknown,      // Gray - not yet tested
    RTSPCameraHealthStatusHealthy,      // Green - all good
    RTSPCameraHealthStatusWarning,      // Yellow - issues detected
    RTSPCameraHealthStatusCritical,     // Red - not working
    RTSPCameraHealthStatusTesting       // Blue - test in progress
};

/// Detailed diagnostic report for a camera
@interface RTSPCameraDiagnosticReport : NSObject

@property (nonatomic, strong) NSString *cameraID;
@property (nonatomic, strong) NSString *cameraName;
@property (nonatomic, assign) RTSPCameraHealthStatus healthStatus;
@property (nonatomic, strong) NSDate *lastTestDate;
@property (nonatomic, assign) NSTimeInterval testDuration;

// Connection diagnostics
@property (nonatomic, assign) BOOL canConnect;
@property (nonatomic, assign) NSTimeInterval connectionTime;
@property (nonatomic, assign) NSInteger connectionRetries;
@property (nonatomic, strong, nullable) NSString *connectionError;

// Stream diagnostics
@property (nonatomic, assign) BOOL hasVideo;
@property (nonatomic, assign) BOOL hasAudio;
@property (nonatomic, strong, nullable) NSString *videoCodec;
@property (nonatomic, strong, nullable) NSString *audioCodec;
@property (nonatomic, strong, nullable) NSString *resolution;
@property (nonatomic, assign) NSInteger framerate;
@property (nonatomic, assign) CGFloat bitrate; // Mbps

// Network diagnostics
@property (nonatomic, assign) CGFloat latency; // milliseconds
@property (nonatomic, assign) CGFloat packetLoss; // percentage
@property (nonatomic, assign) CGFloat bandwidth; // Mbps
@property (nonatomic, assign) NSInteger jitter; // milliseconds

// Performance metrics
@property (nonatomic, assign) CGFloat cpuUsage; // percentage
@property (nonatomic, assign) CGFloat memoryUsage; // MB
@property (nonatomic, assign) NSInteger droppedFrames;
@property (nonatomic, assign) CGFloat bufferHealth; // percentage

// Issues detected
@property (nonatomic, strong) NSArray<NSString *> *warnings;
@property (nonatomic, strong) NSArray<NSString *> *errors;

/// Generate human-readable summary
- (NSString *)summaryDescription;

/// Get color for health status indicator
- (NSColor *)statusColor;

/// Export diagnostics as JSON
- (NSDictionary *)toDictionary;

@end

@class RTSPCameraDiagnostics;

/// Diagnostics delegate
@protocol RTSPCameraDiagnosticsDelegate <NSObject>
@optional
- (void)cameraDiagnostics:(RTSPCameraDiagnostics *)diagnostics didCompleteTest:(RTSPCameraDiagnosticReport *)report;
- (void)cameraDiagnostics:(RTSPCameraDiagnostics *)diagnostics healthStatusChanged:(RTSPCameraConfig *)camera status:(RTSPCameraHealthStatus)status;
@end

/// Camera diagnostics and health monitoring system
@interface RTSPCameraDiagnostics : NSObject

/// Shared instance
+ (instancetype)sharedDiagnostics;

/// Delegate
@property (nonatomic, weak) id<RTSPCameraDiagnosticsDelegate> delegate;

/// Enable automatic health checks
@property (nonatomic, assign) BOOL automaticHealthChecks;

/// Health check interval (default: 60 seconds)
@property (nonatomic, assign) NSTimeInterval healthCheckInterval;

/// Get diagnostic report for camera
- (nullable RTSPCameraDiagnosticReport *)reportForCamera:(RTSPCameraConfig *)camera;

/// Get all diagnostic reports
- (NSArray<RTSPCameraDiagnosticReport *> *)allReports;

/// Run comprehensive diagnostic test on camera
- (void)testCamera:(RTSPCameraConfig *)camera completion:(void (^)(RTSPCameraDiagnosticReport *report))completion;

/// Run quick connection test
- (void)quickTestCamera:(RTSPCameraConfig *)camera completion:(void (^)(BOOL healthy, NSString *_Nullable issue))completion;

/// Test all cameras
- (void)testAllCamerasWithProgress:(void (^)(NSInteger tested, NSInteger total))progressHandler
                        completion:(void (^)(NSArray<RTSPCameraDiagnosticReport *> *reports))completion;

/// Get health status for camera
- (RTSPCameraHealthStatus)healthStatusForCamera:(RTSPCameraConfig *)camera;

/// Get cameras by health status
- (NSArray<RTSPCameraConfig *> *)camerasWithHealthStatus:(RTSPCameraHealthStatus)status;

/// Get unhealthy cameras
- (NSArray<RTSPCameraConfig *> *)unhealthyCameras;

/// Clear diagnostic report for camera
- (void)clearReportForCamera:(RTSPCameraConfig *)camera;

/// Clear all reports
- (void)clearAllReports;

/// Start automatic health monitoring
- (void)startHealthMonitoring;

/// Stop automatic health monitoring
- (void)stopHealthMonitoring;

/// Export all diagnostics to file
- (BOOL)exportDiagnosticsToFile:(NSString *)filePath;

/// Get system-wide health summary
- (NSDictionary *)systemHealthSummary;

@end

NS_ASSUME_NONNULL_END
