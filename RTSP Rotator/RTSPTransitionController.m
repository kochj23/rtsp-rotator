//
//  RTSPTransitionController.m
//  RTSP Rotator
//

#import "RTSPTransitionController.h"

@implementation RTSPTransitionController

- (instancetype)init {
    self = [super init];
    if (self) {
        _duration = 0.5;
        _transitionType = RTSPTransitionTypeFade;
        _timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    }
    return self;
}

- (void)transitionFromLayer:(CALayer *)fromLayer toLayer:(CALayer *)toLayer completion:(void (^)(void))completion {
    if (self.transitionType == RTSPTransitionTypeNone) {
        // Instant transition
        fromLayer.hidden = YES;
        toLayer.hidden = NO;
        if (completion) completion();
        return;
    }

    // Ensure toLayer is positioned correctly
    toLayer.frame = fromLayer.frame;

    // Perform the transition based on type
    switch (self.transitionType) {
        case RTSPTransitionTypeFade:
            [self performFadeTransitionFrom:fromLayer to:toLayer completion:completion];
            break;
        case RTSPTransitionTypeSlideLeft:
            [self performSlideTransitionFrom:fromLayer to:toLayer direction:CGPointMake(-1, 0) completion:completion];
            break;
        case RTSPTransitionTypeSlideRight:
            [self performSlideTransitionFrom:fromLayer to:toLayer direction:CGPointMake(1, 0) completion:completion];
            break;
        case RTSPTransitionTypeSlideUp:
            [self performSlideTransitionFrom:fromLayer to:toLayer direction:CGPointMake(0, 1) completion:completion];
            break;
        case RTSPTransitionTypeSlideDown:
            [self performSlideTransitionFrom:fromLayer to:toLayer direction:CGPointMake(0, -1) completion:completion];
            break;
        case RTSPTransitionTypeZoomIn:
            [self performZoomTransitionFrom:fromLayer to:toLayer zoomIn:YES completion:completion];
            break;
        case RTSPTransitionTypeZoomOut:
            [self performZoomTransitionFrom:fromLayer to:toLayer zoomIn:NO completion:completion];
            break;
        case RTSPTransitionTypeDissolve:
            [self performDissolveTransitionFrom:fromLayer to:toLayer completion:completion];
            break;
        case RTSPTransitionTypePush:
            [self performPushTransitionFrom:fromLayer to:toLayer completion:completion];
            break;
        case RTSPTransitionTypeCube:
            [self performCubeTransitionFrom:fromLayer to:toLayer completion:completion];
            break;
        case RTSPTransitionTypeFlip:
            [self performFlipTransitionFrom:fromLayer to:toLayer completion:completion];
            break;
        default:
            [self performFadeTransitionFrom:fromLayer to:toLayer completion:completion];
            break;
    }
}

- (void)performFadeTransitionFrom:(CALayer *)fromLayer to:(CALayer *)toLayer completion:(void (^)(void))completion {
    toLayer.opacity = 0.0;
    toLayer.hidden = NO;

    [CATransaction begin];
    [CATransaction setAnimationDuration:self.duration];
    [CATransaction setAnimationTimingFunction:self.timingFunction];
    [CATransaction setCompletionBlock:^{
        fromLayer.hidden = YES;
        fromLayer.opacity = 1.0;
        if (completion) completion();
    }];

    CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeOut.fromValue = @(1.0);
    fadeOut.toValue = @(0.0);
    [fromLayer addAnimation:fadeOut forKey:@"fadeOut"];

    CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeIn.fromValue = @(0.0);
    fadeIn.toValue = @(1.0);
    toLayer.opacity = 1.0;
    [toLayer addAnimation:fadeIn forKey:@"fadeIn"];

    [CATransaction commit];
}

