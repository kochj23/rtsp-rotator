//
//  RTSPObjectDetector.h
//  RTSP Rotator
//
//  High-level object detection manager for RTSP streams
//  Integrates MLX processing with camera feeds
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import "RTSPMLXProcessor.h"

NS_ASSUME_NONNULL_BEGIN

/// Object detection zone for filtering
@interface RTSPDetectionZone : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) CGRect normalizedRect;  // 0.0-1.0 coordinates
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, copy) NSArray<NSString *> *enabledClasses; // nil = all classes

- (instancetype)initWithName:(NSString *)name rect:(CGRect)rect;
- (BOOL)containsDetection:(RTSPDetection *)detection;

@end

/// Detection event for logging and alerts
@interface RTSPDetectionEvent : NSObject

@property (nonatomic, copy) NSString *cameraID;
@property (nonatomic, copy) NSString *cameraName;
@property (nonatomic, strong) RTSPDetection *detection;
@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, copy, nullable) NSString *zoneName;
@property (nonatomic, assign) BOOL alertTriggered;
@property (nonatomic, strong, nullable) NSImage *snapshot;

@end

@class RTSPObjectDetector;

/// Object detector delegate
@protocol RTSPObjectDetectorDelegate <NSObject>
@optional
- (void)objectDetector:(RTSPObjectDetector *)detector didDetectEvent:(RTSPDetectionEvent *)event;
- (void)objectDetector:(RTSPObjectDetector *)detector didUpdateStatistics:(NSDictionary *)stats;
@end

/// High-level object detection manager
@interface RTSPObjectDetector : NSObject

/// Shared instance
+ (instancetype)sharedDetector;

/// Delegate
@property (nonatomic, weak) id<RTSPObjectDetectorDelegate> delegate;

/// Enable/disable detection globally
@property (nonatomic, assign) BOOL detectionEnabled;

/// MLX processor
@property (nonatomic, readonly) RTSPMLXProcessor *mlxProcessor;

/**
 * Initialize with model path
 * @param modelPath Path to CoreML model file
 * @param error Error if initialization fails
 * @return YES if successful
 */
- (BOOL)initializeWithModel:(NSString *)modelPath error:(NSError **)error;

/**
 * Enable detection for camera
 * @param cameraID Camera identifier
 * @param zones Optional detection zones (nil = entire frame)
 */
- (void)enableDetectionForCamera:(NSString *)cameraID zones:(NSArray<RTSPDetectionZone *> * _Nullable)zones;

/**
 * Disable detection for camera
 * @param cameraID Camera identifier
 */
- (void)disableDetectionForCamera:(NSString *)cameraID;

/**
 * Process frame from camera
 * @param pixelBuffer CVPixelBuffer containing frame
 * @param cameraID Camera identifier
 * @param cameraName Human-readable camera name
 */
- (void)processFrame:(CVPixelBufferRef)pixelBuffer
         fromCamera:(NSString *)cameraID
               name:(NSString *)cameraName;

/**
 * Get detection zones for camera
 * @param cameraID Camera identifier
 * @return Array of zones or nil
 */
- (NSArray<RTSPDetectionZone *> * _Nullable)zonesForCamera:(NSString *)cameraID;

/**
 * Set detection zones for camera
 * @param zones Array of detection zones
 * @param cameraID Camera identifier
 */
- (void)setZones:(NSArray<RTSPDetectionZone *> *)zones forCamera:(NSString *)cameraID;

/**
 * Get recent detection events
 * @param limit Maximum number of events
 * @return Array of recent events
 */
- (NSArray<RTSPDetectionEvent *> *)recentEvents:(NSInteger)limit;

/**
 * Get detection statistics
 * @return Statistics dictionary
 */
- (NSDictionary *)statistics;

/**
 * Clear detection history
 */
- (void)clearHistory;

/**
 * Export detection events to CSV
 * @param filePath Output file path
 * @param error Error if export fails
 * @return YES if successful
 */
- (BOOL)exportEventsToCSV:(NSString *)filePath error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
