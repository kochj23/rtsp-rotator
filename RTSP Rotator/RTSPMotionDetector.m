//
//  RTSPMotionDetector.m
//  RTSP Rotator
//

#import "RTSPMotionDetector.h"
#import <CoreImage/CoreImage.h>

@interface RTSPMotionDetector ()
@property (nonatomic, weak) AVPlayer *player;
@property (nonatomic, strong) NSTimer *monitoringTimer;
@property (nonatomic, strong) CIImage *previousFrame;
@property (nonatomic, assign) BOOL motionDetected;
@end

@implementation RTSPMotionDetector

- (instancetype)initWithPlayer:(AVPlayer *)player {
    self = [super init];
    if (self) {
        _player = player;
        _enabled = NO;
        _sensitivity = 0.5;
        _checkInterval = 0.5;
        _motionDetected = NO;
    }
    return self;
}

- (void)startMonitoring {
    if (!self.enabled || self.monitoringTimer) {
        return;
    }

    self.monitoringTimer = [NSTimer scheduledTimerWithTimeInterval:self.checkInterval
                                                            target:self
                                                          selector:@selector(checkForMotion)
                                                          userInfo:nil
                                                           repeats:YES];

    NSLog(@"[Motion] Started monitoring (sensitivity: %.2f)", self.sensitivity);
}

- (void)stopMonitoring {
    [self.monitoringTimer invalidate];
    self.monitoringTimer = nil;
    self.previousFrame = nil;
    self.motionDetected = NO;

    NSLog(@"[Motion] Stopped monitoring");
}

- (void)checkForMotion {
    if (!self.player.currentItem) {
        return;
    }

    // Get current frame
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.player.currentItem.asset];
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    generator.requestedTimeToleranceAfter = kCMTimeZero;

    CMTime currentTime = self.player.currentTime;

    if (@available(macOS 13.0, *)) {
        [generator generateCGImageAsynchronouslyForTime:currentTime completionHandler:^(CGImageRef imageRef, CMTime actualTime, NSError *error) {
            if (imageRef) {
                CIImage *currentFrame = [CIImage imageWithCGImage:imageRef];

                if (self.previousFrame) {
                    CGFloat difference = [self calculateDifferenceBetween:self.previousFrame and:currentFrame];

                    BOOL hasMotion = difference > (1.0 - self.sensitivity);

                    if (hasMotion && !self.motionDetected) {
                        self.motionDetected = YES;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if ([self.delegate respondsToSelector:@selector(motionDetector:didDetectMotionWithConfidence:)]) {
                                [self.delegate motionDetector:self didDetectMotionWithConfidence:difference];
                            }
                        });
                        NSLog(@"[Motion] Motion detected (confidence: %.2f)", difference);
                    } else if (!hasMotion && self.motionDetected) {
                        self.motionDetected = NO;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if ([self.delegate respondsToSelector:@selector(motionDetectorDidStopMotion:)]) {
                                [self.delegate motionDetectorDidStopMotion:self];
                            }
                        });
                        NSLog(@"[Motion] Motion stopped");
                    }
                }

                self.previousFrame = currentFrame;
            }
        }];
    } else {
        // Fallback for macOS 11.0-12.x: use synchronous API
        NSError *error = nil;
        CGImageRef imageRef = [generator copyCGImageAtTime:currentTime actualTime:NULL error:&error];
        if (imageRef) {
            CIImage *currentFrame = [CIImage imageWithCGImage:imageRef];

            if (self.previousFrame) {
                CGFloat difference = [self calculateDifferenceBetween:self.previousFrame and:currentFrame];

                BOOL hasMotion = difference > (1.0 - self.sensitivity);

                if (hasMotion && !self.motionDetected) {
                    self.motionDetected = YES;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([self.delegate respondsToSelector:@selector(motionDetector:didDetectMotionWithConfidence:)]) {
                            [self.delegate motionDetector:self didDetectMotionWithConfidence:difference];
                        }
                    });
                    NSLog(@"[Motion] Motion detected (confidence: %.2f)", difference);
                } else if (!hasMotion && self.motionDetected) {
                    self.motionDetected = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([self.delegate respondsToSelector:@selector(motionDetectorDidStopMotion:)]) {
                            [self.delegate motionDetectorDidStopMotion:self];
                        }
                    });
                    NSLog(@"[Motion] Motion stopped");
                }
            }

            self.previousFrame = currentFrame;
            CGImageRelease(imageRef);
        }
    }
}

- (CGFloat)calculateDifferenceBetween:(CIImage *)image1 and:(CIImage *)image2 {
    // Simple pixel difference calculation
    CIFilter *differenceFilter = [CIFilter filterWithName:@"CIDifferenceBlendMode"];
    [differenceFilter setValue:image1 forKey:kCIInputImageKey];
    [differenceFilter setValue:image2 forKey:kCIInputBackgroundImageKey];

    CIImage *differenceImage = differenceFilter.outputImage;

    if (!differenceImage) {
        return 0.0;
    }

    // Calculate average pixel intensity
    CIFilter *areaAverageFilter = [CIFilter filterWithName:@"CIAreaAverage"];
    [areaAverageFilter setValue:differenceImage forKey:kCIInputImageKey];
    [areaAverageFilter setValue:[CIVector vectorWithCGRect:differenceImage.extent] forKey:kCIInputExtentKey];

    CIImage *averageImage = areaAverageFilter.outputImage;

    if (!averageImage) {
        return 0.0;
    }

    // Extract pixel value
    uint8_t pixel[4] = {0};
    CIContext *context = [CIContext contextWithOptions:nil];
    [context render:averageImage toBitmap:pixel rowBytes:4 bounds:CGRectMake(0, 0, 1, 1) format:kCIFormatRGBA8 colorSpace:nil];

    // Return average intensity (0.0 - 1.0)
    CGFloat average = (pixel[0] + pixel[1] + pixel[2]) / (3.0 * 255.0);
    return average;
}

- (void)dealloc {
    [self stopMonitoring];
}

@end