- (void)performSlideTransitionFrom:(CALayer *)fromLayer to:(CALayer *)toLayer direction:(CGPoint)direction completion:(void (^)(void))completion {
    CGRect bounds = fromLayer.bounds;
    CGPoint fromEndPosition = CGPointMake(fromLayer.position.x - direction.x * bounds.size.width,
                                          fromLayer.position.y - direction.y * bounds.size.height);
    CGPoint toStartPosition = CGPointMake(toLayer.position.x + direction.x * bounds.size.width,
                                          toLayer.position.y + direction.y * bounds.size.height);

    toLayer.position = toStartPosition;
    toLayer.hidden = NO;

    [CATransaction begin];
    [CATransaction setAnimationDuration:self.duration];
    [CATransaction setAnimationTimingFunction:self.timingFunction];
    [CATransaction setCompletionBlock:^{
        fromLayer.hidden = YES;
        fromLayer.position = CGPointMake(bounds.size.width / 2, bounds.size.height / 2);
        if (completion) completion();
    }];

    CABasicAnimation *slideOut = [CABasicAnimation animationWithKeyPath:@"position"];
    slideOut.toValue = [NSValue valueWithPoint:NSPointFromCGPoint(fromEndPosition)];
    [fromLayer addAnimation:slideOut forKey:@"slideOut"];

    CABasicAnimation *slideIn = [CABasicAnimation animationWithKeyPath:@"position"];
    slideIn.fromValue = [NSValue valueWithPoint:NSPointFromCGPoint(toStartPosition)];
    slideIn.toValue = [NSValue valueWithPoint:NSPointFromCGPoint(CGPointMake(bounds.size.width / 2, bounds.size.height / 2))];
    toLayer.position = CGPointMake(bounds.size.width / 2, bounds.size.height / 2);
    [toLayer addAnimation:slideIn forKey:@"slideIn"];

    [CATransaction commit];
}

- (void)performZoomTransitionFrom:(CALayer *)fromLayer to:(CALayer *)toLayer zoomIn:(BOOL)zoomIn completion:(void (^)(void))completion {
    CGFloat startScale = zoomIn ? 0.0 : 1.5;
    CGFloat endScale = zoomIn ? 1.5 : 0.0;

    toLayer.transform = CATransform3DMakeScale(startScale, startScale, 1.0);
    toLayer.opacity = 0.0;
    toLayer.hidden = NO;

    [CATransaction begin];
    [CATransaction setAnimationDuration:self.duration];
    [CATransaction setAnimationTimingFunction:self.timingFunction];
    [CATransaction setCompletionBlock:^{
        fromLayer.hidden = YES;
        fromLayer.transform = CATransform3DIdentity;
        fromLayer.opacity = 1.0;
        if (completion) completion();
    }];

    CABasicAnimation *scaleOut = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleOut.toValue = @(endScale);
    CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeOut.toValue = @(0.0);

    CAAnimationGroup *groupOut = [CAAnimationGroup animation];
    groupOut.animations = @[scaleOut, fadeOut];
    [fromLayer addAnimation:groupOut forKey:@"zoomOut"];

    CABasicAnimation *scaleIn = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleIn.fromValue = @(startScale);
    scaleIn.toValue = @(1.0);
    CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeIn.fromValue = @(0.0);
    fadeIn.toValue = @(1.0);

    CAAnimationGroup *groupIn = [CAAnimationGroup animation];
    groupIn.animations = @[scaleIn, fadeIn];
    toLayer.transform = CATransform3DIdentity;
    toLayer.opacity = 1.0;
    [toLayer addAnimation:groupIn forKey:@"zoomIn"];

    [CATransaction commit];
}

- (void)performDissolveTransitionFrom:(CALayer *)fromLayer to:(CALayer *)toLayer completion:(void (^)(void))completion {
    // Similar to fade but with different timing
    CAMediaTimingFunction *dissolveTimingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

    toLayer.opacity = 0.0;
    toLayer.hidden = NO;

    [CATransaction begin];
    [CATransaction setAnimationDuration:self.duration];
    [CATransaction setAnimationTimingFunction:dissolveTimingFunction];
    [CATransaction setCompletionBlock:^{
        fromLayer.hidden = YES;
        fromLayer.opacity = 1.0;
        if (completion) completion();
    }];

    CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeOut.toValue = @(0.0);
    [fromLayer addAnimation:fadeOut forKey:@"dissolveOut"];

    CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeIn.toValue = @(1.0);
    toLayer.opacity = 1.0;
    [toLayer addAnimation:fadeIn forKey:@"dissolveIn"];

    [CATransaction commit];
}

- (void)performPushTransitionFrom:(CALayer *)fromLayer to:(CALayer *)toLayer completion:(void (^)(void))completion {
    CATransition *transition = [CATransition animation];
    transition.duration = self.duration;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    transition.timingFunction = self.timingFunction;

    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        fromLayer.hidden = YES;
        if (completion) completion();
    }];

    toLayer.hidden = NO;
    [fromLayer.superlayer addAnimation:transition forKey:@"pushTransition"];

    [CATransaction commit];
}

