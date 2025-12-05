//
//  RTSPOSDView.h
//  RTSP Rotator
//
//  Created by Jordan Koch on 10/29/25.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// On-screen display overlay for showing feed information
@interface RTSPOSDView : NSView

/// Show OSD with feed information
/// @param feedName Name or URL of the feed
/// @param index Current feed index (1-based)
/// @param total Total number of feeds
/// @param duration How long to display OSD (seconds)
- (void)showWithFeedName:(NSString *)feedName
                   index:(NSInteger)index
                   total:(NSInteger)total
                duration:(NSTimeInterval)duration;

/// Hide OSD immediately
- (void)hide;

/// Configure OSD appearance
@property (nonatomic, strong) NSColor *backgroundColor;
@property (nonatomic, strong) NSColor *textColor;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat opacity;

@end

NS_ASSUME_NONNULL_END
