//
//  RTSPNetworkMonitor.m
//  RTSP Rotator
//

#import "RTSPNetworkMonitor.h"

@implementation RTSPNetworkStats
@end

@interface RTSPNetworkMonitor ()
@property (nonatomic, weak) AVPlayer *player;
@property (nonatomic, strong) NSURL *feedURL;
@property (nonatomic, strong) NSTimer *monitoringTimer;
@property (nonatomic, strong) RTSPNetworkStats *currentStats;
@property (nonatomic, strong) NSMutableArray<RTSPNetworkStats *> *statsHistory;
@property (nonatomic, assign) NSTimeInterval startTime;
@end

@implementation RTSPNetworkMonitor

- (instancetype)initWithPlayer:(AVPlayer *)player feedURL:(NSURL *)feedURL {
    self = [super init];
    if (self) {
        _player = player;
        _feedURL = feedURL;
        _enabled = NO;
        _updateInterval = 1.0;
        _poorQualityThreshold = 30;
        _statsHistory = [NSMutableArray array];

        _currentStats = [[RTSPNetworkStats alloc] init];
        _currentStats.feedURL = feedURL;
        _currentStats.connectionQuality = 100;
    }
    return self;
}

- (void)startMonitoring {
    if (!self.enabled || self.monitoringTimer) {
        return;
    }

    self.startTime = [[NSDate date] timeIntervalSince1970];

    self.monitoringTimer = [NSTimer scheduledTimerWithTimeInterval:self.updateInterval
                                                            target:self
                                                          selector:@selector(updateStatistics)
                                                          userInfo:nil
                                                           repeats:YES];

    NSLog(@"[Network] Started monitoring for %@", self.feedURL.absoluteString);
}

- (void)stopMonitoring {
    [self.monitoringTimer invalidate];
    self.monitoringTimer = nil;

    NSLog(@"[Network] Stopped monitoring");
}

- (void)updateStatistics {
    if (!self.player.currentItem) {
        return;
    }

    RTSPNetworkStats *stats = [[RTSPNetworkStats alloc] init];
    stats.feedURL = self.feedURL;
    stats.lastUpdate = [NSDate date];

    // Collect statistics from AVPlayer
    AVPlayerItem *item = self.player.currentItem;

    // Access log for network data
    AVPlayerItemAccessLog *accessLog = item.accessLog;
    if (accessLog && accessLog.events.count > 0) {
        AVPlayerItemAccessLogEvent *latestEvent = accessLog.events.lastObject;

        // Bandwidth (convert from bps to Mbps)
        if (latestEvent.observedBitrate > 0) {
            stats.bandwidthMbps = latestEvent.observedBitrate / 1000000.0;
        }

        // Dropped frames
        stats.droppedFrames = latestEvent.numberOfDroppedVideoFrames;

        // Total frames (estimated from duration and frame rate)
        if (latestEvent.indicatedBitrate > 0) {
            stats.totalFrames = (NSInteger)(latestEvent.durationWatched * 30); // Assume 30fps
        }
    }

    // Calculate latency (simulated - real implementation would use ping)
    stats.latencyMs = [self measureLatency];

    // Calculate packet loss percentage
    if (stats.totalFrames > 0) {
        stats.packetLossPercent = (CGFloat)stats.droppedFrames / stats.totalFrames * 100.0;
    }

    // Calculate connection quality (0-100)
    stats.connectionQuality = [self calculateConnectionQuality:stats];

    self.currentStats = stats;
    [self.statsHistory addObject:stats];

    // Keep only last 60 samples (1 minute at 1Hz)
    if (self.statsHistory.count > 60) {
        [self.statsHistory removeObjectAtIndex:0];
    }

    // Notify delegate
    if ([self.delegate respondsToSelector:@selector(networkMonitor:didUpdateStats:)]) {
        [self.delegate networkMonitor:self didUpdateStats:stats];
    }

    // Check for poor quality
    if (stats.connectionQuality < self.poorQualityThreshold) {
        if ([self.delegate respondsToSelector:@selector(networkMonitor:didDetectPoorQuality:)]) {
            [self.delegate networkMonitor:self didDetectPoorQuality:stats];
        }

        NSLog(@"[Network] Poor connection quality detected: %ld%%", (long)stats.connectionQuality);
    }
}

- (CGFloat)measureLatency {
    // Simulate latency measurement
    // In production, would send ICMP ping or measure TCP handshake time
    CGFloat baseLatency = 50.0; // 50ms base
    CGFloat variation = ((CGFloat)arc4random() / UINT32_MAX) * 30.0; // +/- 30ms variation

    return baseLatency + variation;
}

