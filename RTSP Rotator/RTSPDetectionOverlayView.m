//
//  RTSPDetectionOverlayView.m
//  RTSP Rotator
//
//  Visual overlay for displaying object detection results on video
//

#import "RTSPDetectionOverlayView.h"
#import <QuartzCore/QuartzCore.h>

@interface RTSPDetectionOverlayView ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, CAShapeLayer *> *detectionLayers;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CATextLayer *> *labelLayers;

@end

@implementation RTSPDetectionOverlayView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.wantsLayer = YES;
    self.layer = [CALayer layer];
    self.layer.backgroundColor = [[NSColor clearColor] CGColor];

    _detectionLayers = [NSMutableDictionary dictionary];
    _labelLayers = [NSMutableDictionary dictionary];
    _detections = @[];
    _style = RTSPDetectionOverlayStyleDefault;
    _showConfidence = YES;
    _showLabels = YES;
    _showZones = YES;
    _animationEnabled = YES;
    _lineWidth = 2.0;
    _fontSize = 14.0;

    NSLog(@"[DetectionOverlay] Initialized overlay view");
}

- (void)updateDetections:(NSArray<RTSPDetection *> *)detections {
    self.detections = detections;
    [self setNeedsDisplay:YES];

    if (self.animationEnabled) {
        [self animateDetections];
    }
}

- (void)clearDetections {
    self.detections = @[];
    [self.detectionLayers removeAllObjects];
    [self.labelLayers removeAllObjects];
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    if (self.detections.count == 0 && (!self.zones || self.zones.count == 0)) {
        return;
    }

    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    CGContextSaveGState(context);

    // Draw zones first (behind detections)
    if (self.showZones && self.zones) {
        [self drawZones:context];
    }

    // Draw detections
    [self drawDetections:context];

    CGContextRestoreGState(context);
}

- (void)drawZones:(CGContextRef)context {
    NSRect bounds = self.bounds;

    for (RTSPDetectionZone *zone in self.zones) {
        if (!zone.enabled) continue;

        CGRect rect = zone.normalizedRect;
        CGRect pixelRect = CGRectMake(
            rect.origin.x * bounds.size.width,
            rect.origin.y * bounds.size.height,
            rect.size.width * bounds.size.width,
            rect.size.height * bounds.size.height
        );

        // Draw zone boundary
        CGContextSetStrokeColorWithColor(context, [[NSColor cyanColor] colorWithAlphaComponent:0.5].CGColor);
        CGContextSetLineWidth(context, 1.0);
        CGContextSetLineDash(context, 0, (CGFloat[]){5.0, 3.0}, 2);
        CGContextStrokeRect(context, pixelRect);

        // Draw zone label
        NSDictionary *attributes = @{
            NSFontAttributeName: [NSFont systemFontOfSize:12],
            NSForegroundColorAttributeName: [NSColor cyanColor]
        };

        NSAttributedString *label = [[NSAttributedString alloc] initWithString:zone.name attributes:attributes];
        [label drawAtPoint:CGPointMake(pixelRect.origin.x + 5, pixelRect.origin.y + pixelRect.size.height - 20)];

        CGContextSetLineDash(context, 0, NULL, 0); // Reset dash
    }
}

- (void)drawDetections:(CGContextRef)context {
    NSRect bounds = self.bounds;

    for (RTSPDetection *detection in self.detections) {
        CGRect box = [detection boundingBoxForImageSize:bounds.size];

        // Get color for this class
        NSColor *color = [[self class] colorForClass:detection.label];

        // Draw bounding box
        [self drawBoundingBox:box color:color context:context];

        // Draw label
        if (self.showLabels) {
            [self drawLabel:detection box:box color:color];
        }
    }
}

- (void)drawBoundingBox:(CGRect)box color:(NSColor *)color context:(CGContextRef)context {
    switch (self.style) {
        case RTSPDetectionOverlayStyleDefault:
        case RTSPDetectionOverlayStyleHighlight:
            CGContextSetStrokeColorWithColor(context, color.CGColor);
            CGContextSetLineWidth(context, self.lineWidth);
            CGContextStrokeRect(context, box);

            if (self.style == RTSPDetectionOverlayStyleHighlight) {
                // Add glow effect
                CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 10.0, color.CGColor);
                CGContextStrokeRect(context, box);
                CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 0, NULL); // Reset shadow
            }
            break;

        case RTSPDetectionOverlayStyleMinimal:
            CGContextSetStrokeColorWithColor(context, color.CGColor);
            CGContextSetLineWidth(context, 1.0);
            CGContextStrokeRect(context, box);
            break;

        case RTSPDetectionOverlayStyleDebug:
            // Draw filled background
            CGContextSetFillColorWithColor(context, [color colorWithAlphaComponent:0.2].CGColor);
            CGContextFillRect(context, box);
            CGContextSetStrokeColorWithColor(context, color.CGColor);
            CGContextSetLineWidth(context, 2.0);
            CGContextStrokeRect(context, box);
            break;
    }
}

