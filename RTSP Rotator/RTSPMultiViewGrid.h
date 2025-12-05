//
//  RTSPMultiViewGrid.h
//  RTSP Rotator
//
//  Grid view controller for multiple simultaneous camera feeds
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <AVFoundation/AVFoundation.h>
#import "RTSPDashboardManager.h"
#import "RTSPCameraDiagnostics.h"

NS_ASSUME_NONNULL_BEGIN

/// Individual camera cell in the grid
@interface RTSPCameraCell : NSView

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) RTSPCameraConfig *cameraConfig;
@property (nonatomic, strong) NSTextField *labelField;
@property (nonatomic, strong) NSTextField *timestampField;
@property (nonatomic, strong) NSView *statusIndicator;
@property (nonatomic, strong) NSTextField *diagnosticsLabel;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL showLabel;
@property (nonatomic, assign) BOOL showTimestamp;
@property (nonatomic, assign) BOOL showDiagnostics;

/// Load and play camera feed
- (void)loadFeed;

/// Stop playback
- (void)stopPlayback;

/// Update status indicator with health status
- (void)updateStatusWithHealthStatus:(RTSPCameraHealthStatus)status;

/// Update status indicator (legacy method)
- (void)updateStatusWithState:(NSString *)state;

/// Update diagnostics display
- (void)updateDiagnosticsDisplay;

@end

@class RTSPMultiViewGrid;

/// Multi-view grid delegate
@protocol RTSPMultiViewGridDelegate <NSObject>
@optional
- (void)multiViewGrid:(RTSPMultiViewGrid *)grid didSelectCamera:(RTSPCameraConfig *)camera;
- (void)multiViewGrid:(RTSPMultiViewGrid *)grid cameraDidFail:(RTSPCameraConfig *)camera withError:(NSError *)error;
@end

/// Multi-camera grid view controller
@interface RTSPMultiViewGrid : NSView

/// Initialize with dashboard
- (instancetype)initWithDashboard:(nullable RTSPDashboard *)dashboard;

/// Delegate for grid events
@property (nonatomic, weak) id<RTSPMultiViewGridDelegate> delegate;

/// Current dashboard
@property (nonatomic, strong) RTSPDashboard *dashboard;

/// All camera cells
@property (nonatomic, strong, readonly) NSArray<RTSPCameraCell *> *cameraCells;

/// Grid spacing (default: 2)
@property (nonatomic, assign) CGFloat gridSpacing;

/// Show diagnostics overlay (default: NO)
@property (nonatomic, assign) BOOL showDiagnostics;

/// Enable automatic health monitoring (default: NO)
@property (nonatomic, assign) BOOL autoHealthMonitoring;

/// Load dashboard and create grid
- (void)loadDashboard:(RTSPDashboard *)dashboard;

/// Start all camera feeds
- (void)startAllFeeds;

/// Stop all camera feeds
- (void)stopAllFeeds;

/// Refresh specific camera
- (void)refreshCameraAtIndex:(NSInteger)index;

/// Refresh all cameras
- (void)refreshAllCameras;

/// Get cell at grid position
- (nullable RTSPCameraCell *)cellAtRow:(NSInteger)row column:(NSInteger)column;

/// Layout cameras in grid based on dashboard layout
- (void)layoutCameraGrid;

/// Run diagnostics on all cameras in grid
- (void)runDiagnostics;

/// Update all status indicators
- (void)updateAllStatusIndicators;

@end

NS_ASSUME_NONNULL_END
