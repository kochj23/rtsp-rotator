//
//  RTSPAnnotationOverlay.h
//  RTSP Rotator
//
//  Feed annotations and overlays
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTSPAnnotation : NSObject
@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) CGPoint position;
@property (nonatomic, strong) NSColor *color;
@property (nonatomic, assign) CGFloat fontSize;
@end

@interface RTSPAnnotationOverlay : NSView

@property (nonatomic, strong) NSMutableArray<RTSPAnnotation *> *annotations;
@property (nonatomic, assign) BOOL showTimestamp;
@property (nonatomic, assign) BOOL showFeedName;
@property (nonatomic, strong, nullable) NSString *feedName;

- (void)addAnnotation:(RTSPAnnotation *)annotation;
- (void)removeAnnotation:(RTSPAnnotation *)annotation;
- (void)clearAnnotations;

@end

NS_ASSUME_NONNULL_END
