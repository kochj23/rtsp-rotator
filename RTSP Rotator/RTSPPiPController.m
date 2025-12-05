//
//  RTSPPiPController.m
//  RTSP Rotator
//

#import "RTSPPiPController.h"

@interface RTSPPiPController ()
@property (nonatomic, strong) NSWindow *pipWindow;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, assign) BOOL isVisible;
@end

@implementation RTSPPiPController

- (instancetype)initWithFeedURL:(NSURL *)feedURL {
    self = [super init];
    if (self) {
        _feedURL = feedURL;
        _windowSize = CGSizeMake(320, 240);
        _position = RTSPPiPPositionBottomRight;
        _draggable = YES;
        _staysOnTop = YES;
        _opacity = 1.0;
        _isVisible = NO;

        [self setupWindow];
        [self setupPlayer];
    }
    return self;
}

- (void)setupWindow {
    NSRect frame = [self calculateFrameForPosition:self.position];

    self.pipWindow = [[NSWindow alloc] initWithContentRect:frame
                                                  styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskResizable
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];

    self.pipWindow.backgroundColor = [NSColor blackColor];
    self.pipWindow.opaque = NO;
    self.pipWindow.hasShadow = YES;
    self.pipWindow.level = NSFloatingWindowLevel;
    self.pipWindow.movableByWindowBackground = self.draggable;
    self.pipWindow.alphaValue = self.opacity;

    // Add close button
    NSButton *closeButton = [[NSButton alloc] initWithFrame:NSMakeRect(5, frame.size.height - 25, 20, 20)];
    closeButton.title = @"×";
    closeButton.bezelStyle = NSBezelStyleCircular;
    closeButton.target = self;
    closeButton.action = @selector(closeButtonClicked:);
    [self.pipWindow.contentView addSubview:closeButton];

    // Add click gesture to swap feeds
    NSClickGestureRecognizer *clickGesture = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(windowClicked:)];
    [self.pipWindow.contentView addGestureRecognizer:clickGesture];
}

- (void)setupPlayer {
    self.player = [[AVPlayer alloc] init];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.pipWindow.contentView.bounds;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.pipWindow.contentView.layer addSublayer:self.playerLayer];
    self.pipWindow.contentView.wantsLayer = YES;

    [self loadFeed];
}

- (void)loadFeed {
    if (!self.feedURL) {
        return;
    }

    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.feedURL];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    self.player.muted = YES; // PiP is always muted by default
    [self.player play];

    NSLog(@"[PiP] Loaded feed: %@", self.feedURL.absoluteString);
}

- (void)show {
    if (self.isVisible) {
        return;
    }

    [self.pipWindow makeKeyAndOrderFront:nil];
    self.isVisible = YES;

    NSLog(@"[PiP] Showing window");
}

- (void)hide {
    if (!self.isVisible) {
        return;
    }

    [self.pipWindow orderOut:nil];
    [self.player pause];
    self.isVisible = NO;

    NSLog(@"[PiP] Hiding window");
}

- (void)updateFeedURL:(NSURL *)feedURL {
    self.feedURL = feedURL;
    [self loadFeed];
}

- (void)swapWithMainFeed {
    if ([self.delegate respondsToSelector:@selector(pipControllerDidSwapFeeds:)]) {
        [self.delegate pipControllerDidSwapFeeds:self];
    }

    NSLog(@"[PiP] Swapping with main feed");
}

- (void)setWindowSize:(CGSize)windowSize {
    _windowSize = windowSize;

    NSRect frame = self.pipWindow.frame;
    frame.size = windowSize;
    [self.pipWindow setFrame:frame display:YES animate:YES];

    self.playerLayer.frame = self.pipWindow.contentView.bounds;
}

- (void)setPosition:(RTSPPiPPosition)position {
    _position = position;

    NSRect frame = [self calculateFrameForPosition:position];
    [self.pipWindow setFrame:frame display:YES animate:YES];
}

- (void)setOpacity:(CGFloat)opacity {
    _opacity = opacity;
    self.pipWindow.alphaValue = opacity;
}

- (void)setStaysOnTop:(BOOL)staysOnTop {
    _staysOnTop = staysOnTop;
    self.pipWindow.level = staysOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel;
}

- (void)setDraggable:(BOOL)draggable {
    _draggable = draggable;
    self.pipWindow.movableByWindowBackground = draggable;
}

- (NSRect)calculateFrameForPosition:(RTSPPiPPosition)position {
    NSScreen *mainScreen = [NSScreen mainScreen];
    NSRect screenFrame = mainScreen.visibleFrame;

    CGFloat margin = 20;
    CGFloat x, y;

    switch (position) {
        case RTSPPiPPositionTopLeft:
            x = screenFrame.origin.x + margin;
            y = screenFrame.origin.y + screenFrame.size.height - self.windowSize.height - margin;
            break;
        case RTSPPiPPositionTopRight:
            x = screenFrame.origin.x + screenFrame.size.width - self.windowSize.width - margin;
            y = screenFrame.origin.y + screenFrame.size.height - self.windowSize.height - margin;
            break;
        case RTSPPiPPositionBottomLeft:
            x = screenFrame.origin.x + margin;
            y = screenFrame.origin.y + margin;
            break;
        case RTSPPiPPositionBottomRight:
        default:
            x = screenFrame.origin.x + screenFrame.size.width - self.windowSize.width - margin;
            y = screenFrame.origin.y + margin;
            break;
    }

    return NSMakeRect(x, y, self.windowSize.width, self.windowSize.height);
}

- (void)closeButtonClicked:(id)sender {
    [self hide];

    if ([self.delegate respondsToSelector:@selector(pipControllerDidClose:)]) {
        [self.delegate pipControllerDidClose:self];
    }
}

- (void)windowClicked:(NSClickGestureRecognizer *)gesture {
    if (gesture.state == NSGestureRecognizerStateEnded) {
        [self swapWithMainFeed];
    }
}

- (void)dealloc {
    [self.player pause];
    [self hide];
}

@end
