//
//  RTSPFullScreenController.m
//  RTSP Rotator
//

#import "RTSPFullScreenController.h"

@interface RTSPFullScreenController ()
@property (nonatomic, weak) NSWindow *window;
@property (nonatomic, weak) NSView *playerView;
@property (nonatomic, strong) NSView *controlsOverlay;
@property (nonatomic, assign) NSRect savedFrame;
@end

@implementation RTSPFullScreenController

- (instancetype)initWithWindow:(NSWindow *)window playerView:(NSView *)playerView {
    self = [super init];
    if (self) {
        _window = window;
        _playerView = playerView;
        _isFullScreen = NO;
        _showControlsOnHover = YES;
        _controlsFadeDelay = 3.0;
    }
    return self;
}

- (void)enterFullScreen {
    if (self.isFullScreen) return;

    self.savedFrame = self.window.frame;
    [self.window toggleFullScreen:nil];
    self.isFullScreen = YES;

    NSLog(@"[FullScreen] Entered full-screen mode");
}

- (void)exitFullScreen {
    if (!self.isFullScreen) return;

    [self.window toggleFullScreen:nil];
    self.isFullScreen = NO;

    NSLog(@"[FullScreen] Exited full-screen mode");
}

- (void)toggleFullScreen {
    if (self.isFullScreen) {
        [self exitFullScreen];
    } else {
        [self enterFullScreen];
    }
}

@end
