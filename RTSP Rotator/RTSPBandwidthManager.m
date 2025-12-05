//
//  RTSPBandwidthManager.m
//  RTSP Rotator
//

#import "RTSPBandwidthManager.h"

@implementation RTSPBandwidthManager

+ (instancetype)sharedManager {
    static RTSPBandwidthManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RTSPBandwidthManager alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        _qualityPreset = RTSPQualityPresetAuto;
        _maxBandwidthMbps = 10.0;
        _autoQualityEnabled = YES;
    }
    return self;
}

- (void)optimizePlayer:(AVPlayer *)player {
    if (!player.currentItem) return;

    // Set preferred peak bit rate based on quality preset
    NSInteger bitrate = 0;

    switch (self.qualityPreset) {
        case RTSPQualityPresetLow:
            bitrate = 1000000; // 1 Mbps
            break;
        case RTSPQualityPresetMedium:
            bitrate = 3000000; // 3 Mbps
            break;
        case RTSPQualityPresetHigh:
            bitrate = 8000000; // 8 Mbps
            break;
        case RTSPQualityPresetAuto:
            bitrate = 0; // Let system decide
            break;
    }

    player.currentItem.preferredPeakBitRate = bitrate;

    NSLog(@"[Bandwidth] Optimized player with quality preset: %ld", (long)self.qualityPreset);
}

- (NSString *)recommendedQuality {
    if (self.maxBandwidthMbps < 2.0) return @"Low";
    if (self.maxBandwidthMbps < 5.0) return @"Medium";
    return @"High";
}

@end
