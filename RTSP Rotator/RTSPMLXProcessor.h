//
//  RTSPMLXProcessor.h
//  RTSP Rotator
//
//  Core MLX integration for machine learning processing
//  Handles model loading, inference, and GPU acceleration
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

/// Detection result from ML model
@interface RTSPDetection : NSObject

@property (nonatomic, copy) NSString *label;           // Object label (e.g., "person", "car")
@property (nonatomic, assign) float confidence;         // Confidence score (0.0 - 1.0)
@property (nonatomic, assign) CGRect boundingBox;      // Normalized coordinates (0.0 - 1.0)
@property (nonatomic, copy) NSString *trackingID;      // Optional tracking ID
@property (nonatomic, strong) NSDate *timestamp;       // Detection timestamp

- (instancetype)initWithLabel:(NSString *)label
                   confidence:(float)confidence
                  boundingBox:(CGRect)box;

/// Convert normalized box to pixel coordinates
- (CGRect)boundingBoxForImageSize:(CGSize)imageSize;

@end

/// MLX Processor configuration
@interface RTSPMLXConfiguration : NSObject

@property (nonatomic, assign) BOOL useGPU;                      // Enable GPU acceleration (default: YES)
@property (nonatomic, assign) NSInteger maxConcurrentStreams;  // Max simultaneous streams (default: 4)
@property (nonatomic, assign) float confidenceThreshold;       // Minimum confidence (default: 0.5)
@property (nonatomic, assign) float iouThreshold;              // Non-max suppression threshold (default: 0.45)
@property (nonatomic, assign) NSInteger inferenceInterval;     // Process every N frames (default: 3)
@property (nonatomic, copy) NSArray<NSString *> *enabledClasses; // Filter by classes (nil = all)

+ (instancetype)defaultConfiguration;

@end

@class RTSPMLXProcessor;

/// MLX Processor delegate
@protocol RTSPMLXProcessorDelegate <NSObject>
@optional
- (void)mlxProcessor:(RTSPMLXProcessor *)processor didDetectObjects:(NSArray<RTSPDetection *> *)detections forCamera:(NSString *)cameraID;
- (void)mlxProcessor:(RTSPMLXProcessor *)processor didFailWithError:(NSError *)error;
- (void)mlxProcessor:(RTSPMLXProcessor *)processor didUpdatePerformance:(NSDictionary *)metrics;
@end

/// Core MLX processor for machine learning inference
@interface RTSPMLXProcessor : NSObject

/// Shared instance
+ (instancetype)sharedProcessor;

/// Delegate
@property (nonatomic, weak) id<RTSPMLXProcessorDelegate> delegate;

/// Configuration
@property (nonatomic, strong) RTSPMLXConfiguration *configuration;

/// Processing statistics
@property (nonatomic, readonly) NSInteger framesProcessed;
@property (nonatomic, readonly) NSInteger detectionsCount;
@property (nonatomic, readonly) double averageInferenceTime; // milliseconds
@property (nonatomic, readonly) BOOL isProcessing;

/**
 * Load ML model from file
 * @param modelPath Path to .mlmodel or .mlpackage file
 * @param error Error if loading fails
 * @return YES if model loaded successfully
 */
- (BOOL)loadModel:(NSString *)modelPath error:(NSError **)error;

/**
 * Process video frame and detect objects
 * @param pixelBuffer CVPixelBuffer containing frame data
 * @param cameraID Camera identifier for tracking
 * @param completion Completion handler with detections array
 */
- (void)processFrame:(CVPixelBufferRef)pixelBuffer
           forCamera:(NSString *)cameraID
          completion:(void (^)(NSArray<RTSPDetection *> * _Nullable detections, NSError * _Nullable error))completion;

/**
 * Process image and detect objects
 * @param image CGImageRef to process
 * @param completion Completion handler with detections array
 */
- (void)processImage:(CGImageRef)image
          completion:(void (^)(NSArray<RTSPDetection *> * _Nullable detections, NSError * _Nullable error))completion;

/**
 * Stop processing for specific camera
 * @param cameraID Camera identifier
 */
- (void)stopProcessingForCamera:(NSString *)cameraID;

/**
 * Stop all processing
 */
- (void)stopAllProcessing;

/**
 * Reset statistics
 */
- (void)resetStatistics;

/**
 * Get performance metrics
 * @return Dictionary with performance data
 */
- (NSDictionary *)performanceMetrics;

/**
 * Check if MLX is available on this system
 * @return YES if MLX is supported
 */
+ (BOOL)isMLXAvailable;

/**
 * Get recommended configuration for current hardware
 * @return Optimized configuration
 */
+ (RTSPMLXConfiguration *)recommendedConfiguration;

@end

NS_ASSUME_NONNULL_END
