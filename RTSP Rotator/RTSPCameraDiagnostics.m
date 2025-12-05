//
//  RTSPCameraDiagnostics.m
//  RTSP Rotator
//

#import "RTSPCameraDiagnostics.h"
#import <AVFoundation/AVFoundation.h>

@implementation RTSPCameraDiagnosticReport

- (instancetype)init {
    self = [super init];
    if (self) {
        _healthStatus = RTSPCameraHealthStatusUnknown;
        _warnings = @[];
        _errors = @[];
    }
    return self;
}

- (NSString *)summaryDescription {
    NSMutableString *summary = [NSMutableString string];

    [summary appendFormat:@"Camera: %@\n", self.cameraName];
    [summary appendFormat:@"Status: %@\n", [self statusString]];
    [summary appendFormat:@"Last Test: %@\n", self.lastTestDate];

    if (self.canConnect) {
        [summary appendFormat:@"Connection: OK (%.1fms)\n", self.connectionTime * 1000];

        if (self.hasVideo) {
            [summary appendFormat:@"Video: %@ @ %@ (%ldfps, %.1f Mbps)\n",
             self.videoCodec, self.resolution, (long)self.framerate, self.bitrate];
        }

        if (self.hasAudio) {
            [summary appendFormat:@"Audio: %@\n", self.audioCodec];
        }

        if (self.latency > 0) {
            [summary appendFormat:@"Latency: %.1fms\n", self.latency];
        }

        if (self.droppedFrames > 0) {
            [summary appendFormat:@"Dropped Frames: %ld\n", (long)self.droppedFrames];
        }
    } else {
        [summary appendFormat:@"Connection: FAILED - %@\n", self.connectionError ?: @"Unknown error"];
    }

    if (self.warnings.count > 0) {
        [summary appendString:@"\nWarnings:\n"];
        for (NSString *warning in self.warnings) {
            [summary appendFormat:@"  • %@\n", warning];
        }
    }

    if (self.errors.count > 0) {
        [summary appendString:@"\nErrors:\n"];
        for (NSString *error in self.errors) {
            [summary appendFormat:@"  • %@\n", error];
        }
    }

    return summary;
}

- (NSString *)statusString {
    switch (self.healthStatus) {
        case RTSPCameraHealthStatusHealthy: return @"Healthy";
        case RTSPCameraHealthStatusWarning: return @"Warning";
        case RTSPCameraHealthStatusCritical: return @"Critical";
        case RTSPCameraHealthStatusTesting: return @"Testing...";
        default: return @"Unknown";
    }
}

- (NSColor *)statusColor {
    switch (self.healthStatus) {
        case RTSPCameraHealthStatusHealthy:
            return [NSColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:1.0]; // Green
        case RTSPCameraHealthStatusWarning:
            return [NSColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0]; // Yellow
        case RTSPCameraHealthStatusCritical:
            return [NSColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0]; // Red
        case RTSPCameraHealthStatusTesting:
            return [NSColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0]; // Blue
        default:
            return [NSColor grayColor]; // Gray
    }
}

- (NSDictionary *)toDictionary {
    return @{
        @"cameraID": self.cameraID ?: @"",
        @"cameraName": self.cameraName ?: @"",
        @"healthStatus": @(self.healthStatus),
        @"lastTestDate": self.lastTestDate ?: [NSNull null],
        @"testDuration": @(self.testDuration),
        @"canConnect": @(self.canConnect),
        @"connectionTime": @(self.connectionTime),
        @"hasVideo": @(self.hasVideo),
        @"hasAudio": @(self.hasAudio),
        @"videoCodec": self.videoCodec ?: [NSNull null],
        @"resolution": self.resolution ?: [NSNull null],
        @"framerate": @(self.framerate),
        @"bitrate": @(self.bitrate),
        @"latency": @(self.latency),
        @"packetLoss": @(self.packetLoss),
        @"droppedFrames": @(self.droppedFrames),
        @"warnings": self.warnings,
        @"errors": self.errors
    };
}

@end

@interface RTSPCameraDiagnostics ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, RTSPCameraDiagnosticReport *> *reports;
@property (nonatomic, strong) NSTimer *monitoringTimer;
@end

@implementation RTSPCameraDiagnostics

+ (instancetype)sharedDiagnostics {
    static RTSPCameraDiagnostics *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RTSPCameraDiagnostics alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _reports = [NSMutableDictionary dictionary];
        _automaticHealthChecks = NO;
        _healthCheckInterval = 60.0;
    }
    return self;
}

