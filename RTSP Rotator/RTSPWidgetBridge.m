//
//  RTSPWidgetBridge.m
//  RTSP Rotator
//
//  Bridge for updating widget data from the main Objective-C app
//  Created by Jordan Koch
//

#import "RTSPWidgetBridge.h"

// Note: WidgetKit's WidgetCenter.shared.reloadTimelines() is Swift-only
// The widget will automatically refresh every 5 minutes via its timeline policy
// For immediate refresh, you can post a notification that a Swift helper catches
static NSString * const kWidgetRefreshNotification = @"com.jkoch.rtsprotator.refreshWidget";

// App Group constants
static NSString * const kAppGroupIdentifier = @"group.com.jkoch.rtsprotator";
static NSString * const kCameraDataKey = @"widget_camera_data";
static NSString * const kCurrentCameraIndexKey = @"widget_current_camera_index";
static NSString * const kTotalDetectionsKey = @"widget_total_detections";
static NSString * const kLastUpdateTimeKey = @"widget_last_update_time";
static NSString * const kIsAppRunningKey = @"widget_is_app_running";

#pragma mark - RTSPWidgetCameraInfo Implementation

@implementation RTSPWidgetCameraInfo

- (instancetype)init {
    self = [super init];
    if (self) {
        _identifier = @"";
        _name = @"";
        _displayName = @"";
        _healthStatus = RTSPWidgetHealthStatusUnknown;
        _detectionCount = 0;
        _lastDetectionTime = nil;
        _lastDetectionType = nil;
        _isEnabled = YES;
        _uptimePercentage = 0.0;
        _consecutiveFailures = 0;
        _lastSuccessfulConnection = nil;
    }
    return self;
}

/// Convert to dictionary for JSON encoding
- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    dict[@"id"] = self.identifier ?: @"";
    dict[@"name"] = self.name ?: @"";
    dict[@"displayName"] = self.displayName ?: self.name ?: @"";
    dict[@"healthStatus"] = @(self.healthStatus);
    dict[@"detectionCount"] = @(self.detectionCount);
    dict[@"isEnabled"] = @(self.isEnabled);
    dict[@"uptimePercentage"] = @(self.uptimePercentage);
    dict[@"consecutiveFailures"] = @(self.consecutiveFailures);

    if (self.lastDetectionTime) {
        dict[@"lastDetectionTime"] = @([self.lastDetectionTime timeIntervalSince1970]);
    }

    if (self.lastDetectionType) {
        dict[@"lastDetectionType"] = self.lastDetectionType;
    }

    if (self.lastSuccessfulConnection) {
        dict[@"lastSuccessfulConnection"] = @([self.lastSuccessfulConnection timeIntervalSince1970]);
    }

    return dict;
}

/// Create from dictionary
+ (instancetype)fromDictionary:(NSDictionary *)dict {
    RTSPWidgetCameraInfo *info = [[RTSPWidgetCameraInfo alloc] init];

    info.identifier = dict[@"id"] ?: @"";
    info.name = dict[@"name"] ?: @"";
    info.displayName = dict[@"displayName"] ?: info.name;
    info.healthStatus = [dict[@"healthStatus"] integerValue];
    info.detectionCount = [dict[@"detectionCount"] integerValue];
    info.isEnabled = [dict[@"isEnabled"] boolValue];
    info.uptimePercentage = [dict[@"uptimePercentage"] doubleValue];
    info.consecutiveFailures = [dict[@"consecutiveFailures"] integerValue];

    if (dict[@"lastDetectionTime"]) {
        info.lastDetectionTime = [NSDate dateWithTimeIntervalSince1970:[dict[@"lastDetectionTime"] doubleValue]];
    }

    info.lastDetectionType = dict[@"lastDetectionType"];

    if (dict[@"lastSuccessfulConnection"]) {
        info.lastSuccessfulConnection = [NSDate dateWithTimeIntervalSince1970:[dict[@"lastSuccessfulConnection"] doubleValue]];
    }

    return info;
}

