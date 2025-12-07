//
//  RTSPSmartAlerts.m
//  RTSP Rotator
//
//  Enhanced with MLX object detection
//

#import "RTSPSmartAlerts.h"
#import <UserNotifications/UserNotifications.h>
#import <AppKit/AppKit.h>

@interface RTSPSmartAlerts () <RTSPObjectDetectorDelegate>

@property (nonatomic, weak) AVPlayer *player;
@property (nonatomic, copy) NSString *cameraID;
@property (nonatomic, copy) NSString *cameraName;
@property (nonatomic, strong) NSTimer *monitoringTimer;
@property (nonatomic, strong) RTSPObjectDetector *objectDetector;
@property (nonatomic, strong) NSMutableArray<RTSPDetectionEvent *> *alertHistoryList;
@property (nonatomic, assign) NSInteger alertCount;
@property (nonatomic, strong) NSDate *lastAlertTime;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDate *> *lastAlertByClass;

@end

@implementation RTSPSmartAlerts

- (instancetype)initWithPlayer:(AVPlayer *)player {
    if (self = [super init]) {
        _player = player;
        _cameraID = [[NSUUID UUID] UUIDString];
        _cameraName = @"Camera";
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCameraID:(NSString *)cameraID cameraName:(NSString *)cameraName {
    if (self = [super init]) {
        _cameraID = cameraID;
        _cameraName = cameraName;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _enabled = NO;
    _confidenceThreshold = 0.5;
    _checkInterval = 1.0;
    _useMLX = YES;
    _alertMode = RTSPAlertModeAny;
    _cooldownPeriod = 30.0;
    _sendSystemNotifications = YES;
    _shouldPlayAlertSound = YES;
    _alertSoundName = nil;
    _alertCount = 0;
    _alertHistoryList = [NSMutableArray array];
    _lastAlertByClass = [NSMutableDictionary dictionary];

    if (_useMLX) {
        _objectDetector = [RTSPObjectDetector sharedDetector];
        _objectDetector.delegate = self;

        // Configure MLX processor
        RTSPMLXConfiguration *config = [RTSPMLXConfiguration defaultConfiguration];
        config.confidenceThreshold = _confidenceThreshold;
        _objectDetector.mlxProcessor.configuration = config;
    }

    NSLog(@"[SmartAlerts] Initialized for camera: %@ (MLX: %@)", _cameraName, _useMLX ? @"YES" : @"NO");
}

- (void)startMonitoring {
    if (!self.enabled) {
        NSLog(@"[SmartAlerts] Cannot start - alerts are disabled");
        return;
    }

    if (self.monitoringTimer) {
        NSLog(@"[SmartAlerts] Already monitoring");
        return;
    }

    if (self.useMLX) {
        // Enable MLX detection for this camera
        [self.objectDetector enableDetectionForCamera:self.cameraID zones:nil];
    }

    if (self.player) {
        // Start timer to extract and process frames
        self.monitoringTimer = [NSTimer scheduledTimerWithTimeInterval:self.checkInterval
                                                                target:self
                                                              selector:@selector(analyzeFrame)
                                                              userInfo:nil
                                                               repeats:YES];
    }

    NSLog(@"[SmartAlerts] Started monitoring camera: %@", self.cameraName);
}

- (void)stopMonitoring {
    [self.monitoringTimer invalidate];
    self.monitoringTimer = nil;

    if (self.useMLX) {
        [self.objectDetector disableDetectionForCamera:self.cameraID];
    }

    NSLog(@"[SmartAlerts] Stopped monitoring camera: %@", self.cameraName);
}

- (void)processFrame:(CVPixelBufferRef)pixelBuffer {
    if (!self.enabled) return;
    if (!self.useMLX) return;

    // Process frame with MLX object detector
    [self.objectDetector processFrame:pixelBuffer
                           fromCamera:self.cameraID
                                 name:self.cameraName];
}

- (void)analyzeFrame {
    if (!self.player.currentItem) return;

    // Get current frame from player
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.player.currentItem.asset];
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    generator.requestedTimeToleranceAfter = kCMTimeZero;

    CMTime currentTime = self.player.currentTime;

    if (@available(macOS 13.0, *)) {
        [generator generateCGImageAsynchronouslyForTime:currentTime completionHandler:^(CGImageRef imageRef, CMTime actualTime, NSError *error) {
            if (imageRef) {
                if (self.useMLX) {
                    // Use MLX for detection
                    [self.objectDetector.mlxProcessor processImage:imageRef completion:^(NSArray<RTSPDetection *> * _Nullable detections, NSError * _Nullable error) {
                        if (detections && !error) {
                            [self handleDetections:detections];
                        }
                    }];
                } else {
                    // Fallback to Vision framework
                    [self performVisionAnalysis:imageRef];
                }
            }
        }];
    } else {
        // Fallback for macOS 11.0-12.x
        NSError *error = nil;
        CGImageRef imageRef = [generator copyCGImageAtTime:currentTime actualTime:NULL error:&error];
        if (imageRef) {
            if (self.useMLX) {
                [self.objectDetector.mlxProcessor processImage:imageRef completion:^(NSArray<RTSPDetection *> * _Nullable detections, NSError * _Nullable error) {
                    if (detections && !error) {
                        [self handleDetections:detections];
                    }
                }];
            } else {
                [self performVisionAnalysis:imageRef];
            }
            CGImageRelease(imageRef);
        }
    }
}

- (void)handleDetections:(NSArray<RTSPDetection *> *)detections {
    if (self.alertMode == RTSPAlertModeDisabled) return;

    for (RTSPDetection *detection in detections) {
        // Check confidence threshold
        if (detection.confidence < self.confidenceThreshold) continue;

        // Check class filter
        if (self.alertClasses && ![self.alertClasses containsObject:detection.label]) {
            continue;
        }

        // Check cooldown
        if ([self shouldCooldownForClass:detection.label]) {
            continue;
        }

        // Trigger alert
        [self triggerAlertForDetection:detection];
    }
}

- (BOOL)shouldCooldownForClass:(NSString *)className {
    NSDate *lastAlert = self.lastAlertByClass[className];
    if (!lastAlert) return NO;

    NSTimeInterval timeSinceLastAlert = [[NSDate date] timeIntervalSinceDate:lastAlert];
    return timeSinceLastAlert < self.cooldownPeriod;
}

- (void)triggerAlertForDetection:(RTSPDetection *)detection {
    // Create event
    RTSPDetectionEvent *event = [[RTSPDetectionEvent alloc] init];
    event.cameraID = self.cameraID;
    event.cameraName = self.cameraName;
    event.detection = detection;
    event.timestamp = [NSDate date];
    event.alertTriggered = YES;

    // Update statistics
    self.alertCount++;
    self.lastAlertTime = event.timestamp;
    self.lastAlertByClass[detection.label] = event.timestamp;

    // Add to history
    [self.alertHistoryList addObject:event];
    if (self.alertHistoryList.count > 100) {
        [self.alertHistoryList removeObjectAtIndex:0];
    }

    NSString *message = [NSString stringWithFormat:@"%@ detected on %@",
                        [self capitalizeFirst:detection.label], self.cameraName];

    NSLog(@"[SmartAlerts] ALERT: %@", message);

    // Play sound
    if (self.shouldPlayAlertSound) {
        [self playAlertSound];
    }

    // Send notification
    if (self.sendSystemNotifications) {
        [self sendNotification:message detection:detection];
    }

    // Notify delegate
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(smartAlerts:didTriggerAlert:forEvent:)]) {
            [self.delegate smartAlerts:self didTriggerAlert:message forEvent:event];
        }

        if ([self.delegate respondsToSelector:@selector(smartAlerts:didDetectEvent:)]) {
            [self.delegate smartAlerts:self didDetectEvent:event];
        }

        // Legacy delegate method
        if ([self.delegate respondsToSelector:@selector(smartAlerts:didDetectObject:confidence:)]) {
            RTSPDetectedObjectType type = [self objectTypeForClass:detection.label];
            [self.delegate smartAlerts:self didDetectObject:type confidence:detection.confidence];
        }
    });
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

