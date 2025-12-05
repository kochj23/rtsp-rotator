//
//  RTSPBandwidthManager.h
//  RTSP Rotator
//
//  Bandwidth management and optimization
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTSPQualityPreset) {
    RTSPQualityPresetAuto,
    RTSPQualityPresetLow,
    RTSPQualityPresetMedium,
    RTSPQualityPresetHigh
};

@interface RTSPBandwidthManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, assign) RTSPQualityPreset qualityPreset;
@property (nonatomic, assign) CGFloat maxBandwidthMbps;
@property (nonatomic, assign) BOOL autoQualityEnabled;

- (void)optimizePlayer:(AVPlayer *)player;
- (NSString *)recommendedQuality;

@end

NS_ASSUME_NONNULL_END
