//
//  RTSPThumbnailGrid.h
//  RTSP Rotator
//
//  Grid view of feed thumbnails for quick access
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RTSPThumbnailGrid;

/// Thumbnail cell representing a feed
@interface RTSPThumbnailCell : NSView
@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong) NSTextField *labelField;
@property (nonatomic, strong) NSView *statusIndicator;
@property (nonatomic, strong) NSURL *feedURL;
@property (nonatomic, assign) BOOL isHealthy;
@property (nonatomic, assign) BOOL isSelected;
@end

/// Thumbnail grid delegate
@protocol RTSPThumbnailGridDelegate <NSObject>
@optional
- (void)thumbnailGrid:(RTSPThumbnailGrid *)grid didSelectFeedAtIndex:(NSUInteger)index;
- (void)thumbnailGrid:(RTSPThumbnailGrid *)grid didReorderFeedFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;
@end

/// Grid view for feed thumbnails
@interface RTSPThumbnailGrid : NSView

/// Initialize with feed URLs
- (instancetype)initWithFeedURLs:(NSArray<NSURL *> *)feedURLs;

/// Delegate for grid events
@property (nonatomic, weak) id<RTSPThumbnailGridDelegate> delegate;

/// Feed URLs
@property (nonatomic, strong) NSArray<NSURL *> *feedURLs;

/// Refresh interval in seconds (default: 5.0)
@property (nonatomic, assign) NSTimeInterval refreshInterval;

/// Thumbnail size (default: 160x120)
@property (nonatomic, assign) CGSize thumbnailSize;

/// Grid columns (default: 4, auto-calculated)
@property (nonatomic, assign) NSInteger columns;

/// Enable drag-and-drop reordering (default: YES)
@property (nonatomic, assign) BOOL allowsReordering;

/// Currently selected index
@property (nonatomic, assign) NSInteger selectedIndex;

/// Reload all thumbnails
- (void)reloadThumbnails;

/// Update thumbnail at index
- (void)updateThumbnailAtIndex:(NSUInteger)index;

/// Update feed health status
- (void)updateHealthStatus:(BOOL)healthy atIndex:(NSUInteger)index;

/// Start auto-refresh
- (void)startAutoRefresh;

/// Stop auto-refresh
- (void)stopAutoRefresh;

@end

NS_ASSUME_NONNULL_END
