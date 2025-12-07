//
//  RTSPMLXProcessor.m
//  RTSP Rotator
//
//  Core MLX integration for machine learning processing
//

#import "RTSPMLXProcessor.h"
#import <CoreML/CoreML.h>
#import <Vision/Vision.h>
#import <Accelerate/Accelerate.h>
#import <sys/sysctl.h>

@implementation RTSPDetection

- (instancetype)initWithLabel:(NSString *)label confidence:(float)confidence boundingBox:(CGRect)box {
    self = [super init];
    if (self) {
        _label = [label copy];
        _confidence = confidence;
        _boundingBox = box;
        _timestamp = [NSDate date];
        _trackingID = [[NSUUID UUID] UUIDString];
    }
    return self;
}

- (CGRect)boundingBoxForImageSize:(CGSize)imageSize {
    return CGRectMake(
        self.boundingBox.origin.x * imageSize.width,
        self.boundingBox.origin.y * imageSize.height,
        self.boundingBox.size.width * imageSize.width,
        self.boundingBox.size.height * imageSize.height
    );
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<RTSPDetection: %@ (%.2f%%) @ %.2f,%.2f %.2fx%.2f>",
            self.label, self.confidence * 100,
            self.boundingBox.origin.x, self.boundingBox.origin.y,
            self.boundingBox.size.width, self.boundingBox.size.height];
}

@end

@implementation RTSPMLXConfiguration

+ (instancetype)defaultConfiguration {
    RTSPMLXConfiguration *config = [[RTSPMLXConfiguration alloc] init];
    config.useGPU = YES;
    config.maxConcurrentStreams = 4;
    config.confidenceThreshold = 0.5;
    config.iouThreshold = 0.45;
    config.inferenceInterval = 3; // Process every 3rd frame for performance
    config.enabledClasses = nil; // All classes enabled
    return config;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<RTSPMLXConfiguration: GPU=%@ streams=%ld conf=%.2f iou=%.2f interval=%ld>",
            self.useGPU ? @"YES" : @"NO",
            (long)self.maxConcurrentStreams,
            self.confidenceThreshold,
            self.iouThreshold,
            (long)self.inferenceInterval];
}

@end

@interface RTSPMLXProcessor ()

@property (nonatomic, strong) MLModel *model;
@property (nonatomic, strong) VNCoreMLModel *visionModel;
@property (nonatomic, strong) dispatch_queue_t processingQueue;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *cameraFrameCounts;
@property (nonatomic, assign) NSInteger framesProcessed;
@property (nonatomic, assign) NSInteger detectionsCount;
@property (nonatomic, assign) double totalInferenceTime;
@property (nonatomic, assign) NSInteger inferenceCount;
@property (nonatomic, strong) NSMutableSet<NSString *> *activeCameras;
@property (nonatomic, strong) NSDate *startTime;

@end

@implementation RTSPMLXProcessor

+ (instancetype)sharedProcessor {
    static RTSPMLXProcessor *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RTSPMLXProcessor alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _configuration = [RTSPMLXConfiguration defaultConfiguration];
        _processingQueue = dispatch_queue_create("com.rtsp.mlx.processing", DISPATCH_QUEUE_CONCURRENT);
        _cameraFrameCounts = [NSMutableDictionary dictionary];
        _activeCameras = [NSMutableSet set];
        _startTime = [NSDate date];
        _framesProcessed = 0;
        _detectionsCount = 0;
        _totalInferenceTime = 0.0;
        _inferenceCount = 0;

        NSLog(@"[MLX] Initialized MLX Processor with config: %@", _configuration);
    }
    return self;
}

- (BOOL)loadModel:(NSString *)modelPath error:(NSError **)error {
    NSLog(@"[MLX] Loading model from: %@", modelPath);

    // Check if file exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:modelPath]) {
        NSLog(@"[MLX] Model file not found at path: %@", modelPath);
        if (error) {
            *error = [NSError errorWithDomain:@"RTSPMLXProcessor"
                                        code:404
                                    userInfo:@{NSLocalizedDescriptionKey: @"Model file not found"}];
        }
        return NO;
    }

    // Load CoreML model
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];

    @try {
        MLModelConfiguration *config = [[MLModelConfiguration alloc] init];
        if (self.configuration.useGPU) {
            config.computeUnits = MLComputeUnitsAll; // Use GPU + Neural Engine
        } else {
            config.computeUnits = MLComputeUnitsCPUOnly;
        }

        self.model = [MLModel modelWithContentsOfURL:modelURL configuration:config error:error];

        if (!self.model) {
            NSLog(@"[MLX] Failed to load CoreML model: %@", error ? *error : @"Unknown error");
            return NO;
        }

        // Create Vision model wrapper
        self.visionModel = [VNCoreMLModel modelForMLModel:self.model error:error];

        if (!self.visionModel) {
            NSLog(@"[MLX] Failed to create Vision model: %@", error ? *error : @"Unknown error");
            return NO;
        }

        NSLog(@"[MLX] Model loaded successfully: %@", self.model.modelDescription);
        return YES;

    } @catch (NSException *exception) {
        NSLog(@"[MLX] Exception loading model: %@", exception);
        if (error) {
            *error = [NSError errorWithDomain:@"RTSPMLXProcessor"
                                        code:500
                                    userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"Unknown exception"}];
        }
        return NO;
    }
}