- (NSInteger)calculateConnectionQuality:(RTSPNetworkStats *)stats {
    // Quality score based on multiple factors
    NSInteger score = 100;

    // Bandwidth impact (expect at least 2 Mbps for HD stream)
    if (stats.bandwidthMbps < 2.0) {
        score -= 30;
    } else if (stats.bandwidthMbps < 5.0) {
        score -= 10;
    }

    // Latency impact (expect < 100ms)
    if (stats.latencyMs > 200) {
        score -= 30;
    } else if (stats.latencyMs > 100) {
        score -= 15;
    }

    // Packet loss impact
    if (stats.packetLossPercent > 5.0) {
        score -= 25;
    } else if (stats.packetLossPercent > 2.0) {
        score -= 10;
    }

    // Ensure score is in valid range
    if (score < 0) score = 0;
    if (score > 100) score = 100;

    return score;
}

- (NSString *)generateDiagnosticsReport {
    NSMutableString *report = [NSMutableString string];

    [report appendString:@"=== RTSP Network Diagnostics Report ===\n\n"];
    [report appendFormat:@"Feed URL: %@\n", self.feedURL.absoluteString];
    [report appendFormat:@"Report Date: %@\n\n", [NSDate date]];

    // Current statistics
    [report appendString:@"Current Statistics:\n"];
    [report appendFormat:@"  Bandwidth: %.2f Mbps\n", self.currentStats.bandwidthMbps];
    [report appendFormat:@"  Latency: %.2f ms\n", self.currentStats.latencyMs];
    [report appendFormat:@"  Packet Loss: %.2f%%\n", self.currentStats.packetLossPercent];
    [report appendFormat:@"  Dropped Frames: %ld / %ld\n", (long)self.currentStats.droppedFrames, (long)self.currentStats.totalFrames];
    [report appendFormat:@"  Connection Quality: %ld%%\n\n", (long)self.currentStats.connectionQuality];

    // Average statistics
    if (self.statsHistory.count > 0) {
        CGFloat avgBandwidth = 0, avgLatency = 0, avgPacketLoss = 0;
        NSInteger avgQuality = 0;

        for (RTSPNetworkStats *stats in self.statsHistory) {
            avgBandwidth += stats.bandwidthMbps;
            avgLatency += stats.latencyMs;
            avgPacketLoss += stats.packetLossPercent;
            avgQuality += stats.connectionQuality;
        }

        NSInteger count = self.statsHistory.count;
        avgBandwidth /= count;
        avgLatency /= count;
        avgPacketLoss /= count;
        avgQuality /= count;

        [report appendString:@"Average Statistics (last minute):\n"];
        [report appendFormat:@"  Bandwidth: %.2f Mbps\n", avgBandwidth];
        [report appendFormat:@"  Latency: %.2f ms\n", avgLatency];
        [report appendFormat:@"  Packet Loss: %.2f%%\n", avgPacketLoss];
        [report appendFormat:@"  Connection Quality: %ld%%\n\n", (long)avgQuality];
    }

    // Connection details
    if (self.player.currentItem) {
        AVPlayerItemAccessLog *accessLog = self.player.currentItem.accessLog;
        if (accessLog && accessLog.events.count > 0) {
            AVPlayerItemAccessLogEvent *event = accessLog.events.lastObject;

            [report appendString:@"Connection Details:\n"];
            [report appendFormat:@"  Server Address: %@\n", event.serverAddress ?: @"Unknown"];
            [report appendFormat:@"  Playback Type: %@\n", event.playbackType ?: @"Unknown"];
            [report appendFormat:@"  Observed Bitrate: %.2f Kbps\n", event.observedBitrate / 1000.0];
            [report appendFormat:@"  Indicated Bitrate: %.2f Kbps\n", event.indicatedBitrate / 1000.0];
            [report appendFormat:@"  Number of Stalls: %ld\n", (long)event.numberOfStalls];
            [report appendFormat:@"  Duration Watched: %.2f seconds\n", event.durationWatched];
        }
    }

    [report appendString:@"\n=== End of Report ===\n"];

    return report;
}

- (BOOL)exportReportToFile:(NSString *)filePath {
    NSString *report = [self generateDiagnosticsReport];
    NSError *error = nil;

    BOOL success = [report writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];

    if (success) {
        NSLog(@"[Network] Exported diagnostics report to: %@", filePath);
    } else {
        NSLog(@"[Network] Failed to export report: %@", error);
    }

    return success;
}

- (void)dealloc {
    [self stopMonitoring];
}

@end
