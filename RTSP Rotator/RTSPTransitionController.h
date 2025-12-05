//
//  RTSPTransitionController.h
//  RTSP Rotator
//
//  Custom transitions between feeds
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTSPTransitionType) {
    RTSPTransitionTypeNone,
    RTSPTransitionTypeFade,
    RTSPTransitionTypeSlideLeft,
    RTSPTransitionTypeSlideRight,
    RTSPTransitionTypeSlideUp,
    RTSPTransitionTypeSlideDown,
    RTSPTransitionTypeZoomIn,
    RTSPTransitionTypeZoomOut,
    RTSPTransitionTypeDissolve,
    RTSPTransitionTypePush,
    RTSPTransitionTypeCube,
    RTSPTransitionTypeFlip
};

/// Custom transition controller
@interface RTSPTransitionController : NSObject

/// Transition duration in seconds (default: 0.5, range: 0.1-2.0)
@property (nonatomic, assign) NSTimeInterval duration;

/// Transition type (default: Fade)
@property (nonatomic, assign) RTSPTransitionType transitionType;

/// Animation timing function (default: easeInOut)
@property (nonatomic, strong) CAMediaTimingFunction *timingFunction;

/// Perform transition between two layers
- (void)transitionFromLayer:(CALayer *)fromLayer toLayer:(CALayer *)toLayer completion:(nullable void (^)(void))completion;

/// Get display name for transition type
+ (NSString *)nameForTransitionType:(RTSPTransitionType)type;

/// Get all available transition types
+ (NSArray<NSNumber *> *)allTransitionTypes;

@end

NS_ASSUME_NONNULL_END
