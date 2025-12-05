//
//  RTSPOSDView.m
//  RTSP Rotator
//
//  Created by Jordan Koch on 10/29/25.
//

#import "RTSPOSDView.h"

@interface RTSPOSDView ()
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSTextField *subtitleLabel;
@property (nonatomic, strong) NSTimer *hideTimer;
@property (nonatomic, strong) NSVisualEffectView *backgroundView;
@end

@implementation RTSPOSDView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setupUI];
        [self setupDefaults];
        self.hidden = YES;
    }
    return self;
}

- (void)setupDefaults {
    _backgroundColor = [NSColor colorWithWhite:0.0 alpha:0.8];
    _textColor = [NSColor whiteColor];
    _fontSize = 24.0;
    _cornerRadius = 10.0;
    _opacity = 0.9;
}

- (void)setupUI {
    // Background view with blur effect
    self.backgroundView = [[NSVisualEffectView alloc] initWithFrame:self.bounds];
    self.backgroundView.material = NSVisualEffectMaterialHUDWindow;
    self.backgroundView.state = NSVisualEffectStateActive;
    self.backgroundView.wantsLayer = YES;
    self.backgroundView.layer.cornerRadius = self.cornerRadius;
    self.backgroundView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:self.backgroundView];

    // Title label
    self.titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 50, self.bounds.size.width - 40, 30)];
    self.titleLabel.editable = NO;
    self.titleLabel.selectable = NO;
    self.titleLabel.bordered = NO;
    self.titleLabel.backgroundColor = [NSColor clearColor];
    self.titleLabel.textColor = self.textColor;
    self.titleLabel.font = [NSFont boldSystemFontOfSize:self.fontSize];
    self.titleLabel.alignment = NSTextAlignmentCenter;
    self.titleLabel.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    [self addSubview:self.titleLabel];

    // Subtitle label
    self.subtitleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 20, self.bounds.size.width - 40, 20)];
    self.subtitleLabel.editable = NO;
    self.subtitleLabel.selectable = NO;
    self.subtitleLabel.bordered = NO;
    self.subtitleLabel.backgroundColor = [NSColor clearColor];
    self.subtitleLabel.textColor = [self.textColor colorWithAlphaComponent:0.8];
    self.subtitleLabel.font = [NSFont systemFontOfSize:self.fontSize * 0.6];
    self.subtitleLabel.alignment = NSTextAlignmentCenter;
    self.subtitleLabel.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    [self addSubview:self.subtitleLabel];

    self.wantsLayer = YES;
    self.layer.cornerRadius = self.cornerRadius;
}

- (void)showWithFeedName:(NSString *)feedName
                   index:(NSInteger)index
                   total:(NSInteger)total
                duration:(NSTimeInterval)duration {

    dispatch_async(dispatch_get_main_queue(), ^{
        // Update text
        self.titleLabel.stringValue = feedName;
        self.subtitleLabel.stringValue = [NSString stringWithFormat:@"Feed %ld of %ld", (long)index, (long)total];

        // Update colors
        self.titleLabel.textColor = self.textColor;
        self.titleLabel.font = [NSFont boldSystemFontOfSize:self.fontSize];
        self.subtitleLabel.textColor = [self.textColor colorWithAlphaComponent:0.8];
        self.subtitleLabel.font = [NSFont systemFontOfSize:self.fontSize * 0.6];
        self.backgroundView.layer.cornerRadius = self.cornerRadius;

        // Cancel existing timer
        [self.hideTimer invalidate];

        // Show with animation
        self.hidden = NO;
        self.alphaValue = 0.0;
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.3;
            self.animator.alphaValue = self.opacity;
        } completionHandler:nil];

        // Schedule hide
        if (duration > 0) {
            self.hideTimer = [NSTimer scheduledTimerWithTimeInterval:duration
                                                              target:self
                                                            selector:@selector(hideAnimated)
                                                            userInfo:nil
                                                             repeats:NO];
        }
    });
}

- (void)hide {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.hideTimer invalidate];
        self.hideTimer = nil;
        self.hidden = YES;
    });
}

- (void)hideAnimated {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.3;
        self.animator.alphaValue = 0.0;
    } completionHandler:^{
        self.hidden = YES;
    }];
}

- (void)dealloc {
    [self.hideTimer invalidate];
}

@end
