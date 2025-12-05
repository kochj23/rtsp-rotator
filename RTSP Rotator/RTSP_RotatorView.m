//
//  RTSP_RotatorView.m
//  RTSP Rotator
//
//  Created by Jordan Koch on 10/10/25.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "RTSPPreferencesController.h"
#import "RTSPWallpaperController.h"
#import "RTSPFFmpegProxy.h"

/// Custom window class that allows the RTSP viewer to become key/main window
/// This enables proper event handling while maintaining desktop-level display
@interface RTSPWallpaperWindow : NSWindow
@end

@implementation RTSPWallpaperWindow

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

@end

/// Private interface extension for RTSPWallpaperController
@interface RTSPWallpaperController ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) RTSPWallpaperWindow *window;
@property (nonatomic, strong) NSTimer *rotationTimer;
@property (nonatomic, strong) id timeObserver;
@property (nonatomic, assign) BOOL usingExternalView;
@property (nonatomic, strong) NSArray<NSString *> *mutableFeeds;
@property (nonatomic, weak) AVPlayerItem *currentObservedItem;

@end

@implementation RTSPWallpaperController

@synthesize feeds = _feeds;
@synthesize currentIndex = _currentIndex;
@synthesize isMuted = _isMuted;

#pragma mark - Initialization

- (instancetype)initWithFeeds:(NSArray<NSString *> *)feeds rotationInterval:(NSTimeInterval)interval {
    self = [super init];
    if (self) {
        // Validate feeds array
        if (!feeds || feeds.count == 0) {
            NSLog(@"[ERROR] No feeds provided. Using default feeds.");
            _feeds = @[
                @"rtsp://feed1.example.com/stream",
                @"rtsp://feed2.example.com/stream"
            ];
        } else {
            _feeds = [feeds copy];
        }

        _currentIndex = 0;
        _isMuted = YES;
        _rotationInterval = (interval > 0) ? interval : 60.0;

        NSLog(@"[INFO] Initialized with %lu feeds, rotation interval: %.1fs",
              (unsigned long)_feeds.count, _rotationInterval);
    }
    return self;
}

- (instancetype)init {
    return [self initWithFeeds:@[] rotationInterval:60.0];
}

- (NSArray<NSString *> *)feeds {
    return _mutableFeeds ?: _feeds;
}

- (void)setFeeds:(NSArray<NSString *> *)feeds {
    _mutableFeeds = [feeds copy];
    NSLog(@"[INFO] Updated feeds: %lu items", (unsigned long)_mutableFeeds.count);
}

#pragma mark - Setup for Standard App Mode

- (void)setupWithView:(NSView *)view {
    if (!view) {
        NSLog(@"[ERROR] Cannot setup with nil view");
        return;
    }

    self.parentView = view;
    self.usingExternalView = YES;

    // Enable layer backing
    [view setWantsLayer:YES];

    NSLog(@"[INFO] Setup with external view");
}

- (void)setupWithWindow:(NSWindow *)window {
    if (!window) {
        NSLog(@"[ERROR] Cannot setup with nil window");
        return;
    }

    self.window = (RTSPWallpaperWindow *)window;
    self.parentView = window.contentView;
    self.usingExternalView = YES;

    // Enable layer backing
    [self.parentView setWantsLayer:YES];

    NSLog(@"[INFO] Setup with external window");
}

#pragma mark - Lifecycle

- (void)start {
    NSLog(@"[INFO] Starting RTSP Rotator");

    // Setup window on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.usingExternalView) {
            [self setupWindow];
        }
        [self setupPlayer];
        [self playCurrentFeed];
        [self startRotationTimer];
    });
}

- (void)stop {
    NSLog(@"[INFO] Stopping RTSP Rotator");

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rotationTimer invalidate];
        self.rotationTimer = nil;

        // Remove observers
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        if (self.timeObserver) {
            [self.player removeTimeObserver:self.timeObserver];
            self.timeObserver = nil;
        }

        // Remove KVO observer from current player item
        if (self.currentObservedItem) {
            @try {
                [self.currentObservedItem removeObserver:self forKeyPath:@"status"];
            } @catch (NSException *exception) {
                NSLog(@"[INFO] Observer already removed in stop: %@", exception.reason);
            }
            self.currentObservedItem = nil;
        }

        [self.player pause];
        [self.player replaceCurrentItemWithPlayerItem:nil];
        self.player = nil;

        [self.playerLayer removeFromSuperlayer];
        self.playerLayer = nil;

        // Stop all FFmpeg proxies
        NSLog(@"[INFO] Stopping FFmpeg proxies...");
        [[RTSPFFmpegProxy sharedProxy] stopAllProxies];

        // Only close window if we created it (not using external view)
        if (!self.usingExternalView && self.window) {
            [self.window close];
            self.window = nil;
        }
    });
}

