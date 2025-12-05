//
//  RTSPCameraTypeManager.m
//  RTSP Rotator
//

#import "RTSPCameraTypeManager.h"
#import <AVFoundation/AVFoundation.h>

@implementation RTSPStandardCameraConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        self.cameraType = @"RTSP";
        _port = 554;
        _connectionTimeout = 10.0;
        _maxRetries = 3;
        _preferredFramerate = 30;
        _hasAudio = NO;
        _enableAudio = NO;
        _audioVolume = 0.5;
        _useUDP = NO;
        _bufferSize = 1000;
        _supportsPTZ = NO;
    }
    return self;
}

- (NSURL *)buildRTSPURL {
    if (self.feedURL) {
        return self.feedURL;
    }

    // Build from components
    NSString *scheme = self.usesTLS ? @"rtsps" : @"rtsp";
    NSString *host = @""; // Should be set separately
    NSString *streamPath = self.streamPath ?: @"/stream";

    NSString *urlString;
    if (self.username && self.password) {
        urlString = [NSString stringWithFormat:@"%@://%@:%@@%@:%ld%@",
                    scheme, self.username, self.password, host, (long)self.port, streamPath];
    } else {
        urlString = [NSString stringWithFormat:@"%@://%@:%ld%@",
                    scheme, host, (long)self.port, streamPath];
    }

    return [NSURL URLWithString:urlString];
}

- (void)testConnectionWithCompletion:(void (^)(BOOL, NSError * _Nullable))completion {
    if (!self.feedURL) {
        NSError *error = [NSError errorWithDomain:@"RTSPCameraTypeManager"
                                            code:1001
                                        userInfo:@{NSLocalizedDescriptionKey: @"No feed URL configured"}];
        if (completion) completion(NO, error);
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVPlayer *testPlayer = [[AVPlayer alloc] init];
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:self.feedURL];

        __block BOOL completed = NO;
        NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:self.connectionTimeout];

        [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
        [testPlayer replaceCurrentItemWithPlayerItem:item];

        while (!completed && [[NSDate date] compare:timeout] == NSOrderedAscending) {
            if (item.status == AVPlayerItemStatusReadyToPlay) {
                completed = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(YES, nil);
                });
                break;
            } else if (item.status == AVPlayerItemStatusFailed) {
                completed = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(NO, item.error);
                });
                break;
            }
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }

        if (!completed) {
            NSError *error = [NSError errorWithDomain:@"RTSPCameraTypeManager"
                                                code:1002
                                            userInfo:@{NSLocalizedDescriptionKey: @"Connection timeout"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, error);
            });
        }

        [item removeObserver:self forKeyPath:@"status"];
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // Observer for test connection
}

@end

@implementation RTSPGoogleHomeCameraConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        self.cameraType = @"GoogleHome";
        _isStreaming = NO;
        _supportsLiveStream = YES;
        _supportsSnapshot = YES;
        _supportsTwoWayAudio = NO;
        _supportsMotionDetection = NO;
        _supportsSoundDetection = NO;
    }
    return self;
}

- (void)refreshStreamWithCompletion:(void (^)(BOOL, NSError * _Nullable))completion {
    RTSPGoogleHomeAdapter *adapter = [RTSPGoogleHomeAdapter sharedAdapter];

    // Create temporary camera object
    RTSPGoogleHomeCamera *camera = [[RTSPGoogleHomeCamera alloc] init];
    camera.deviceID = self.deviceID;
    camera.displayName = self.name;

    [adapter getStreamURLForCamera:camera completionHandler:^(NSURL *streamURL, NSError *error) {
        if (error) {
            if (completion) completion(NO, error);
            return;
        }

        self.feedURL = streamURL;
        self.isStreaming = YES;
        self.streamExpiresAt = [NSDate dateWithTimeIntervalSinceNow:300]; // 5 minutes

        if (completion) completion(YES, nil);
    }];
}

