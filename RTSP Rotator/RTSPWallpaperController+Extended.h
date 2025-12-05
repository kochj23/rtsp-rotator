//
//  RTSPWallpaperController+Extended.h
//  RTSP Rotator - Extended Controller Features
//
//  Created by Jordan Koch on 10/29/25.
//

#import <Foundation/Foundation.h>

@class RTSPWallpaperController, RTSPRecorder, RTSPOSDView, RTSPStatusMenuController, RTSPFeedMetadata;

NS_ASSUME_NONNULL_BEGIN

/// Extended category for RTSPWallpaperController
@interface RTSPWallpaperController (Extended)

#pragma mark - Recording

/// Recorder instance
@property (nonatomic, strong, readonly) RTSPRecorder *recorder;

/// Take a snapshot
- (void)takeSnapshot;

/// Start recording
- (void)startRecording;

/// Stop recording
- (void)stopRecording;

#pragma mark - OSD

/// OSD view
@property (nonatomic, strong, readonly, nullable) RTSPOSDView *osdView;

/// Show OSD with current feed info
- (void)showOSD;

#pragma mark - Status Menu

/// Status menu controller
@property (nonatomic, strong, readonly, nullable) RTSPStatusMenuController *statusMenu;

#pragma mark - Multi-Monitor

/// Set target display
/// @param displayIndex Display index (0 = main, 1+ = additional)
- (void)setDisplayIndex:(NSInteger)displayIndex;

/// Get available displays
+ (NSArray<NSScreen *> *)availableDisplays;

#pragma mark - Grid Layout

/// Enable grid layout
/// @param rows Number of rows
/// @param columns Number of columns
- (void)enableGridLayoutWithRows:(NSInteger)rows columns:(NSInteger)columns;

/// Disable grid layout
- (void)disableGridLayout;

#pragma mark - Feed Metadata

/// Current feed metadata
@property (nonatomic, strong, readonly, nullable) RTSPFeedMetadata *currentFeedMetadata;

/// Update health status for current feed
- (void)updateCurrentFeedHealth:(BOOL)successful;

#pragma mark - Navigation

/// Go to previous feed
- (void)previousFeed;

/// Pause rotation
- (void)pauseRotation;

/// Resume rotation
- (void)resumeRotation;

/// Whether rotation is paused
@property (nonatomic, assign, readonly) BOOL rotationPaused;

@end

NS_ASSUME_NONNULL_END
