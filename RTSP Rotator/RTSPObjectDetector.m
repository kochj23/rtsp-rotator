//
//  RTSPObjectDetector.m
//  RTSP Rotator
//
//  High-level object detection manager for RTSP streams
//

#import "RTSPObjectDetector.h"
#import <AppKit/AppKit.h>

@implementation RTSPDetectionZone

- (instancetype)initWithName:(NSString *)name rect:(CGRect)rect {
    self = [super init];
    if (self) {
        _name = [name copy];
        _normalizedRect = rect;
        _enabled = YES;
        _enabledClasses = nil; // All classes
    }
    return self;
}

- (BOOL)containsDetection:(RTSPDetection *)detection {
    if (!self.enabled) return NO;

    // Check if detection bounding box intersects with zone
    CGRect detectionRect = detection.boundingBox;
    CGRect zoneRect = self.normalizedRect;

    BOOL intersects = CGRectIntersectsRect(detectionRect, zoneRect);

    if (!intersects) return NO;

    // Check class filter
    if (self.enabledClasses && ![self.enabledClasses containsObject:detection.label]) {
        return NO;
    }

    return YES;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<RTSPDetectionZone: %@ rect:(%.2f,%.2f,%.2f,%.2f) enabled:%@>",
            self.name,
            self.normalizedRect.origin.x, self.normalizedRect.origin.y,
            self.normalizedRect.size.width, self.normalizedRect.size.height,
            self.enabled ? @"YES" : @"NO"];
}

@end

@implementation RTSPDetectionEvent

- (NSString *)description {
    return [NSString stringWithFormat:@"<RTSPDetectionEvent: %@ - %@ @ %@>",
            self.cameraName, self.detection.label, self.timestamp];
}

@end

@interface RTSPObjectDetector () <RTSPMLXProcessorDelegate>

@property (nonatomic, strong) RTSPMLXProcessor *mlxProcessor;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<RTSPDetectionZone *> *> *cameraZones;
@property (nonatomic, strong) NSMutableArray<RTSPDetectionEvent *> *detectionHistory;
@property (nonatomic, strong) NSMutableSet<NSString *> *enabledCameras;
@property (nonatomic, strong) dispatch_queue_t eventQueue;
@property (nonatomic, assign) NSInteger maxHistorySize;

@end

@implementation RTSPObjectDetector

+ (instancetype)sharedDetector {
    static RTSPObjectDetector *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RTSPObjectDetector alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mlxProcessor = [RTSPMLXProcessor sharedProcessor];
        _mlxProcessor.delegate = self;
        _cameraZones = [NSMutableDictionary dictionary];
        _detectionHistory = [NSMutableArray array];
        _enabledCameras = [NSMutableSet set];
        _eventQueue = dispatch_queue_create("com.rtsp.objectdetector.events", DISPATCH_QUEUE_SERIAL);
        _detectionEnabled = YES;
        _maxHistorySize = 1000; // Keep last 1000 events

        NSLog(@"[ObjectDetector] Initialized with MLX Processor");
    }
    return self;
}

- (BOOL)initializeWithModel:(NSString *)modelPath error:(NSError **)error {
    NSLog(@"[ObjectDetector] Initializing with model: %@", modelPath);

    BOOL success = [self.mlxProcessor loadModel:modelPath error:error];

    if (success) {
        NSLog(@"[ObjectDetector] Model loaded successfully");
    } else {
        NSLog(@"[ObjectDetector] Failed to load model: %@", error ? *error : @"Unknown error");
    }

    return success;
}

- (void)enableDetectionForCamera:(NSString *)cameraID zones:(NSArray<RTSPDetectionZone *> *)zones {
    [self.enabledCameras addObject:cameraID];

    if (zones) {
        self.cameraZones[cameraID] = zones;
        NSLog(@"[ObjectDetector] Enabled detection for camera %@ with %lu zones", cameraID, (unsigned long)zones.count);
    } else {
        [self.cameraZones removeObjectForKey:cameraID];
        NSLog(@"[ObjectDetector] Enabled detection for camera %@ (full frame)", cameraID);
    }
}