- (RTSPCameraDiagnosticReport *)reportForCamera:(RTSPCameraConfig *)camera {
    return self.reports[camera.cameraID];
}

- (NSArray<RTSPCameraDiagnosticReport *> *)allReports {
    return [self.reports.allValues copy];
}

- (void)testCamera:(RTSPCameraConfig *)camera completion:(void (^)(RTSPCameraDiagnosticReport *))completion {
    RTSPCameraDiagnosticReport *report = [[RTSPCameraDiagnosticReport alloc] init];
    report.cameraID = camera.cameraID;
    report.cameraName = camera.name;
    report.healthStatus = RTSPCameraHealthStatusTesting;
    report.lastTestDate = [NSDate date];

    self.reports[camera.cameraID] = report;

    NSDate *testStart = [NSDate date];

    NSLog(@"[Diagnostics] Testing camera: %@", camera.name);

    // Test connection
    [[RTSPCameraTypeManager sharedManager] testCameraConnection:camera completion:^(BOOL success, NSDictionary *diagnostics, NSError *error) {
        report.testDuration = [[NSDate date] timeIntervalSinceDate:testStart];
        report.canConnect = success;

        if (success) {
            report.connectionTime = [diagnostics[@"connectionTime"] doubleValue];

            // Run detailed stream analysis
            [self analyzeStream:camera report:report completion:^{
                [self finalizeReport:report];

                if ([self.delegate respondsToSelector:@selector(cameraDiagnostics:didCompleteTest:)]) {
                    [self.delegate cameraDiagnostics:self didCompleteTest:report];
                }

                if (completion) completion(report);
            }];
        } else {
            report.connectionError = error.localizedDescription;
            report.healthStatus = RTSPCameraHealthStatusCritical;

            NSMutableArray *errors = [report.errors mutableCopy];
            [errors addObject:[NSString stringWithFormat:@"Connection failed: %@", error.localizedDescription]];
            report.errors = errors;

            [self finalizeReport:report];

            if (completion) completion(report);
        }
    }];
}

- (void)analyzeStream:(RTSPCameraConfig *)camera report:(RTSPCameraDiagnosticReport *)report completion:(void (^)(void))completion {
    // Create temporary player for stream analysis
    AVPlayer *player = [[AVPlayer alloc] init];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:camera.feedURL];

    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:(__bridge void *)report];
    [player replaceCurrentItemWithPlayerItem:item];

    // Wait for player to be ready
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (item.status == AVPlayerItemStatusReadyToPlay) {
            // Extract stream information
            AVAsset *asset = item.asset;

            // Video tracks - use new async API
            if (@available(macOS 12.0, *)) {
                [asset loadTracksWithMediaType:AVMediaTypeVideo completionHandler:^(NSArray<AVAssetTrack *> * _Nullable videoTracks, NSError * _Nullable error) {
                    if (!error && videoTracks.count > 0) {
                        AVAssetTrack *videoTrack = videoTracks[0];
                        report.hasVideo = YES;

                        // Get resolution
                        CGSize size = videoTrack.naturalSize;
                        report.resolution = [NSString stringWithFormat:@"%.0fx%.0f", size.width, size.height];

                        // Get framerate
                        report.framerate = (NSInteger)videoTrack.nominalFrameRate;

                        // Estimate bitrate
                        report.bitrate = videoTrack.estimatedDataRate / 1000000.0; // Convert to Mbps

                        NSLog(@"[Diagnostics] Video: %@ @ %ldfps, %.1f Mbps", report.resolution, (long)report.framerate, report.bitrate);
                    }

                    // Audio tracks - use new async API
                    [asset loadTracksWithMediaType:AVMediaTypeAudio completionHandler:^(NSArray<AVAssetTrack *> * _Nullable audioTracks, NSError * _Nullable audioError) {
                        if (!audioError) {
                            report.hasAudio = audioTracks.count > 0;
                        }

                    // Check for issues
                    NSMutableArray *warnings = [NSMutableArray array];

                    if (report.framerate < 15) {
                        [warnings addObject:[NSString stringWithFormat:@"Low framerate: %ldfps", (long)report.framerate]];
                    }

                    if (report.bitrate < 1.0) {
                        [warnings addObject:[NSString stringWithFormat:@"Low bitrate: %.1f Mbps", report.bitrate]];
                    }

                    if (!report.hasVideo) {
                        [warnings addObject:@"No video stream detected"];
                    }

                    report.warnings = warnings;

                    dispatch_async(dispatch_get_main_queue(), ^{
                        [item removeObserver:self forKeyPath:@"status" context:(__bridge void *)report];
                        [player pause];

                        if (completion) completion();
                    });
                }];
            }];
            } else {
                // Fallback for macOS 11.0-11.x: use synchronous API
                NSArray<AVAssetTrack *> *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
                if (videoTracks.count > 0) {
                    AVAssetTrack *videoTrack = videoTracks[0];
                    report.hasVideo = YES;

                    // Get resolution
                    CGSize size = videoTrack.naturalSize;
                    report.resolution = [NSString stringWithFormat:@"%.0fx%.0f", size.width, size.height];

                    // Get framerate
                    report.framerate = (NSInteger)videoTrack.nominalFrameRate;

                    // Estimate bitrate
                    report.bitrate = videoTrack.estimatedDataRate / 1000000.0;

                    NSLog(@"[Diagnostics] Video: %@ @ %ldfps, %.1f Mbps", report.resolution, (long)report.framerate, report.bitrate);
                }

                // Audio tracks
                NSArray<AVAssetTrack *> *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
                report.hasAudio = audioTracks.count > 0;

                // Check for issues
                NSMutableArray *warnings = [NSMutableArray array];

                if (report.framerate < 15) {
                    [warnings addObject:[NSString stringWithFormat:@"Low framerate: %ldfps", (long)report.framerate]];
                }

                if (report.bitrate < 1.0) {
                    [warnings addObject:[NSString stringWithFormat:@"Low bitrate: %.1f Mbps", report.bitrate]];
                }

                if (!report.hasVideo) {
                    [warnings addObject:@"No video stream detected"];
                }

                report.warnings = warnings;

                dispatch_async(dispatch_get_main_queue(), ^{
                    [item removeObserver:self forKeyPath:@"status" context:(__bridge void *)report];
                    [player pause];

                    if (completion) completion();
                });
            }
        } else {
            [item removeObserver:self forKeyPath:@"status" context:(__bridge void *)report];
            [player pause];

            if (completion) completion();
        }
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // Observer for stream analysis
}