@end

#pragma mark - RTSPWidgetBridge Implementation

@interface RTSPWidgetBridge ()

@property (nonatomic, strong) NSUserDefaults *sharedDefaults;

@end

@implementation RTSPWidgetBridge

#pragma mark - Singleton

+ (instancetype)sharedBridge {
    static RTSPWidgetBridge *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RTSPWidgetBridge alloc] init];
    });
    return shared;
}

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        _sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupIdentifier];

        if (!_sharedDefaults) {
            NSLog(@"[RTSPWidgetBridge] Warning: Could not initialize UserDefaults with App Group: %@", kAppGroupIdentifier);
        }
    }
    return self;
}

#pragma mark - Properties

- (NSString *)appGroupIdentifier {
    return kAppGroupIdentifier;
}

#pragma mark - Camera Data

- (void)updateCameras:(NSArray<RTSPWidgetCameraInfo *> *)cameras {
    if (!self.sharedDefaults) {
        NSLog(@"[RTSPWidgetBridge] Shared defaults not available");
        return;
    }

    NSMutableArray *cameraArray = [NSMutableArray arrayWithCapacity:cameras.count];
    for (RTSPWidgetCameraInfo *camera in cameras) {
        [cameraArray addObject:[camera toDictionary]];
    }

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:cameraArray options:0 error:&error];

    if (error) {
        NSLog(@"[RTSPWidgetBridge] Error encoding camera data: %@", error);
        return;
    }

    [self.sharedDefaults setObject:jsonData forKey:kCameraDataKey];
    [self.sharedDefaults setObject:[NSDate date] forKey:kLastUpdateTimeKey];
    [self.sharedDefaults synchronize];

    [self refreshWidgetTimeline];

    NSLog(@"[RTSPWidgetBridge] Saved %lu cameras to widget data", (unsigned long)cameras.count);
}

- (NSArray<RTSPWidgetCameraInfo *> *)loadCameras {
    if (!self.sharedDefaults) {
        return @[];
    }

    NSData *jsonData = [self.sharedDefaults dataForKey:kCameraDataKey];
    if (!jsonData) {
        return @[];
    }

    NSError *error = nil;
    NSArray *cameraArray = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];

    if (error) {
        NSLog(@"[RTSPWidgetBridge] Error decoding camera data: %@", error);
        return @[];
    }

    NSMutableArray<RTSPWidgetCameraInfo *> *cameras = [NSMutableArray arrayWithCapacity:cameraArray.count];
    for (NSDictionary *dict in cameraArray) {
        [cameras addObject:[RTSPWidgetCameraInfo fromDictionary:dict]];
    }

    return cameras;
}

#pragma mark - Current Camera Index

- (void)updateCurrentCameraIndex:(NSInteger)index {
    [self.sharedDefaults setInteger:index forKey:kCurrentCameraIndexKey];
    [self.sharedDefaults synchronize];
    [self refreshWidgetTimeline];
}

#pragma mark - Detection Count

- (void)updateTotalDetections:(NSInteger)count {
    [self.sharedDefaults setInteger:count forKey:kTotalDetectionsKey];
    [self.sharedDefaults synchronize];
}

#pragma mark - App Running State

- (void)updateAppRunningState:(BOOL)isRunning {
    [self.sharedDefaults setBool:isRunning forKey:kIsAppRunningKey];
    [self.sharedDefaults synchronize];
    [self refreshWidgetTimeline];
}

#pragma mark - Full Update

