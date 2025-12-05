//
//  RTSPPTZController.m
//  RTSP Rotator
//

#import "RTSPPTZController.h"

@implementation RTSPPTZPreset
@end

@interface RTSPPTZController ()
@property (nonatomic, strong) NSURL *cameraURL;
@property (nonatomic, strong, nullable) NSString *username;
@property (nonatomic, strong, nullable) NSString *password;
@property (nonatomic, assign) BOOL supportsPTZ;
@property (nonatomic, strong) NSMutableArray<RTSPPTZPreset *> *presets;
@property (nonatomic, strong, nullable) NSTimer *autoTourTimer;
@property (nonatomic, assign) NSInteger currentPresetIndex;
@end

@implementation RTSPPTZController

- (instancetype)initWithURL:(NSURL *)cameraURL username:(NSString *)username password:(NSString *)password {
    self = [super init];
    if (self) {
        _cameraURL = cameraURL;
        _username = username;
        _password = password;
        _supportsPTZ = NO;
        _presets = [NSMutableArray array];
        _currentPresetIndex = 0;

        [self detectPTZCapabilities];
    }
    return self;
}

- (void)detectPTZCapabilities {
    // Simple PTZ capability detection
    // In production, this would use ONVIF GetCapabilities
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // For now, assume cameras with specific ports support PTZ
        NSInteger port = [[self.cameraURL port] integerValue];
        self.supportsPTZ = (port == 80 || port == 554 || port == 8080);

        NSLog(@"[PTZ] Detected PTZ support: %@", self.supportsPTZ ? @"YES" : @"NO");
    });
}

- (void)move:(RTSPPTZDirection)direction speed:(CGFloat)speed completion:(void (^)(BOOL, NSError * _Nullable))completion {
    if (!self.supportsPTZ) {
        NSError *error = [NSError errorWithDomain:@"RTSPPTZController"
                                             code:1001
                                         userInfo:@{NSLocalizedDescriptionKey: @"Camera does not support PTZ"}];
        if (completion) completion(NO, error);
        return;
    }

    NSString *directionStr = [self stringForDirection:direction];
    NSLog(@"[PTZ] Moving %@ at speed %.2f", directionStr, speed);

    // Simulate PTZ command
    // In production, this would send ONVIF PTZ commands
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Simulate network delay
        [NSThread sleepForTimeInterval:0.1];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(YES, nil);
        });
    });
}

- (void)stop:(void (^)(BOOL))completion {
    NSLog(@"[PTZ] Stopping movement");

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:0.05];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(YES);
        });
    });
}

- (void)goToPosition:(CGFloat)pan tilt:(CGFloat)tilt zoom:(CGFloat)zoom completion:(void (^)(BOOL, NSError * _Nullable))completion {
    NSLog(@"[PTZ] Going to position pan:%.2f tilt:%.2f zoom:%.2f", pan, tilt, zoom);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:0.2];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(YES, nil);
        });
    });
}

- (void)savePreset:(NSString *)name completion:(void (^)(RTSPPTZPreset * _Nullable, NSError * _Nullable))completion {
    RTSPPTZPreset *preset = [[RTSPPTZPreset alloc] init];
    preset.name = name;
    preset.presetID = self.presets.count + 1;
    preset.pan = 0.5;  // Current position (simulated)
    preset.tilt = 0.5;
    preset.zoom = 0.5;

    [self.presets addObject:preset];

    NSLog(@"[PTZ] Saved preset: %@ (ID: %ld)", name, (long)preset.presetID);

    if (completion) completion(preset, nil);
}

- (void)goToPreset:(RTSPPTZPreset *)preset completion:(void (^)(BOOL, NSError * _Nullable))completion {
    NSLog(@"[PTZ] Going to preset: %@", preset.name);

    [self goToPosition:preset.pan tilt:preset.tilt zoom:preset.zoom completion:completion];
}

- (void)listPresetsWithCompletion:(void (^)(NSArray<RTSPPTZPreset *> * _Nullable, NSError * _Nullable))completion {
    if (completion) completion([self.presets copy], nil);
}

- (void)deletePreset:(RTSPPTZPreset *)preset completion:(void (^)(BOOL, NSError * _Nullable))completion {
    [self.presets removeObject:preset];

    NSLog(@"[PTZ] Deleted preset: %@", preset.name);

    if (completion) completion(YES, nil);
}

- (void)startAutoTourWithInterval:(NSTimeInterval)interval completion:(void (^)(BOOL))completion {
    if (self.presets.count == 0) {
        NSLog(@"[PTZ] Cannot start auto-tour: no presets defined");
        if (completion) completion(NO);
        return;
    }

    [self stopAutoTour];

    self.currentPresetIndex = 0;
    self.autoTourTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                          target:self
                                                        selector:@selector(autoTourTick)
                                                        userInfo:nil
                                                         repeats:YES];

    NSLog(@"[PTZ] Started auto-tour with %ld presets, interval: %.1fs", (long)self.presets.count, interval);

    if (completion) completion(YES);
}

- (void)stopAutoTour {
    [self.autoTourTimer invalidate];
    self.autoTourTimer = nil;

    NSLog(@"[PTZ] Stopped auto-tour");
}

- (void)autoTourTick {
    if (self.presets.count == 0) {
        [self stopAutoTour];
        return;
    }

    RTSPPTZPreset *preset = self.presets[self.currentPresetIndex];
    [self goToPreset:preset completion:nil];

    self.currentPresetIndex = (self.currentPresetIndex + 1) % self.presets.count;
}

- (NSString *)stringForDirection:(RTSPPTZDirection)direction {
    switch (direction) {
        case RTSPPTZDirectionUp: return @"Up";
        case RTSPPTZDirectionDown: return @"Down";
        case RTSPPTZDirectionLeft: return @"Left";
        case RTSPPTZDirectionRight: return @"Right";
        case RTSPPTZDirectionZoomIn: return @"Zoom In";
        case RTSPPTZDirectionZoomOut: return @"Zoom Out";
    }
}

- (void)dealloc {
    [self stopAutoTour];
}

@end