- (void)captureSnapshotWithCompletion:(void (^)(NSImage * _Nullable, NSError * _Nullable))completion {
    if (!self.snapshotURL) {
        NSError *error = [NSError errorWithDomain:@"RTSPCameraTypeManager"
                                            code:1003
                                        userInfo:@{NSLocalizedDescriptionKey: @"No snapshot URL available"}];
        if (completion) completion(nil, error);
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *imageData = [NSData dataWithContentsOfURL:self.snapshotURL];

        if (imageData) {
            NSImage *image = [[NSImage alloc] initWithData:imageData];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(image, nil);
            });
        } else {
            NSError *error = [NSError errorWithDomain:@"RTSPCameraTypeManager"
                                                code:1004
                                            userInfo:@{NSLocalizedDescriptionKey: @"Failed to load snapshot"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(nil, error);
            });
        }
    });
}

@end

@interface RTSPCameraTypeManager ()
@property (nonatomic, strong) NSMutableArray<RTSPStandardCameraConfig *> *allRTSPCameras;
@property (nonatomic, strong) NSMutableArray<RTSPGoogleHomeCameraConfig *> *allGoogleHomeCameras;
@end

@implementation RTSPCameraTypeManager

+ (instancetype)sharedManager {
    static RTSPCameraTypeManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RTSPCameraTypeManager alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _allRTSPCameras = [NSMutableArray array];
        _allGoogleHomeCameras = [NSMutableArray array];
        [self loadCameras];
    }
    return self;
}

- (NSArray<RTSPStandardCameraConfig *> *)rtspCameras {
    return [self.allRTSPCameras copy];
}

- (NSArray<RTSPGoogleHomeCameraConfig *> *)googleHomeCameras {
    return [self.allGoogleHomeCameras copy];
}

- (void)addRTSPCamera:(RTSPStandardCameraConfig *)camera {
    [self.allRTSPCameras addObject:camera];
    [self saveCameras];

    NSLog(@"[CameraTypeManager] Added RTSP camera: %@", camera.name);

    if ([self.delegate respondsToSelector:@selector(cameraTypeManager:didUpdateCamera:)]) {
        [self.delegate cameraTypeManager:self didUpdateCamera:camera];
    }
}

- (void)addGoogleHomeCamera:(RTSPGoogleHomeCameraConfig *)camera {
    [self.allGoogleHomeCameras addObject:camera];
    [self saveCameras];

    NSLog(@"[CameraTypeManager] Added Google Home camera: %@", camera.name);

    if ([self.delegate respondsToSelector:@selector(cameraTypeManager:didUpdateCamera:)]) {
        [self.delegate cameraTypeManager:self didUpdateCamera:camera];
    }
}

- (void)removeCameraWithID:(NSString *)cameraID {
    RTSPCameraConfig *camera = [self cameraWithID:cameraID];

    if ([camera isKindOfClass:[RTSPStandardCameraConfig class]]) {
        [self.allRTSPCameras removeObject:(RTSPStandardCameraConfig *)camera];
    } else if ([camera isKindOfClass:[RTSPGoogleHomeCameraConfig class]]) {
        [self.allGoogleHomeCameras removeObject:(RTSPGoogleHomeCameraConfig *)camera];
    }

    [self saveCameras];
    NSLog(@"[CameraTypeManager] Removed camera: %@", cameraID);
}

- (RTSPCameraConfig *)cameraWithID:(NSString *)cameraID {
    for (RTSPStandardCameraConfig *camera in self.allRTSPCameras) {
        if ([camera.cameraID isEqualToString:cameraID]) {
            return camera;
        }
    }

    for (RTSPGoogleHomeCameraConfig *camera in self.allGoogleHomeCameras) {
        if ([camera.cameraID isEqualToString:cameraID]) {
            return camera;
        }
    }

    return nil;
}