- (void)playAlertSound {
    NSSound *sound;
    if (self.alertSoundName) {
        sound = [NSSound soundNamed:self.alertSoundName];
    } else {
        sound = [NSSound soundNamed:@"Ping"];
    }
    [sound play];
}

- (void)sendNotification:(NSString *)message detection:(RTSPDetection *)detection {
    if (@available(macOS 10.14, *)) {
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = @"RTSP Rotator Alert";
        content.body = message;
        content.sound = [UNNotificationSound defaultSound];

        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString]
                                                                              content:content
                                                                              trigger:nil];

        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request
                                                                withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"[SmartAlerts] Notification error: %@", error);
            }
        }];
    }
}

- (RTSPDetectedObjectType)objectTypeForClass:(NSString *)className {
    className = className.lowercaseString;

    if ([className isEqualToString:@"person"]) {
        return RTSPDetectedObjectTypePerson;
    } else if ([className containsString:@"car"] || [className containsString:@"vehicle"] ||
               [className containsString:@"truck"] || [className containsString:@"bus"]) {
        return RTSPDetectedObjectTypeVehicle;
    } else if ([className containsString:@"dog"] || [className containsString:@"cat"] ||
               [className containsString:@"bird"] || [className containsString:@"animal"]) {
        return RTSPDetectedObjectTypeAnimal;
    } else if ([className containsString:@"package"] || [className containsString:@"box"]) {
        return RTSPDetectedObjectTypePackage;
    }

    return RTSPDetectedObjectTypeOther;
}

- (NSString *)capitalizeFirst:(NSString *)string {
    if (string.length == 0) return string;
    return [string stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                            withString:[[string substringToIndex:1] uppercaseString]];
}

- (void)resetStatistics {
    self.alertCount = 0;
    self.lastAlertTime = nil;
    [self.lastAlertByClass removeAllObjects];
    [self.alertHistoryList removeAllObjects];

    NSLog(@"[SmartAlerts] Statistics reset");
}

- (NSArray<RTSPDetectionEvent *> *)alertHistory:(NSInteger)limit {
    NSInteger start = MAX(0, (NSInteger)self.alertHistoryList.count - limit);
    return [self.alertHistoryList subarrayWithRange:NSMakeRange(start, self.alertHistoryList.count - start)];
}

#pragma mark - RTSPObjectDetectorDelegate

- (void)objectDetector:(RTSPObjectDetector *)detector didDetectEvent:(RTSPDetectionEvent *)event {
    // Filter by camera
    if (![event.cameraID isEqualToString:self.cameraID]) return;

    // Handle detection
    [self handleDetections:@[event.detection]];

    // Forward to delegate
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(smartAlerts:didDetectEvent:)]) {
            [self.delegate smartAlerts:self didDetectEvent:event];
        }
    });
}

- (void)dealloc {
    [self stopMonitoring];
}

@end