- (void)dealloc {
    [self stop];
}

#pragma mark - Setup

- (void)setupWindow {
    NSScreen *mainScreen = [NSScreen mainScreen];
    if (!mainScreen) {
        NSLog(@"[ERROR] No main screen found");
        return;
    }

    self.window = [[RTSPWallpaperWindow alloc] initWithContentRect:mainScreen.frame
                                                         styleMask:NSWindowStyleMaskBorderless
                                                           backing:NSBackingStoreBuffered
                                                             defer:NO];

    if (!self.window) {
        NSLog(@"[ERROR] Failed to create window");
        return;
    }

    // Enable layer backing for video playback
    [self.window.contentView setWantsLayer:YES];

    [self.window setLevel:kCGDesktopWindowLevel];
    [self.window setBackgroundColor:[NSColor blackColor]];
    [self.window makeKeyAndOrderFront:nil];

    NSLog(@"[INFO] Window created at desktop level");
}

- (void)setupPlayer {
    self.player = [[AVPlayer alloc] init];
    if (!self.player) {
        NSLog(@"[ERROR] Failed to create AVPlayer");
        return;
    }

    // Determine target view
    NSView *targetView = self.parentView ?: self.window.contentView;
    if (!targetView) {
        NSLog(@"[ERROR] No target view for player layer");
        return;
    }

    // Create player layer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = targetView.bounds;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;

    [targetView.layer addSublayer:self.playerLayer];

    // Set up notification observers for player state
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemFailedToPlay:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:nil];

    NSLog(@"[INFO] AVPlayer initialized");
}

- (void)startRotationTimer {
    // Use block-based API to avoid retain cycle (available in macOS 10.12+)
    __weak typeof(self) weakSelf = self;
    self.rotationTimer = [NSTimer scheduledTimerWithTimeInterval:self.rotationInterval
                                                         repeats:YES
                                                           block:^(NSTimer *timer) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf nextFeed];
        } else {
            [timer invalidate];
        }
    }];

    NSLog(@"[INFO] Rotation timer started (interval: %.1fs)", self.rotationInterval);
}

#pragma mark - Feed Management

- (void)nextFeed {
    NSLog(@"[INFO] Switching to next feed");
    self.currentIndex = (self.currentIndex + 1) % self.feeds.count;
    [self playCurrentFeed];
}

- (void)playCurrentFeed {
    if (self.currentIndex >= self.feeds.count) {
        NSLog(@"[ERROR] Invalid feed index: %lu", (unsigned long)self.currentIndex);
        return;
    }

    NSString *feedURLString = self.feeds[self.currentIndex];
    NSURL *feedURL = [NSURL URLWithString:feedURLString];

    if (!feedURL) {
        NSLog(@"[ERROR] Invalid feed URL: %@", feedURLString);
        return;
    }

    NSLog(@"[INFO] Playing feed %lu/%lu: %@",
          (unsigned long)(self.currentIndex + 1),
          (unsigned long)self.feeds.count,
          feedURLString);

    // Check if this is an RTSPS URL that needs proxying
    if ([feedURL.scheme isEqualToString:@"rtsps"]) {
        NSLog(@"[INFO] RTSPS URL detected - starting FFmpeg proxy");

        // Get camera name for logging (use index as fallback)
        NSString *cameraName = [NSString stringWithFormat:@"Camera %lu", (unsigned long)(self.currentIndex + 1)];

        // Start FFmpeg proxy
        RTSPFFmpegProxy *proxy = [RTSPFFmpegProxy sharedProxy];
        NSURL *localURL = [proxy startProxyForURL:feedURL cameraName:cameraName];

        if (localURL) {
            NSLog(@"[INFO] Using FFmpeg proxy: %@ → %@", feedURLString, localURL.absoluteString);
            feedURL = localURL; // Use local RTSP URL instead
            feedURLString = localURL.absoluteString;
        } else {
            NSLog(@"[ERROR] Failed to start FFmpeg proxy for %@", feedURLString);
            // Continue anyway, might work without proxy
        }
    }

    // Create AVPlayerItem with URL
    // For rtsps:// URLs with self-signed certs, use AVURLAsset with proper options
    AVPlayerItem *playerItem;
    if ([feedURLString hasPrefix:@"rtsps://"]) {
        // Create AVURLAsset with options that work better with RTSP streams
        NSDictionary *options = @{
            AVURLAssetPreferPreciseDurationAndTimingKey: @NO,  // Better for live streams
            @"AVURLAssetOutOfBandMIMETypeKey": @"application/sdp"  // RTSP hint
        };
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:feedURL options:options];
        playerItem = [AVPlayerItem playerItemWithAsset:asset];
        NSLog(@"[INFO] Created AVPlayerItem for rtsps:// URL (self-signed cert compatible)");
    } else {
        playerItem = [AVPlayerItem playerItemWithURL:feedURL];
    }

    if (!playerItem) {
        NSLog(@"[ERROR] Failed to create AVPlayerItem from URL: %@", feedURLString);
        return;
    }

    // Remove observer from previous item if exists
    if (self.currentObservedItem) {
        @try {
            [self.currentObservedItem removeObserver:self forKeyPath:@"status"];
        } @catch (NSException *exception) {
            NSLog(@"[INFO] Observer already removed: %@", exception.reason);
        }
        self.currentObservedItem = nil;
    }

    // Replace current item and play
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    self.player.muted = self.isMuted;
    [self.player play];

    // Monitor player status for new item
    self.currentObservedItem = playerItem;
    [playerItem addObserver:self
                 forKeyPath:@"status"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
}