- (void)performCubeTransitionFrom:(CALayer *)fromLayer to:(CALayer *)toLayer completion:(void (^)(void))completion {
    // 3D cube rotation effect
    CATransform3D perspective = CATransform3DIdentity;
    perspective.m34 = -1.0 / 1000.0;

    toLayer.hidden = NO;
    toLayer.transform = CATransform3DConcat(perspective, CATransform3DMakeRotation(M_PI_2, 0, 1, 0));

    [CATransaction begin];
    [CATransaction setAnimationDuration:self.duration];
    [CATransaction setAnimationTimingFunction:self.timingFunction];
    [CATransaction setCompletionBlock:^{
        fromLayer.hidden = YES;
        fromLayer.transform = CATransform3DIdentity;
        if (completion) completion();
    }];

    CABasicAnimation *rotateOut = [CABasicAnimation animationWithKeyPath:@"transform"];
    rotateOut.toValue = [NSValue valueWithCATransform3D:CATransform3DConcat(perspective, CATransform3DMakeRotation(-M_PI_2, 0, 1, 0))];
    [fromLayer addAnimation:rotateOut forKey:@"cubeOut"];

    CABasicAnimation *rotateIn = [CABasicAnimation animationWithKeyPath:@"transform"];
    rotateIn.fromValue = [NSValue valueWithCATransform3D:CATransform3DConcat(perspective, CATransform3DMakeRotation(M_PI_2, 0, 1, 0))];
    rotateIn.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    toLayer.transform = CATransform3DIdentity;
    [toLayer addAnimation:rotateIn forKey:@"cubeIn"];

    [CATransaction commit];
}

- (void)performFlipTransitionFrom:(CALayer *)fromLayer to:(CALayer *)toLayer completion:(void (^)(void))completion {
    CATransform3D perspective = CATransform3DIdentity;
    perspective.m34 = -1.0 / 1000.0;

    toLayer.hidden = NO;
    toLayer.transform = CATransform3DConcat(perspective, CATransform3DMakeRotation(M_PI, 1, 0, 0));

    [CATransaction begin];
    [CATransaction setAnimationDuration:self.duration];
    [CATransaction setAnimationTimingFunction:self.timingFunction];
    [CATransaction setCompletionBlock:^{
        fromLayer.hidden = YES;
        fromLayer.transform = CATransform3DIdentity;
        if (completion) completion();
    }];

    CABasicAnimation *flipOut = [CABasicAnimation animationWithKeyPath:@"transform"];
    flipOut.toValue = [NSValue valueWithCATransform3D:CATransform3DConcat(perspective, CATransform3DMakeRotation(M_PI, 1, 0, 0))];
    [fromLayer addAnimation:flipOut forKey:@"flipOut"];

    CABasicAnimation *flipIn = [CABasicAnimation animationWithKeyPath:@"transform"];
    flipIn.fromValue = [NSValue valueWithCATransform3D:CATransform3DConcat(perspective, CATransform3DMakeRotation(M_PI, 1, 0, 0))];
    flipIn.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    toLayer.transform = CATransform3DIdentity;
    [toLayer addAnimation:flipIn forKey:@"flipIn"];

    [CATransaction commit];
}

+ (NSString *)nameForTransitionType:(RTSPTransitionType)type {
    switch (type) {
        case RTSPTransitionTypeNone: return @"None";
        case RTSPTransitionTypeFade: return @"Fade";
        case RTSPTransitionTypeSlideLeft: return @"Slide Left";
        case RTSPTransitionTypeSlideRight: return @"Slide Right";
        case RTSPTransitionTypeSlideUp: return @"Slide Up";
        case RTSPTransitionTypeSlideDown: return @"Slide Down";
        case RTSPTransitionTypeZoomIn: return @"Zoom In";
        case RTSPTransitionTypeZoomOut: return @"Zoom Out";
        case RTSPTransitionTypeDissolve: return @"Dissolve";
        case RTSPTransitionTypePush: return @"Push";
        case RTSPTransitionTypeCube: return @"Cube";
        case RTSPTransitionTypeFlip: return @"Flip";
    }
}

+ (NSArray<NSNumber *> *)allTransitionTypes {
    return @[@(RTSPTransitionTypeNone),
             @(RTSPTransitionTypeFade),
             @(RTSPTransitionTypeSlideLeft),
             @(RTSPTransitionTypeSlideRight),
             @(RTSPTransitionTypeSlideUp),
             @(RTSPTransitionTypeSlideDown),
             @(RTSPTransitionTypeZoomIn),
             @(RTSPTransitionTypeZoomOut),
             @(RTSPTransitionTypeDissolve),
             @(RTSPTransitionTypePush),
             @(RTSPTransitionTypeCube),
             @(RTSPTransitionTypeFlip)];
}

@end
