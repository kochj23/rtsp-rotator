//
//  RTSPSmartAlerts.m
//  RTSP Rotator
//

#import "RTSPSmartAlerts.h"

@interface RTSPSmartAlerts ()
@property (nonatomic, weak) AVPlayer *player;
@property (nonatomic, strong) NSTimer *monitoringTimer;
@end

@implementation RTSPSmartAlerts

- (instancetype)initWithPlayer:(AVPlayer *)player {
    if (self = [super init]) {
        _player = player;
        _enabled = NO;
        _confidenceThreshold = 0.7;
        _checkInterval = 1.0;
    }
    return self;
}

- (void)startMonitoring {
    if (!self.enabled || self.monitoringTimer) return;

    self.monitoringTimer = [NSTimer scheduledTimerWithTimeInterval:self.checkInterval
                                                            target:self
                                                          selector:@selector(analyzeFrame)
                                                          userInfo:nil
                                                           repeats:YES];

    NSLog(@"[SmartAlerts] Started AI monitoring");
}

- (void)stopMonitoring {
    [self.monitoringTimer invalidate];
    self.monitoringTimer = nil;

    NSLog(@"[SmartAlerts] Stopped AI monitoring");
}

- (void)analyzeFrame {
    if (!self.player.currentItem) return;

    // Get current frame
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.player.currentItem.asset];
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    generator.requestedTimeToleranceAfter = kCMTimeZero;

    CMTime currentTime = self.player.currentTime;

    if (@available(macOS 13.0, *)) {
        [generator generateCGImageAsynchronouslyForTime:currentTime completionHandler:^(CGImageRef imageRef, CMTime actualTime, NSError *error) {
            if (imageRef) {
                [self performVisionAnalysis:imageRef];
            }
        }];
    } else {
        // Fallback for macOS 11.0-12.x: use synchronous API
        NSError *error = nil;
        CGImageRef imageRef = [generator copyCGImageAtTime:currentTime actualTime:NULL error:&error];
        if (imageRef) {
            [self performVisionAnalysis:imageRef];
            CGImageRelease(imageRef);
        }
    }
}

- (void)performVisionAnalysis:(CGImageRef)imageRef {
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:imageRef options:@{}];

    VNRecognizeAnimalsRequest *animalRequest = [[VNRecognizeAnimalsRequest alloc] initWithCompletionHandler:^(VNRequest *request, NSError *error) {
        if (error) return;

        for (VNRecognizedObjectObservation *observation in request.results) {
            if (observation.confidence >= self.confidenceThreshold) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.delegate respondsToSelector:@selector(smartAlerts:didDetectObject:confidence:)]) {
                        [self.delegate smartAlerts:self didDetectObject:RTSPDetectedObjectTypeAnimal confidence:observation.confidence];
                    }
                });
                NSLog(@"[SmartAlerts] Detected animal with confidence: %.2f", observation.confidence);
            }
        }
    }];

    [handler performRequests:@[animalRequest] error:nil];
}

- (void)dealloc {
    [self stopMonitoring];
}

@end
