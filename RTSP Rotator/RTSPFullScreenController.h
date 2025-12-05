//
//  RTSPFullScreenController.h
//  RTSP Rotator
//
//  Full-screen mode with overlay controls
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTSPFullScreenController : NSObject

- (instancetype)initWithWindow:(NSWindow *)window playerView:(NSView *)playerView;

@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic, assign) BOOL showControlsOnHover;
@property (nonatomic, assign) NSTimeInterval controlsFadeDelay;

- (void)enterFullScreen;
- (void)exitFullScreen;
- (void)toggleFullScreen;

@end

NS_ASSUME_NONNULL_END