- (void)disableDetectionForCamera:(NSString *)cameraID {
    [self.enabledCameras removeObject:cameraID];
    [self.cameraZones removeObjectForKey:cameraID];
    [self.mlxProcessor stopProcessingForCamera:cameraID];

    NSLog(@"[ObjectDetector] Disabled detection for camera %@", cameraID);
}

- (void)processFrame:(CVPixelBufferRef)pixelBuffer fromCamera:(NSString *)cameraID name:(NSString *)cameraName {
    if (!self.detectionEnabled) return;
    if (![self.enabledCameras containsObject:cameraID]) return;

    // Process frame with MLX
    [self.mlxProcessor processFrame:pixelBuffer
                          forCamera:cameraID
                         completion:^(NSArray<RTSPDetection *> * _Nullable detections, NSError * _Nullable error) {
        if (error) {
            NSLog(@"[ObjectDetector] Error processing frame for %@: %@", cameraID, error);
            return;
        }

        if (detections.count == 0) return;

        // Filter detections by zones
        NSArray<RTSPDetectionZone *> *zones = self.cameraZones[cameraID];
        NSArray<RTSPDetection *> *filteredDetections = detections;

        if (zones) {
            NSMutableArray *filtered = [NSMutableArray array];
            for (RTSPDetection *detection in detections) {
                for (RTSPDetectionZone *zone in zones) {
                    if ([zone containsDetection:detection]) {
                        [filtered addObject:detection];
                        break;
                    }
                }
            }
            filteredDetections = filtered;
        }

        // Create detection events
        for (RTSPDetection *detection in filteredDetections) {
            [self createEventForDetection:detection cameraID:cameraID cameraName:cameraName];
        }
    }];
}

- (void)createEventForDetection:(RTSPDetection *)detection
                       cameraID:(NSString *)cameraID
                     cameraName:(NSString *)cameraName {

    dispatch_async(self.eventQueue, ^{
        RTSPDetectionEvent *event = [[RTSPDetectionEvent alloc] init];
        event.cameraID = cameraID;
        event.cameraName = cameraName;
        event.detection = detection;
        event.timestamp = [NSDate date];
        event.alertTriggered = NO;

        // Find zone name if applicable
        NSArray<RTSPDetectionZone *> *zones = self.cameraZones[cameraID];
        for (RTSPDetectionZone *zone in zones) {
            if ([zone containsDetection:detection]) {
                event.zoneName = zone.name;
                break;
            }
        }

        // Add to history
        [self.detectionHistory addObject:event];

        // Trim history if needed
        if (self.detectionHistory.count > self.maxHistorySize) {
            [self.detectionHistory removeObjectsInRange:NSMakeRange(0, self.detectionHistory.count - self.maxHistorySize)];
        }

        // Notify delegate
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(objectDetector:didDetectEvent:)]) {
                [self.delegate objectDetector:self didDetectEvent:event];
            }
        });

        NSLog(@"[ObjectDetector] Event: %@ detected %@ in %@%@",
              cameraName, detection.label,
              event.zoneName ?: @"frame",
              event.alertTriggered ? @" (ALERT)" : @"");
    });
}

- (NSArray<RTSPDetectionZone *> *)zonesForCamera:(NSString *)cameraID {
    return self.cameraZones[cameraID];
}

- (void)setZones:(NSArray<RTSPDetectionZone *> *)zones forCamera:(NSString *)cameraID {
    self.cameraZones[cameraID] = zones;
    NSLog(@"[ObjectDetector] Set %lu zones for camera %@", (unsigned long)zones.count, cameraID);
}

