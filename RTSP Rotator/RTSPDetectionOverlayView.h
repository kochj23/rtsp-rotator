//
//  RTSPDetectionOverlayView.h
//  RTSP Rotator
//
//  Visual overlay for displaying object detection results on video
//

#import <Cocoa/Cocoa.h>
#import "RTSPObjectDetector.h"

NS_ASSUME_NONNULL_BEGIN

/// Visual style for detection overlays
typedef NS_ENUM(NSInteger, RTSPDetectionOverlayStyle) {
    RTSPDetectionOverlayStyleDefault,      // Colored boxes with labels
    RTSPDetectionOverlayStyleMinimal,      // Thin boxes only
    RTSPDetectionOverlayStyleHighlight,    // Highlighted with glow
    RTSPDetectionOverlayStyleDebug         // Detailed debug info
};

/// Overlay view for displaying object detections on video
@interface RTSPDetectionOverlayView : NSView

/// Current detections to display
@property (nonatomic, strong) NSArray<RTSPDetection *> *detections;

/// Detection zones to visualize
@property (nonatomic, strong, nullable) NSArray<RTSPDetectionZone *> *zones;

/// Visual style
@property (nonatomic, assign) RTSPDetectionOverlayStyle style;

/// Show confidence scores
@property (nonatomic, assign) BOOL showConfidence;

/// Show labels
@property (nonatomic, assign) BOOL showLabels;

/// Show zones
@property (nonatomic, assign) BOOL showZones;

/// Animation enabled
@property (nonatomic, assign) BOOL animationEnabled;

/// Box line width
@property (nonatomic, assign) CGFloat lineWidth;

/// Font size for labels
@property (nonatomic, assign) CGFloat fontSize;

/**
 * Update detections with animation
 * @param detections New detections array
 */
- (void)updateDetections:(NSArray<RTSPDetection *> *)detections;

/**
 * Clear all detections
 */
- (void)clearDetections;

/**
 * Get color for object class
 * @param className Object class label
 * @return Color for that class
 */
+ (NSColor *)colorForClass:(NSString *)className;

@end

NS_ASSUME_NONNULL_END