- (void)finalizeReport:(RTSPCameraDiagnosticReport *)report {
    // Determine overall health status
    if (!report.canConnect) {
        report.healthStatus = RTSPCameraHealthStatusCritical;
    } else if (report.errors.count > 0) {
        report.healthStatus = RTSPCameraHealthStatusCritical;
    } else if (report.warnings.count > 0) {
        report.healthStatus = RTSPCameraHealthStatusWarning;
    } else {
        report.healthStatus = RTSPCameraHealthStatusHealthy;
    }

    NSLog(@"[Diagnostics] Test complete: %@ - %@", report.cameraName, [report statusString]);

    if ([self.delegate respondsToSelector:@selector(cameraDiagnostics:healthStatusChanged:status:)]) {
        RTSPCameraConfig *camera = [[RTSPCameraTypeManager sharedManager] cameraWithID:report.cameraID];
        if (camera) {
            [self.delegate cameraDiagnostics:self healthStatusChanged:camera status:report.healthStatus];
        }
    }
}

- (void)quickTestCamera:(RTSPCameraConfig *)camera completion:(void (^)(BOOL, NSString * _Nullable))completion {
    [[RTSPCameraTypeManager sharedManager] testCameraConnection:camera completion:^(BOOL success, NSDictionary *diagnostics, NSError *error) {
        if (success) {
            if (completion) completion(YES, nil);
        } else {
            if (completion) completion(NO, error.localizedDescription);
        }
    }];
}

- (void)testAllCamerasWithProgress:(void (^)(NSInteger, NSInteger))progressHandler completion:(void (^)(NSArray<RTSPCameraDiagnosticReport *> *))completion {
    RTSPCameraTypeManager *manager = [RTSPCameraTypeManager sharedManager];

    NSMutableArray *allCameras = [NSMutableArray arrayWithArray:manager.rtspCameras];

    NSMutableArray<RTSPCameraDiagnosticReport *> *allReports = [NSMutableArray array];
    __block NSInteger tested = 0;
    NSInteger total = allCameras.count;

    if (total == 0) {
        if (completion) completion(@[]);
        return;
    }

    NSLog(@"[Diagnostics] Testing %ld cameras...", (long)total);

    for (RTSPCameraConfig *camera in allCameras) {
        [self testCamera:camera completion:^(RTSPCameraDiagnosticReport *report) {
            [allReports addObject:report];
            tested++;

            if (progressHandler) {
                progressHandler(tested, total);
            }

            if (tested == total) {
                NSLog(@"[Diagnostics] All cameras tested");
                if (completion) completion(allReports);
            }
        }];

        // Stagger tests to avoid overload
        [NSThread sleepForTimeInterval:0.5];
    }
}

