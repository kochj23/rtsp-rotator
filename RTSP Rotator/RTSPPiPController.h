//
//  RTSPPiPController.h
//  RTSP Rotator
//
//  Picture-in-Picture mode for monitoring multiple feeds
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTSPPiPPosition) {
    RTSPPiPPositionTopLeft,
    RTSPPiPPositionTopRight,
    RTSPPiPPositionBottomLeft,
    RTSPPiPPositionBottomRight
};

@class RTSPPiPController;

/// PiP delegate for interaction events
@protocol RTSPPiPControllerDelegate <NSObject>
@optional
- (void)pipControllerDidSwapFeeds:(RTSPPiPController *)controller;
- (void)pipControllerDidClose:(RTSPPiPController *)controller;
@end

/// Picture-in-Picture window controller
@interface RTSPPiPController : NSObject

/// Initialize with feed URL
- (instancetype)initWithFeedURL:(NSURL *)feedURL;

/// Delegate for PiP events
@property (nonatomic, weak) id<RTSPPiPControllerDelegate> delegate;

/// Show PiP window
- (void)show;

/// Hide PiP window
- (void)hide;

/// Whether PiP is currently visible
@property (nonatomic, assign, readonly) BOOL isVisible;

/// PiP window size (default: 320x240)
@property (nonatomic, assign) CGSize windowSize;

/// PiP position (default: bottom right)
@property (nonatomic, assign) RTSPPiPPosition position;

/// Whether window is draggable (default: YES)
@property (nonatomic, assign) BOOL draggable;

/// Whether window stays on top (default: YES)
@property (nonatomic, assign) BOOL staysOnTop;

/// Opacity (0.0 - 1.0, default: 1.0)
@property (nonatomic, assign) CGFloat opacity;

/// Current feed URL
@property (nonatomic, strong) NSURL *feedURL;

/// Update feed URL
- (void)updateFeedURL:(NSURL *)feedURL;

/// Swap with main feed (calls delegate)
- (void)swapWithMainFeed;

@end

NS_ASSUME_NONNULL_END
