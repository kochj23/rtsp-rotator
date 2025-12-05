//
//  RTSPStatusWindow.h
//  RTSP Rotator
//
//  Status window for showing real-time operation logs
//

#import <Cocoa/Cocoa.h>

@interface RTSPStatusWindow : NSWindowController

+ (instancetype)sharedWindow;

- (void)show;
- (void)hide;
- (void)clearLog;
- (void)appendLog:(NSString *)message;
- (void)appendLog:(NSString *)message level:(NSString *)level;

@end
