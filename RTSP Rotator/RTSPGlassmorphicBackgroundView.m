//
//  RTSPGlassmorphicBackgroundView.m
//  Stream Rotator
//
//  Modern glassmorphic background with animated floating blobs
//  Inspired by iOS design and modern dashboard aesthetics
//
//  Created by Jordan Koch on 1/17/2026.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

#import "RTSPGlassmorphicBackgroundView.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

@interface RTSPGlassmorphicBackgroundView ()
@property (nonatomic, strong) NSArray<CAShapeLayer *> *blobLayers;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@end

@implementation RTSPGlassmorphicBackgroundView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setupLayers];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupLayers];
}

- (void)setupLayers {
    // Enable layer backing
    self.wantsLayer = YES;

    // Create base gradient layer (dark blue gradient - CleanMyMac style)
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.frame = self.bounds;

    // Dark navy gradient colors
    NSColor *gradientStart = [NSColor colorWithRed:0.08 green:0.12 blue:0.22 alpha:1.0];
    NSColor *gradientMid = [NSColor colorWithRed:0.10 green:0.15 blue:0.28 alpha:1.0];
    NSColor *gradientEnd = [NSColor colorWithRed:0.12 green:0.18 blue:0.32 alpha:1.0];

    self.gradientLayer.colors = @[
        (__bridge id)gradientStart.CGColor,
        (__bridge id)gradientMid.CGColor,
        (__bridge id)gradientEnd.CGColor
    ];

    self.gradientLayer.startPoint = CGPointMake(0, 0);
    self.gradientLayer.endPoint = CGPointMake(1, 1);

    [self.layer addSublayer:self.gradientLayer];

    // Create floating blob layers
    NSMutableArray *blobs = [NSMutableArray array];

    // Blob 1: Cyan
    CAShapeLayer *blob1 = [self createBlobWithColor:[NSColor colorWithRed:0.2 green:0.7 blue:0.9 alpha:0.3]
                                              size:400
                                          position:CGPointMake(-100, -200)];
    [blobs addObject:blob1];
    [self.layer addSublayer:blob1];

    // Blob 2: Purple
    CAShapeLayer *blob2 = [self createBlobWithColor:[NSColor colorWithRed:0.5 green:0.3 blue:0.8 alpha:0.3]
                                              size:350
                                          position:CGPointMake(150, -150)];
    [blobs addObject:blob2];
    [self.layer addSublayer:blob2];

    // Blob 3: Pink
    CAShapeLayer *blob3 = [self createBlobWithColor:[NSColor colorWithRed:0.9 green:0.3 blue:0.6 alpha:0.3]
                                              size:450
                                          position:CGPointMake(100, 300)];
    [blobs addObject:blob3];
    [self.layer addSublayer:blob3];

    // Blob 4: Orange
    CAShapeLayer *blob4 = [self createBlobWithColor:[NSColor colorWithRed:0.9 green:0.5 blue:0.2 alpha:0.3]
                                              size:300
                                          position:CGPointMake(-200, 250)];
    [blobs addObject:blob4];
    [self.layer addSublayer:blob4];

    // Blob 5: Cyan (lighter)
    CAShapeLayer *blob5 = [self createBlobWithColor:[NSColor colorWithRed:0.2 green:0.7 blue:0.9 alpha:0.2]
                                              size:250
                                          position:CGPointMake(200, 100)];
    [blobs addObject:blob5];
    [self.layer addSublayer:blob5];

    self.blobLayers = [blobs copy];
}