- (NSArray<RTSPDetectionEvent *> *)recentEvents:(NSInteger)limit {
    __block NSArray *events;
    dispatch_sync(self.eventQueue, ^{
        NSInteger start = MAX(0, (NSInteger)self.detectionHistory.count - limit);
        events = [self.detectionHistory subarrayWithRange:NSMakeRange(start, self.detectionHistory.count - start)];
    });
    return events;
}

- (NSDictionary *)statistics {
    __block NSDictionary *stats;

    dispatch_sync(self.eventQueue, ^{
        // Count detections by class
        NSMutableDictionary *classCounts = [NSMutableDictionary dictionary];
        NSMutableDictionary *cameraCounts = [NSMutableDictionary dictionary];

        for (RTSPDetectionEvent *event in self.detectionHistory) {
            NSString *label = event.detection.label;
            classCounts[label] = @([classCounts[label] integerValue] + 1);

            NSString *camera = event.cameraName ?: event.cameraID;
            cameraCounts[camera] = @([cameraCounts[camera] integerValue] + 1);
        }

        // Get MLX performance metrics
        NSDictionary *mlxMetrics = [self.mlxProcessor performanceMetrics];

        stats = @{
            @"totalEvents": @(self.detectionHistory.count),
            @"enabledCameras": @(self.enabledCameras.count),
            @"detectionsByClass": classCounts,
            @"detectionsByCamera": cameraCounts,
            @"mlxPerformance": mlxMetrics,
            @"historySize": @(self.detectionHistory.count),
            @"maxHistorySize": @(self.maxHistorySize)
        };
    });

    return stats;
}

- (void)clearHistory {
    dispatch_async(self.eventQueue, ^{
        [self.detectionHistory removeAllObjects];
        NSLog(@"[ObjectDetector] Cleared detection history");
    });
}

- (BOOL)exportEventsToCSV:(NSString *)filePath error:(NSError **)error {
    __block NSArray *events;
    dispatch_sync(self.eventQueue, ^{
        events = [self.detectionHistory copy];
    });

    if (events.count == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"RTSPObjectDetector"
                                        code:400
                                    userInfo:@{NSLocalizedDescriptionKey: @"No events to export"}];
        }
        return NO;
    }

    NSMutableString *csv = [NSMutableString string];

    // Header
    [csv appendString:@"Timestamp,Camera ID,Camera Name,Object,Confidence,X,Y,Width,Height,Zone,Alert\n"];

    // Rows
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";

    for (RTSPDetectionEvent *event in events) {
        RTSPDetection *det = event.detection;
        [csv appendFormat:@"%@,%@,%@,%@,%.2f,%.4f,%.4f,%.4f,%.4f,%@,%@\n",
         [formatter stringFromDate:event.timestamp],
         event.cameraID,
         event.cameraName ?: @"",
         det.label,
         det.confidence,
         det.boundingBox.origin.x,
         det.boundingBox.origin.y,
         det.boundingBox.size.width,
         det.boundingBox.size.height,
         event.zoneName ?: @"",
         event.alertTriggered ? @"YES" : @"NO"];
    }

    // Write to file
    BOOL success = [csv writeToFile:filePath
                         atomically:YES
                           encoding:NSUTF8StringEncoding
                              error:error];

    if (success) {
        NSLog(@"[ObjectDetector] Exported %lu events to %@", (unsigned long)events.count, filePath);
    } else {
        NSLog(@"[ObjectDetector] Failed to export events: %@", error ? *error : @"Unknown error");
    }

    return success;
}

#pragma mark - RTSPMLXProcessorDelegate

- (void)mlxProcessor:(RTSPMLXProcessor *)processor didDetectObjects:(NSArray<RTSPDetection *> *)detections forCamera:(NSString *)cameraID {
    // This is handled in processFrame completion
}

- (void)mlxProcessor:(RTSPMLXProcessor *)processor didUpdatePerformance:(NSDictionary *)metrics {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(objectDetector:didUpdateStatistics:)]) {
            [self.delegate objectDetector:self didUpdateStatistics:metrics];
        }
    });
}

@end