#pragma mark - Audio Control

- (void)toggleMute {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isMuted = !self.isMuted;
        self.player.muted = self.isMuted;
        NSLog(@"[INFO] Audio muted: %@", self.isMuted ? @"YES" : @"NO");
    });
}

#pragma mark - AVPlayer Observers

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        switch (item.status) {
            case AVPlayerItemStatusReadyToPlay:
                NSLog(@"[INFO] Player ready to play");
                break;
            case AVPlayerItemStatusFailed:
                {
                    NSString *feedURL = self.feeds[self.currentIndex];
                    NSLog(@"[ERROR] ========================================");
                    NSLog(@"[ERROR] PLAYBACK FAILED FOR CAMERA %lu/%lu",
                          (unsigned long)(self.currentIndex + 1),
                          (unsigned long)self.feeds.count);
                    NSLog(@"[ERROR] URL: %@", feedURL);
                    if (item.error) {
                        NSLog(@"[ERROR] Error Code: %ld", (long)item.error.code);
                        NSLog(@"[ERROR] Error Domain: %@", item.error.domain);
                        NSLog(@"[ERROR] Description: %@", item.error.localizedDescription);
                        if (item.error.userInfo) {
                            NSLog(@"[ERROR] Details: %@", item.error.userInfo);
                        }
                    }
                    NSLog(@"[ERROR] ========================================");

                    // Show user-friendly alert for first failure
                    static BOOL hasShownAlert = NO;
                    if (!hasShownAlert) {
                        hasShownAlert = YES;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSAlert *alert = [[NSAlert alloc] init];
                            alert.messageText = @"Camera Connection Failed";
                            alert.informativeText = [NSString stringWithFormat:@"Failed to connect to camera:\n\n%@\n\nError: %@\n\nCheck Window > Show Camera List for all camera statuses.",
                                                   feedURL,
                                                   item.error.localizedDescription ?: @"Unknown error"];
                            alert.alertStyle = NSAlertStyleWarning;
                            [alert addButtonWithTitle:@"OK"];
                            [alert runModal];
                        });
                    }
                }
                break;
            case AVPlayerItemStatusUnknown:
                NSLog(@"[INFO] Player status unknown");
                break;
        }
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    NSLog(@"[INFO] Player item reached end");
    // RTSP streams shouldn't normally end, so this might indicate a problem
    dispatch_async(dispatch_get_main_queue(), ^{
        [self playCurrentFeed]; // Retry current feed
    });
}

- (void)playerItemFailedToPlay:(NSNotification *)notification {
    NSLog(@"[ERROR] Player item failed to play");
    AVPlayerItem *item = notification.object;
    if (item.error) {
        NSLog(@"[ERROR] Error: %@", item.error.localizedDescription);
    }
}

@end

// Note: This file contains RTSPWallpaperWindow and RTSPWallpaperController implementations
// Application delegate is in AppDelegate.m