- (void)processFrame:(CVPixelBufferRef)pixelBuffer
           forCamera:(NSString *)cameraID
          completion:(void (^)(NSArray<RTSPDetection *> * _Nullable, NSError * _Nullable))completion {

    if (!self.visionModel) {
        NSError *error = [NSError errorWithDomain:@"RTSPMLXProcessor"
                                            code:400
                                        userInfo:@{NSLocalizedDescriptionKey: @"Model not loaded"}];
        if (completion) completion(nil, error);
        return;
    }

    // Check frame interval
    NSNumber *frameCount = self.cameraFrameCounts[cameraID] ?: @0;
    NSInteger count = [frameCount integerValue];
    self.cameraFrameCounts[cameraID] = @(count + 1);

    if (count % self.configuration.inferenceInterval != 0) {
        // Skip this frame
        if (completion) completion(@[], nil);
        return;
    }

    [self.activeCameras addObject:cameraID];

    dispatch_async(self.processingQueue, ^{
        NSDate *startTime = [NSDate date];

        // Create Vision request
        VNCoreMLRequest *request = [[VNCoreMLRequest alloc] initWithModel:self.visionModel
                                                        completionHandler:^(VNRequest *request, NSError *error) {
            if (error) {
                NSLog(@"[MLX] Vision request error: %@", error);
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(nil, error);
                    });
                }
                return;
            }

            // Process results
            NSArray<RTSPDetection *> *detections = [self processVisionResults:request.results];

            // Update statistics
            NSTimeInterval inferenceTime = [[NSDate date] timeIntervalSinceDate:startTime] * 1000; // ms
            self.totalInferenceTime += inferenceTime;
            self.inferenceCount++;
            self.framesProcessed++;
            self.detectionsCount += detections.count;

            NSLog(@"[MLX] Camera %@: Found %lu objects in %.1fms",
                  cameraID, (unsigned long)detections.count, inferenceTime);

            // Notify delegate
            if ([self.delegate respondsToSelector:@selector(mlxProcessor:didDetectObjects:forCamera:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate mlxProcessor:self didDetectObjects:detections forCamera:cameraID];
                });
            }

            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(detections, nil);
                });
            }
        }];

        // Configure request
        request.imageCropAndScaleOption = VNImageCropAndScaleOptionScaleFit;

        // Create request handler
        VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:pixelBuffer
                                                                                      options:@{}];

        // Perform request
        NSError *error = nil;
        if (![handler performRequests:@[request] error:&error]) {
            NSLog(@"[MLX] Failed to perform Vision request: %@", error);
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            }
        }
    });
}

- (void)processImage:(CGImageRef)image completion:(void (^)(NSArray<RTSPDetection *> * _Nullable, NSError * _Nullable))completion {
    if (!self.visionModel) {
        NSError *error = [NSError errorWithDomain:@"RTSPMLXProcessor"
                                            code:400
                                        userInfo:@{NSLocalizedDescriptionKey: @"Model not loaded"}];
        if (completion) completion(nil, error);
        return;
    }

    dispatch_async(self.processingQueue, ^{
        NSDate *startTime = [NSDate date];

        VNCoreMLRequest *request = [[VNCoreMLRequest alloc] initWithModel:self.visionModel
                                                        completionHandler:^(VNRequest *request, NSError *error) {
            if (error) {
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(nil, error);
                    });
                }
                return;
            }

            NSArray<RTSPDetection *> *detections = [self processVisionResults:request.results];

            NSTimeInterval inferenceTime = [[NSDate date] timeIntervalSinceDate:startTime] * 1000;
            NSLog(@"[MLX] Image: Found %lu objects in %.1fms",
                  (unsigned long)detections.count, inferenceTime);

            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(detections, nil);
                });
            }
        }];

        request.imageCropAndScaleOption = VNImageCropAndScaleOptionScaleFit;

        VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:image options:@{}];

        NSError *error = nil;
        if (![handler performRequests:@[request] error:&error]) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            }
        }
    });
}