- (void)updateWidgetWithCameras:(NSArray<RTSPWidgetCameraInfo *> *)cameras
             currentCameraIndex:(NSInteger)currentIndex
                totalDetections:(NSInteger)totalDetections
                   isAppRunning:(BOOL)isRunning {

    if (!self.sharedDefaults) {
        NSLog(@"[RTSPWidgetBridge] Shared defaults not available");
        return;
    }

    // Encode cameras
    NSMutableArray *cameraArray = [NSMutableArray arrayWithCapacity:cameras.count];
    for (RTSPWidgetCameraInfo *camera in cameras) {
        [cameraArray addObject:[camera toDictionary]];
    }

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:cameraArray options:0 error:&error];

    if (error) {
        NSLog(@"[RTSPWidgetBridge] Error encoding camera data: %@", error);
        return;
    }

    // Update all values
    [self.sharedDefaults setObject:jsonData forKey:kCameraDataKey];
    [self.sharedDefaults setInteger:currentIndex forKey:kCurrentCameraIndexKey];
    [self.sharedDefaults setInteger:totalDetections forKey:kTotalDetectionsKey];
    [self.sharedDefaults setBool:isRunning forKey:kIsAppRunningKey];
    [self.sharedDefaults setObject:[NSDate date] forKey:kLastUpdateTimeKey];
    [self.sharedDefaults synchronize];

    [self refreshWidgetTimeline];

    NSLog(@"[RTSPWidgetBridge] Full widget update completed with %lu cameras", (unsigned long)cameras.count);
}

#pragma mark - Single Camera Updates

- (void)updateCameraHealth:(NSString *)cameraID status:(RTSPWidgetHealthStatus)status {
    NSArray<RTSPWidgetCameraInfo *> *cameras = [self loadCameras];

    for (RTSPWidgetCameraInfo *camera in cameras) {
        if ([camera.identifier isEqualToString:cameraID]) {
            camera.healthStatus = status;

            if (status == RTSPWidgetHealthStatusHealthy) {
                camera.lastSuccessfulConnection = [NSDate date];
                camera.consecutiveFailures = 0;
            } else if (status == RTSPWidgetHealthStatusUnhealthy) {
                camera.consecutiveFailures++;
            }

            break;
        }
    }

    [self updateCameras:cameras];
}

- (void)updateCameraDetection:(NSString *)cameraID detectionType:(NSString *)type {
    NSArray<RTSPWidgetCameraInfo *> *cameras = [self loadCameras];

    for (RTSPWidgetCameraInfo *camera in cameras) {
        if ([camera.identifier isEqualToString:cameraID]) {
            camera.detectionCount++;
            camera.lastDetectionTime = [NSDate date];
            camera.lastDetectionType = type;
            break;
        }
    }

    [self updateCameras:cameras];

    // Update total detections
    NSInteger totalDetections = [self.sharedDefaults integerForKey:kTotalDetectionsKey] + 1;
    [self updateTotalDetections:totalDetections];
}

#pragma mark - Clear Data

- (void)clearWidgetData {
    [self.sharedDefaults removeObjectForKey:kCameraDataKey];
    [self.sharedDefaults removeObjectForKey:kCurrentCameraIndexKey];
    [self.sharedDefaults removeObjectForKey:kTotalDetectionsKey];
    [self.sharedDefaults removeObjectForKey:kLastUpdateTimeKey];
    [self.sharedDefaults removeObjectForKey:kIsAppRunningKey];
    [self.sharedDefaults synchronize];

    [self refreshWidgetTimeline];

    NSLog(@"[RTSPWidgetBridge] Widget data cleared");
}

#pragma mark - Widget Refresh

- (void)refreshWidgetTimeline {
    // Post a notification that can be caught by a Swift helper to reload the widget
    // WidgetCenter is Swift-only, so we use a notification pattern instead
    [[NSNotificationCenter defaultCenter] postNotificationName:kWidgetRefreshNotification
                                                        object:nil
                                                      userInfo:nil];

    // Also post to DistributedNotificationCenter for cross-process communication
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:kWidgetRefreshNotification
                                                                   object:nil
                                                                 userInfo:nil];

    NSLog(@"[RTSPWidgetBridge] Widget refresh notification posted");
}

@end
