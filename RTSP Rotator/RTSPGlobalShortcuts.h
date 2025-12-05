//
//  RTSPGlobalShortcuts.h
//  RTSP Rotator
//
//  Created by Jordan Koch on 10/29/25.
//

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

NS_ASSUME_NONNULL_BEGIN

/// Global keyboard shortcut manager
@interface RTSPGlobalShortcuts : NSObject

/// Singleton instance
+ (instancetype)sharedManager;

/// Register global shortcuts
- (void)registerShortcuts;

/// Unregister global shortcuts
- (void)unregisterShortcuts;

/// Set callback for next feed shortcut
@property (nonatomic, copy, nullable) void (^onNextFeed)(void);

/// Set callback for previous feed shortcut
@property (nonatomic, copy, nullable) void (^onPreviousFeed)(void);

/// Set callback for toggle mute shortcut
@property (nonatomic, copy, nullable) void (^onToggleMute)(void);

/// Set callback for take snapshot shortcut
@property (nonatomic, copy, nullable) void (^onTakeSnapshot)(void);

/// Set callback for pause rotation shortcut
@property (nonatomic, copy, nullable) void (^onPauseRotation)(void);

@end

NS_ASSUME_NONNULL_END