- (NSArray<RTSPDetection *> *)processVisionResults:(NSArray<VNObservation *> *)results {
    NSMutableArray<RTSPDetection *> *detections = [NSMutableArray array];

    for (VNObservation *observation in results) {
        if ([observation isKindOfClass:[VNRecognizedObjectObservation class]]) {
            VNRecognizedObjectObservation *objectObservation = (VNRecognizedObjectObservation *)observation;

            // Get top classification
            VNClassificationObservation *topLabel = objectObservation.labels.firstObject;
            if (!topLabel) continue;

            // Filter by confidence
            if (topLabel.confidence < self.configuration.confidenceThreshold) {
                continue;
            }

            // Filter by enabled classes
            if (self.configuration.enabledClasses &&
                ![self.configuration.enabledClasses containsObject:topLabel.identifier]) {
                continue;
            }

            // Convert Vision coordinates (origin bottom-left) to normalized top-left
            CGRect box = objectObservation.boundingBox;
            CGRect normalizedBox = CGRectMake(
                box.origin.x,
                1.0 - box.origin.y - box.size.height, // Flip Y coordinate
                box.size.width,
                box.size.height
            );

            RTSPDetection *detection = [[RTSPDetection alloc] initWithLabel:topLabel.identifier
                                                                  confidence:topLabel.confidence
                                                                 boundingBox:normalizedBox];
            [detections addObject:detection];
        }
    }

    return [detections copy];
}

- (void)stopProcessingForCamera:(NSString *)cameraID {
    [self.activeCameras removeObject:cameraID];
    [self.cameraFrameCounts removeObjectForKey:cameraID];
    NSLog(@"[MLX] Stopped processing for camera: %@", cameraID);
}

- (void)stopAllProcessing {
    [self.activeCameras removeAllObjects];
    [self.cameraFrameCounts removeAllObjects];
    NSLog(@"[MLX] Stopped all processing");
}

- (void)resetStatistics {
    self.framesProcessed = 0;
    self.detectionsCount = 0;
    self.totalInferenceTime = 0.0;
    self.inferenceCount = 0;
    self.startTime = [NSDate date];
    NSLog(@"[MLX] Statistics reset");
}

- (BOOL)isProcessing {
    return self.activeCameras.count > 0;
}

- (double)averageInferenceTime {
    if (self.inferenceCount == 0) return 0.0;
    return self.totalInferenceTime / self.inferenceCount;
}

- (NSDictionary *)performanceMetrics {
    NSTimeInterval uptime = [[NSDate date] timeIntervalSinceDate:self.startTime];

    return @{
        @"framesProcessed": @(self.framesProcessed),
        @"detectionsCount": @(self.detectionsCount),
        @"averageInferenceTime": @(self.averageInferenceTime),
        @"inferenceCount": @(self.inferenceCount),
        @"activeCameras": @(self.activeCameras.count),
        @"uptimeSeconds": @(uptime),
        @"framesPerSecond": @(uptime > 0 ? self.framesProcessed / uptime : 0.0),
        @"detectionsPerFrame": @(self.framesProcessed > 0 ? (double)self.detectionsCount / self.framesProcessed : 0.0)
    };
}

+ (BOOL)isMLXAvailable {
    // Check for CoreML availability
    if (@available(macOS 11.0, *)) {
        return YES;
    }
    return NO;
}

+ (RTSPMLXConfiguration *)recommendedConfiguration {
    RTSPMLXConfiguration *config = [RTSPMLXConfiguration defaultConfiguration];

    // Detect Apple Silicon
    BOOL isAppleSilicon = NO;
    size_t size;
    cpu_type_t type;
    size = sizeof(type);
    if (sysctlbyname("hw.cputype", &type, &size, NULL, 0) == 0) {
        isAppleSilicon = (type == CPU_TYPE_ARM64);
    }

    if (isAppleSilicon) {
        // Apple Silicon - can handle more streams
        config.maxConcurrentStreams = 6;
        config.inferenceInterval = 2; // Process more frequently
        NSLog(@"[MLX] Detected Apple Silicon - using optimized configuration");
    } else {
        // Intel - more conservative
        config.maxConcurrentStreams = 3;
        config.inferenceInterval = 5;
        NSLog(@"[MLX] Detected Intel processor - using conservative configuration");
    }

    return config;
}

- (void)dealloc {
    [self stopAllProcessing];
}

@end
