//
//  RTSPAudioMonitor.m
//  RTSP Rotator
//

#import "RTSPAudioMonitor.h"

@interface RTSPAudioMonitor ()
@property (nonatomic, weak) AVPlayer *player;
@property (nonatomic, strong) NSTimer *monitoringTimer;
@property (nonatomic, assign) CGFloat currentLevel;
@property (nonatomic, assign) CGFloat peakLevel;
@property (nonatomic, assign) CGFloat averageLevel;
@property (nonatomic, assign) BOOL isSilent;
@property (nonatomic, assign) NSTimeInterval silenceStartTime;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *levelHistory;
@end

@implementation RTSPAudioMonitor

- (instancetype)initWithPlayer:(AVPlayer *)player {
    self = [super init];
    if (self) {
        _player = player;
        _enabled = NO;
        _updateInterval = 0.1;
        _loudNoiseThreshold = 0.8;
        _silenceThreshold = 0.1;
        _silenceDuration = 2.0;
        _currentLevel = 0.0;
        _peakLevel = 0.0;
        _averageLevel = 0.0;
        _isSilent = NO;
        _silenceStartTime = 0;
        _levelHistory = [NSMutableArray array];
    }
    return self;
}

- (void)startMonitoring {
    if (!self.enabled || self.monitoringTimer) {
        return;
    }

    self.monitoringTimer = [NSTimer scheduledTimerWithTimeInterval:self.updateInterval
                                                            target:self
                                                          selector:@selector(updateAudioLevels)
                                                          userInfo:nil
                                                           repeats:YES];

    NSLog(@"[Audio] Started monitoring (update interval: %.2fs)", self.updateInterval);
}

- (void)stopMonitoring {
    [self.monitoringTimer invalidate];
    self.monitoringTimer = nil;
    self.currentLevel = 0.0;
    self.isSilent = NO;
    [self.levelHistory removeAllObjects];

    NSLog(@"[Audio] Stopped monitoring");
}

