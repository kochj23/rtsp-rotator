//
//  RTSPAnnotationOverlay.m
//  RTSP Rotator
//

#import "RTSPAnnotationOverlay.h"

@implementation RTSPAnnotation
@end

@implementation RTSPAnnotationOverlay

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        _annotations = [NSMutableArray array];
        _showTimestamp = YES;
        _showFeedName = YES;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    // Draw timestamp
    if (self.showTimestamp) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        NSString *timestamp = [formatter stringFromDate:[NSDate date]];

        NSDictionary *attrs = @{NSFontAttributeName: [NSFont systemFontOfSize:14],
                               NSForegroundColorAttributeName: [NSColor whiteColor]};
        [timestamp drawAtPoint:NSMakePoint(10, self.bounds.size.height - 30) withAttributes:attrs];
    }

    // Draw feed name
    if (self.showFeedName && self.feedName) {
        NSDictionary *attrs = @{NSFontAttributeName: [NSFont boldSystemFontOfSize:16],
                               NSForegroundColorAttributeName: [NSColor whiteColor]};
        [self.feedName drawAtPoint:NSMakePoint(10, 10) withAttributes:attrs];
    }

    // Draw annotations
    for (RTSPAnnotation *annotation in self.annotations) {
        NSDictionary *attrs = @{NSFontAttributeName: [NSFont systemFontOfSize:annotation.fontSize],
                               NSForegroundColorAttributeName: annotation.color};
        [annotation.text drawAtPoint:annotation.position withAttributes:attrs];
    }
}

- (void)addAnnotation:(RTSPAnnotation *)annotation {
    [self.annotations addObject:annotation];
    [self setNeedsDisplay:YES];
}

- (void)removeAnnotation:(RTSPAnnotation *)annotation {
    [self.annotations removeObject:annotation];
    [self setNeedsDisplay:YES];
}

- (void)clearAnnotations {
    [self.annotations removeAllObjects];
    [self setNeedsDisplay:YES];
}

@end