- (void)testCameraConnection:(RTSPCameraConfig *)camera completion:(void (^)(BOOL, NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSMutableDictionary *diagnostics = [NSMutableDictionary dictionary];
    diagnostics[@"cameraID"] = camera.cameraID;
    diagnostics[@"cameraName"] = camera.name;
    diagnostics[@"cameraType"] = camera.cameraType;
    diagnostics[@"testStartTime"] = [NSDate date];

    if ([camera isKindOfClass:[RTSPStandardCameraConfig class]]) {
        RTSPStandardCameraConfig *rtspCamera = (RTSPStandardCameraConfig *)camera;

        [rtspCamera testConnectionWithCompletion:^(BOOL success, NSError *error) {
            diagnostics[@"testEndTime"] = [NSDate date];
            diagnostics[@"connectionSuccess"] = @(success);
            diagnostics[@"feedURL"] = rtspCamera.feedURL.absoluteString;

            if (error) {
                diagnostics[@"error"] = error.localizedDescription;
                diagnostics[@"errorCode"] = @(error.code);
            }

            RTSPCameraConnectionStatus status = success ? RTSPCameraConnectionStatusConnected : RTSPCameraConnectionStatusFailed;

            if ([self.delegate respondsToSelector:@selector(cameraTypeManager:cameraConnectionChanged:status:)]) {
                [self.delegate cameraTypeManager:self cameraConnectionChanged:camera status:status];
            }

            if (completion) completion(success, diagnostics, error);
        }];

    } else if ([camera isKindOfClass:[RTSPGoogleHomeCameraConfig class]]) {
        RTSPGoogleHomeCameraConfig *ghCamera = (RTSPGoogleHomeCameraConfig *)camera;

        [ghCamera refreshStreamWithCompletion:^(BOOL success, NSError *error) {
            diagnostics[@"testEndTime"] = [NSDate date];
            diagnostics[@"connectionSuccess"] = @(success);
            diagnostics[@"deviceID"] = ghCamera.deviceID;
            diagnostics[@"isStreaming"] = @(ghCamera.isStreaming);

            if (ghCamera.streamExpiresAt) {
                diagnostics[@"streamExpiresAt"] = ghCamera.streamExpiresAt;
            }

            if (error) {
                diagnostics[@"error"] = error.localizedDescription;
            }

            RTSPCameraConnectionStatus status = success ? RTSPCameraConnectionStatusConnected : RTSPCameraConnectionStatusFailed;

            if ([self.delegate respondsToSelector:@selector(cameraTypeManager:cameraConnectionChanged:status:)]) {
                [self.delegate cameraTypeManager:self cameraConnectionChanged:camera status:status];
            }

            if (completion) completion(success, diagnostics, error);
        }];
    }
}

- (NSArray<RTSPCameraConfig *> *)camerasOfType:(NSString *)type {
    if ([type isEqualToString:@"RTSP"]) {
        return [self.allRTSPCameras copy];
    } else if ([type isEqualToString:@"GoogleHome"]) {
        return [self.allGoogleHomeCameras copy];
    }
    return @[];
}

- (BOOL)importCamerasFromFile:(NSString *)filePath error:(NSError **)error {
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) {
        if (error) {
            *error = [NSError errorWithDomain:@"RTSPCameraTypeManager"
                                        code:2001
                                    userInfo:@{NSLocalizedDescriptionKey: @"Failed to read file"}];
        }
        return NO;
    }

    NSDictionary *config = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    if (!config) {
        return NO;
    }

    // Import RTSP cameras
    NSArray *rtspCameras = config[@"rtspCameras"];
    for (NSDictionary *cameraDict in rtspCameras) {
        RTSPStandardCameraConfig *camera = [[RTSPStandardCameraConfig alloc] init];
        camera.name = cameraDict[@"name"];
        camera.feedURL = [NSURL URLWithString:cameraDict[@"url"]];
        camera.username = cameraDict[@"username"];
        camera.password = cameraDict[@"password"];
        camera.location = cameraDict[@"location"];
        [self addRTSPCamera:camera];
    }

    NSLog(@"[CameraTypeManager] Imported %lu cameras from file", (unsigned long)rtspCameras.count);
    return YES;
}