- (void)updateAudioLevels {
    if (!self.player.currentItem) {
        return;
    }

    // Get audio tracks - use new async API
    if (@available(macOS 12.0, *)) {
        [self.player.currentItem.asset loadTracksWithMediaType:AVMediaTypeAudio completionHandler:^(NSArray<AVAssetTrack *> * _Nullable audioTracks, NSError * _Nullable error) {
            if (error || audioTracks.count == 0) {
                return;
            }

            // Simulate audio level reading (in production, would use AVAudioMix or audio tap)
            // For now, we'll generate sample data based on player state
            CGFloat level = [self simulateAudioLevel];

            dispatch_async(dispatch_get_main_queue(), ^{
                self.currentLevel = level;

                // Update peak
                if (level > self.peakLevel) {
                    self.peakLevel = level;
                }

                // Update history for average calculation
                [self.levelHistory addObject:@(level)];
                if (self.levelHistory.count > 30) { // Keep last 3 seconds at 0.1s interval
                [self.levelHistory removeObjectAtIndex:0];
            }

            // Calculate average
            CGFloat sum = 0;
            for (NSNumber *value in self.levelHistory) {
                sum += [value floatValue];
            }
            self.averageLevel = sum / self.levelHistory.count;

            // Notify delegate of level update
            if ([self.delegate respondsToSelector:@selector(audioMonitor:didDetectAudioLevel:)]) {
                [self.delegate audioMonitor:self didDetectAudioLevel:level];
            }

            if ([self.delegate respondsToSelector:@selector(audioMonitor:didUpdatePeakLevel:averageLevel:)]) {
                [self.delegate audioMonitor:self didUpdatePeakLevel:self.peakLevel averageLevel:self.averageLevel];
            }

            // Check for loud noise alert
            if (level >= self.loudNoiseThreshold) {
                [self triggerAlert:RTSPAudioAlertTypeLoudNoise level:level];
            }

            // Check for silence
            if (level <= self.silenceThreshold) {
                if (!self.isSilent) {
                    if (self.silenceStartTime == 0) {
                        self.silenceStartTime = [[NSDate date] timeIntervalSince1970];
                    } else {
                        NSTimeInterval elapsed = [[NSDate date] timeIntervalSince1970] - self.silenceStartTime;
                        if (elapsed >= self.silenceDuration) {
                            self.isSilent = YES;
                            [self triggerAlert:RTSPAudioAlertTypeSilence level:level];
                        }
                    }
                }
            } else {
                if (self.isSilent) {
                    self.isSilent = NO;
                    NSLog(@"[Audio] Audio resumed");
                }
                self.silenceStartTime = 0;
            }
        });
    }];
    } else {
        // Fallback for macOS 11.0-11.x: use synchronous API
        NSArray<AVAssetTrack *> *audioTracks = [self.player.currentItem.asset tracksWithMediaType:AVMediaTypeAudio];
        if (audioTracks.count == 0) {
            return;
        }

        // Simulate audio level reading
        CGFloat level = [self simulateAudioLevel];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.currentLevel = level;

            // Update peak
            if (level > self.peakLevel) {
                self.peakLevel = level;
            }

            // Update history
            [self.levelHistory addObject:@(level)];
            if (self.levelHistory.count > 30) {
                [self.levelHistory removeObjectAtIndex:0];
            }

            // Calculate average
            CGFloat sum = 0;
            for (NSNumber *value in self.levelHistory) {
                sum += [value floatValue];
            }
            self.averageLevel = sum / self.levelHistory.count;

            // Notify delegate
            if ([self.delegate respondsToSelector:@selector(audioMonitor:didDetectAudioLevel:)]) {
                [self.delegate audioMonitor:self didDetectAudioLevel:level];
            }

            if ([self.delegate respondsToSelector:@selector(audioMonitor:didUpdatePeakLevel:averageLevel:)]) {
                [self.delegate audioMonitor:self didUpdatePeakLevel:self.peakLevel averageLevel:self.averageLevel];
            }

            // Check for loud noise alert
            if (level >= self.loudNoiseThreshold) {
                [self triggerAlert:RTSPAudioAlertTypeLoudNoise level:level];
            }

            // Check for silence
            if (level <= self.silenceThreshold) {
                if (!self.isSilent) {
                    if (self.silenceStartTime == 0) {
                        self.silenceStartTime = [[NSDate date] timeIntervalSince1970];
                    } else {
                        NSTimeInterval elapsed = [[NSDate date] timeIntervalSince1970] - self.silenceStartTime;
                        if (elapsed >= self.silenceDuration) {
                            self.isSilent = YES;
                            [self triggerAlert:RTSPAudioAlertTypeSilence level:level];
                        }
                    }
                }
            } else {
                if (self.isSilent) {
                    self.isSilent = NO;
                    NSLog(@"[Audio] Audio resumed");
                }
                self.silenceStartTime = 0;
            }
        });
    }
}

- (CGFloat)simulateAudioLevel {
    // In production, this would read actual audio samples
    // For now, simulate varying audio levels
    static CGFloat simulatedLevel = 0.3;

    // Random walk simulation
    CGFloat change = ((CGFloat)arc4random() / UINT32_MAX - 0.5) * 0.1;
    simulatedLevel += change;

    // Keep within bounds
    if (simulatedLevel < 0.0) simulatedLevel = 0.0;
    if (simulatedLevel > 1.0) simulatedLevel = 1.0;

    // Occasionally spike to test loud noise detection
    if (arc4random() % 100 == 0) {
        simulatedLevel = 0.9;
    }

    // Occasionally drop to test silence detection
    if (arc4random() % 150 == 0) {
        simulatedLevel = 0.05;
    }

    return simulatedLevel;
}

- (void)triggerAlert:(RTSPAudioAlertType)alertType level:(CGFloat)level {
    if ([self.delegate respondsToSelector:@selector(audioMonitor:didTriggerAlert:level:)]) {
        [self.delegate audioMonitor:self didTriggerAlert:alertType level:level];
    }

    NSString *alertName = @"Unknown";
    switch (alertType) {
        case RTSPAudioAlertTypeLoudNoise:
            alertName = @"Loud Noise";
            break;
        case RTSPAudioAlertTypeSilence:
            alertName = @"Silence";
            break;
        case RTSPAudioAlertTypeFrequencyDetected:
            alertName = @"Frequency";
            break;
    }

    NSLog(@"[Audio] Alert: %@ (level: %.2f)", alertName, level);
}

- (void)resetPeakLevel {
    self.peakLevel = 0.0;
    NSLog(@"[Audio] Reset peak level");
}

- (void)dealloc {
    [self stopMonitoring];
}

@end