- (RTSPCameraHealthStatus)healthStatusForCamera:(RTSPCameraConfig *)camera {
    RTSPCameraDiagnosticReport *report = self.reports[camera.cameraID];
    return report ? report.healthStatus : RTSPCameraHealthStatusUnknown;
}

- (NSArray<RTSPCameraConfig *> *)camerasWithHealthStatus:(RTSPCameraHealthStatus)status {
    NSMutableArray *cameras = [NSMutableArray array];
    RTSPCameraTypeManager *manager = [RTSPCameraTypeManager sharedManager];

    for (RTSPCameraDiagnosticReport *report in self.reports.allValues) {
        if (report.healthStatus == status) {
            RTSPCameraConfig *camera = [manager cameraWithID:report.cameraID];
            if (camera) {
                [cameras addObject:camera];
            }
        }
    }

    return cameras;
}

- (NSArray<RTSPCameraConfig *> *)unhealthyCameras {
    NSMutableArray *cameras = [NSMutableArray array];
    [cameras addObjectsFromArray:[self camerasWithHealthStatus:RTSPCameraHealthStatusWarning]];
    [cameras addObjectsFromArray:[self camerasWithHealthStatus:RTSPCameraHealthStatusCritical]];
    return cameras;
}

- (void)clearReportForCamera:(RTSPCameraConfig *)camera {
    [self.reports removeObjectForKey:camera.cameraID];
}

- (void)clearAllReports {
    [self.reports removeAllObjects];
    NSLog(@"[Diagnostics] Cleared all reports");
}

- (void)startHealthMonitoring {
    if (self.monitoringTimer) {
        return;
    }

    self.monitoringTimer = [NSTimer scheduledTimerWithTimeInterval:self.healthCheckInterval
                                                            target:self
                                                          selector:@selector(performHealthChecks)
                                                          userInfo:nil
                                                           repeats:YES];

    NSLog(@"[Diagnostics] Started health monitoring (interval: %.0fs)", self.healthCheckInterval);

    // Run initial check
    [self performHealthChecks];
}

- (void)stopHealthMonitoring {
    [self.monitoringTimer invalidate];
    self.monitoringTimer = nil;

    NSLog(@"[Diagnostics] Stopped health monitoring");
}

- (void)performHealthChecks {
    RTSPCameraTypeManager *manager = [RTSPCameraTypeManager sharedManager];

    NSMutableArray *allCameras = [NSMutableArray arrayWithArray:manager.rtspCameras];

    for (RTSPCameraConfig *camera in allCameras) {
        if (camera.enabled) {
            [self quickTestCamera:camera completion:^(BOOL healthy, NSString * _Nullable issue) {
                // Health check completed, no action needed for automatic monitoring
            }];
        }
    }
}

- (BOOL)exportDiagnosticsToFile:(NSString *)filePath {
    NSMutableArray *reportDicts = [NSMutableArray array];

    for (RTSPCameraDiagnosticReport *report in self.reports.allValues) {
        [reportDicts addObject:[report toDictionary]];
    }

    NSDictionary *export = @{
        @"exportDate": [NSDate date],
        @"reports": reportDicts,
        @"summary": [self systemHealthSummary]
    };

    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:export options:NSJSONWritingPrettyPrinted error:&error];

    if (error) {
        NSLog(@"[Diagnostics] Export failed: %@", error);
        return NO;
    }

    BOOL success = [data writeToFile:filePath atomically:YES];

    if (success) {
        NSLog(@"[Diagnostics] Exported diagnostics to: %@", filePath);
    }

    return success;
}

- (NSDictionary *)systemHealthSummary {
    NSInteger healthy = 0, warning = 0, critical = 0, unknown = 0;

    for (RTSPCameraDiagnosticReport *report in self.reports.allValues) {
        switch (report.healthStatus) {
            case RTSPCameraHealthStatusHealthy: healthy++; break;
            case RTSPCameraHealthStatusWarning: warning++; break;
            case RTSPCameraHealthStatusCritical: critical++; break;
            default: unknown++; break;
        }
    }

    NSInteger total = healthy + warning + critical + unknown;
    CGFloat healthPercentage = total > 0 ? (CGFloat)healthy / total * 100.0 : 0.0;

    return @{
        @"totalCameras": @(total),
        @"healthy": @(healthy),
        @"warning": @(warning),
        @"critical": @(critical),
        @"unknown": @(unknown),
        @"healthPercentage": @(healthPercentage)
    };
}

- (void)dealloc {
    [self stopHealthMonitoring];
}

@end