- (BOOL)exportCamerasToFile:(NSString *)filePath error:(NSError **)error {
    NSMutableDictionary *config = [NSMutableDictionary dictionary];

    NSMutableArray *rtspArray = [NSMutableArray array];
    for (RTSPStandardCameraConfig *camera in self.allRTSPCameras) {
        [rtspArray addObject:@{
            @"name": camera.name ?: @"",
            @"url": camera.feedURL.absoluteString ?: @"",
            @"username": camera.username ?: @"",
            @"password": camera.password ?: @"",
            @"location": camera.location ?: @""
        }];
    }
    config[@"rtspCameras"] = rtspArray;

    NSMutableArray *ghArray = [NSMutableArray array];
    for (RTSPGoogleHomeCameraConfig *camera in self.allGoogleHomeCameras) {
        [ghArray addObject:@{
            @"name": camera.name ?: @"",
            @"deviceID": camera.deviceID ?: @"",
            @"deviceType": camera.deviceType ?: @"",
            @"roomName": camera.roomName ?: @""
        }];
    }
    config[@"googleHomeCameras"] = ghArray;

    NSData *data = [NSJSONSerialization dataWithJSONObject:config options:NSJSONWritingPrettyPrinted error:error];
    if (!data) {
        return NO;
    }

    return [data writeToFile:filePath atomically:YES];
}

- (void)discoverRTSPCamerasWithCompletion:(void (^)(NSArray<RTSPStandardCameraConfig *> *))completion {
    // ONVIF discovery would go here
    // This is a placeholder for network camera discovery

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"[CameraTypeManager] Starting ONVIF camera discovery...");

        // In production, this would use ONVIF WS-Discovery protocol
        // For now, return empty array

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(@[]);
            }
        });
    });
}

- (BOOL)saveCameras {
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *appFolder = [appSupport stringByAppendingPathComponent:@"RTSP Rotator"];

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:appFolder]) {
        [fm createDirectoryAtPath:appFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *camerasPath = [appFolder stringByAppendingPathComponent:@"camera_types.dat"];

    NSDictionary *data = @{
        @"rtspCameras": self.allRTSPCameras,
        @"googleHomeCameras": self.allGoogleHomeCameras
    };

    NSError *error = nil;
    NSData *archiveData = [NSKeyedArchiver archivedDataWithRootObject:data requiringSecureCoding:YES error:&error];

    if (error) {
        NSLog(@"[CameraTypeManager] Failed to save cameras: %@", error);
        return NO;
    }

    BOOL success = [archiveData writeToFile:camerasPath atomically:YES];
    if (success) {
        NSLog(@"[CameraTypeManager] Saved %lu RTSP + %lu Google Home cameras",
              (unsigned long)self.allRTSPCameras.count, (unsigned long)self.allGoogleHomeCameras.count);
    }

    return success;
}

- (BOOL)loadCameras {
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *camerasPath = [[appSupport stringByAppendingPathComponent:@"RTSP Rotator"] stringByAppendingPathComponent:@"camera_types.dat"];

    if (![[NSFileManager defaultManager] fileExistsAtPath:camerasPath]) {
        NSLog(@"[CameraTypeManager] No saved cameras found");
        return NO;
    }

    NSError *error = nil;
    NSData *archiveData = [NSData dataWithContentsOfFile:camerasPath];

    NSSet *classes = [NSSet setWithArray:@[
        [NSDictionary class],
        [NSArray class],
        [NSMutableArray class],
        [RTSPStandardCameraConfig class],
        [RTSPGoogleHomeCameraConfig class],
        [RTSPCameraConfig class],
        [NSString class],
        [NSURL class],
        [NSNumber class],
        [NSDate class]
    ]];

    NSDictionary *data = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:archiveData error:&error];

    if (error) {
        NSLog(@"[CameraTypeManager] Failed to load cameras: %@", error);
        return NO;
    }

    self.allRTSPCameras = [NSMutableArray arrayWithArray:data[@"rtspCameras"]];
    self.allGoogleHomeCameras = [NSMutableArray arrayWithArray:data[@"googleHomeCameras"]];

    NSLog(@"[CameraTypeManager] Loaded %lu RTSP + %lu Google Home cameras",
          (unsigned long)self.allRTSPCameras.count, (unsigned long)self.allGoogleHomeCameras.count);

    return YES;
}

@end