- (void)drawLabel:(RTSPDetection *)detection box:(CGRect)box color:(NSColor *)color {
    NSString *labelText = detection.label;
    if (self.showConfidence) {
        labelText = [NSString stringWithFormat:@"%@ %.0f%%", detection.label, detection.confidence * 100];
    }

    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont boldSystemFontOfSize:self.fontSize],
        NSForegroundColorAttributeName: [NSColor whiteColor]
    };

    NSAttributedString *label = [[NSAttributedString alloc] initWithString:labelText attributes:attributes];
    NSSize labelSize = [label size];

    // Background for label
    CGRect labelBg = CGRectMake(
        box.origin.x,
        box.origin.y - labelSize.height - 4,
        labelSize.width + 8,
        labelSize.height + 4
    );

    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    CGContextSetFillColorWithColor(context, [color colorWithAlphaComponent:0.8].CGColor);
    CGContextFillRect(context, labelBg);

    // Draw label text
    [label drawAtPoint:CGPointMake(labelBg.origin.x + 4, labelBg.origin.y + 2)];
}

- (void)animateDetections {
    // Animate appearance of new detections
    for (RTSPDetection *detection in self.detections) {
        NSString *trackingID = detection.trackingID;

        if (!self.detectionLayers[trackingID]) {
            // Create new layer with fade-in animation
            CAShapeLayer *layer = [CAShapeLayer layer];

            CGRect box = [detection boundingBoxForImageSize:self.bounds.size];
            CGPathRef path = CGPathCreateWithRect(box, NULL);
            layer.path = path;
            CGPathRelease(path);

            layer.strokeColor = [[self class] colorForClass:detection.label].CGColor;
            layer.fillColor = [[NSColor clearColor] CGColor];
            layer.lineWidth = self.lineWidth;

            // Fade in animation
            CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeIn.fromValue = @0.0;
            fadeIn.toValue = @1.0;
            fadeIn.duration = 0.3;
            [layer addAnimation:fadeIn forKey:@"fadeIn"];

            [self.layer addSublayer:layer];
            self.detectionLayers[trackingID] = layer;
        }
    }

    // Remove old detections
    NSSet *currentIDs = [NSSet setWithArray:[self.detections valueForKey:@"trackingID"]];
    NSArray *layerIDs = [self.detectionLayers allKeys];

    for (NSString *layerID in layerIDs) {
        if (![currentIDs containsObject:layerID]) {
            CALayer *layer = self.detectionLayers[layerID];

            // Fade out animation
            CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeOut.fromValue = @1.0;
            fadeOut.toValue = @0.0;
            fadeOut.duration = 0.3;
            fadeOut.fillMode = kCAFillModeForwards;
            fadeOut.removedOnCompletion = NO;

            [layer addAnimation:fadeOut forKey:@"fadeOut"];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [layer removeFromSuperlayer];
                [self.detectionLayers removeObjectForKey:layerID];
            });
        }
    }
}

+ (NSColor *)colorForClass:(NSString *)className {
    static NSDictionary<NSString *, NSColor *> *colorMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorMap = @{
            @"person": [NSColor systemRedColor],
            @"car": [NSColor systemBlueColor],
            @"truck": [NSColor systemIndigoColor],
            @"bus": [NSColor systemPurpleColor],
            @"motorcycle": [NSColor systemOrangeColor],
            @"bicycle": [NSColor systemYellowColor],
            @"dog": [NSColor systemGreenColor],
            @"cat": [NSColor systemTealColor],
            @"bird": [NSColor systemMintColor],
            @"horse": [NSColor systemBrownColor],
            @"package": [NSColor systemPinkColor],
            @"backpack": [NSColor systemCyanColor]
        };
    });

    NSColor *color = colorMap[className.lowercaseString];
    if (!color) {
        // Generate consistent color from hash
        NSUInteger hash = [className hash];
        CGFloat hue = (hash % 360) / 360.0;
        color = [NSColor colorWithHue:hue saturation:0.7 brightness:0.9 alpha:1.0];
    }

    return color;
}

- (BOOL)isFlipped {
    return YES; // Use top-left origin for easier coordinate mapping
}

@end