- (CAShapeLayer *)createBlobWithColor:(NSColor *)color size:(CGFloat)size position:(CGPoint)position {
    CAShapeLayer *blob = [CAShapeLayer layer];

    // Create circular path
    CGRect rect = CGRectMake(0, 0, size, size);
    NSBezierPath *bezierPath = [NSBezierPath bezierPathWithOvalInRect:rect];
    blob.path = [self convertNSBezierPathToCGPath:bezierPath];

    // Create radial gradient effect
    CAGradientLayer *gradientBlob = [CAGradientLayer layer];
    gradientBlob.frame = rect;
    gradientBlob.type = kCAGradientLayerRadial;

    NSColor *centerColor = color;
    NSColor *edgeColor = [color colorWithAlphaComponent:0.6];

    gradientBlob.colors = @[
        (__bridge id)centerColor.CGColor,
        (__bridge id)edgeColor.CGColor
    ];

    gradientBlob.startPoint = CGPointMake(0.5, 0.5);
    gradientBlob.endPoint = CGPointMake(1.0, 1.0);

    // Apply blur filter
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setDefaults];
    [blurFilter setValue:@50.0 forKey:kCIInputRadiusKey];

    blob.filters = @[blurFilter];
    blob.frame = CGRectMake(position.x, position.y, size, size);
    blob.fillColor = color.CGColor;

    return blob;
}

- (void)layout {
    [super layout];

    // Update gradient layer frame
    if (self.gradientLayer) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.gradientLayer.frame = self.bounds;
        [CATransaction commit];
    }
}

- (void)startAnimations {
    if (!self.blobLayers || self.blobLayers.count == 0) {
        return;
    }

    NSArray *durations = @[@8.0, @7.0, @9.0, @10.0, @6.0];
    NSArray *offsets = @[
        @[@(-100), @(-150), @(-200), @(-250)],  // Blob 1
        @[@(150), @(100), @(-150), @(-100)],     // Blob 2
        @[@(100), @(150), @(300), @(350)],       // Blob 3
        @[@(-200), @(-150), @(250), @(300)],     // Blob 4
        @[@(200), @(250), @(100), @(50)]         // Blob 5
    ];

    for (NSInteger i = 0; i < self.blobLayers.count && i < durations.count; i++) {
        CAShapeLayer *blob = self.blobLayers[i];
        CGFloat duration = [durations[i] doubleValue];
        NSArray *blobOffsets = offsets[i];

        // Create position animation
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
        animation.duration = duration;
        animation.repeatCount = HUGE_VALF;
        animation.autoreverses = YES;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

        CGFloat fromX = [blobOffsets[0] doubleValue];
        CGFloat toX = [blobOffsets[1] doubleValue];
        CGFloat fromY = [blobOffsets[2] doubleValue];
        CGFloat toY = [blobOffsets[3] doubleValue];

        animation.fromValue = [NSValue valueWithPoint:NSMakePoint(fromX + blob.bounds.size.width / 2,
                                                                   fromY + blob.bounds.size.height / 2)];
        animation.toValue = [NSValue valueWithPoint:NSMakePoint(toX + blob.bounds.size.width / 2,
                                                                 toY + blob.bounds.size.height / 2)];

        [blob addAnimation:animation forKey:@"position"];
    }
}

- (void)stopAnimations {
    for (CAShapeLayer *blob in self.blobLayers) {
        [blob removeAllAnimations];
    }
}

- (BOOL)isOpaque {
    return YES;
}

// Helper method to convert NSBezierPath to CGPath
- (CGPathRef)convertNSBezierPathToCGPath:(NSBezierPath *)path {
    CGMutablePathRef cgPath = CGPathCreateMutable();
    NSInteger count = [path elementCount];

    for (NSInteger i = 0; i < count; i++) {
        NSPoint points[3];
        NSBezierPathElement element = [path elementAtIndex:i associatedPoints:points];

        switch (element) {
            case NSBezierPathElementMoveTo:
                CGPathMoveToPoint(cgPath, NULL, points[0].x, points[0].y);
                break;
            case NSBezierPathElementLineTo:
                CGPathAddLineToPoint(cgPath, NULL, points[0].x, points[0].y);
                break;
            case NSBezierPathElementCurveTo:
                CGPathAddCurveToPoint(cgPath, NULL,
                                     points[0].x, points[0].y,
                                     points[1].x, points[1].y,
                                     points[2].x, points[2].y);
                break;
            case NSBezierPathElementQuadraticCurveTo:
                CGPathAddQuadCurveToPoint(cgPath, NULL,
                                         points[0].x, points[0].y,
                                         points[1].x, points[1].y);
                break;
            case NSBezierPathElementClosePath:
                CGPathCloseSubpath(cgPath);
                break;
        }
    }

    return cgPath;
}

@end
