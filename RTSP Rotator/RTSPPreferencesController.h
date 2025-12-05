//
//  RTSPPreferencesController.h
//  RTSP Rotator
//
//  Created by Jordan Koch on 10/29/25.
//

#import <Cocoa/Cocoa.h>
#import "RTSPFeedMetadata.h"

NS_ASSUME_NONNULL_BEGIN

/// Configuration source type for RTSP feeds
typedef NS_ENUM(NSInteger, RTSPConfigurationSource) {
    RTSPConfigurationSourceManual,      ///< Manually entered feeds
    RTSPConfigurationSourceRemoteURL    ///< Feeds loaded from remote URL
};

/// Controller for the preferences window
@interface RTSPPreferencesController : NSWindowController

/// Singleton instance
+ (instancetype)sharedController;

/// Show the preferences window
- (void)showWindow:(nullable id)sender;

@end

/// Manages persistent storage and retrieval of RTSP configuration
@interface RTSPConfigurationManager : NSObject

/// Singleton instance
+ (instancetype)sharedManager;

#pragma mark - Configuration Source

/// Current configuration source type
@property (nonatomic, assign) RTSPConfigurationSource configurationSource;

/// Remote configuration URL (when source is RemoteURL)
@property (nonatomic, strong, nullable) NSString *remoteConfigurationURL;

#pragma mark - Manual Feeds

/// Manually configured RTSP feeds (with metadata)
@property (nonatomic, strong) NSArray<RTSPFeedMetadata *> *manualFeedMetadata;

/// Legacy: Manually configured RTSP feeds (URLs only)
@property (nonatomic, strong) NSArray<NSString *> *manualFeeds;

/// Add a feed to manual configuration
- (void)addManualFeed:(NSString *)feedURL;

/// Remove a feed from manual configuration at index
- (void)removeManualFeedAtIndex:(NSUInteger)index;

/// Update feed at index
- (void)updateManualFeedAtIndex:(NSUInteger)index withURL:(NSString *)feedURL;

/// Move feed from one index to another
- (void)moveManualFeedFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

#pragma mark - Playback Settings

/// Rotation interval in seconds
@property (nonatomic, assign) NSTimeInterval rotationInterval;

/// Whether to start muted
@property (nonatomic, assign) BOOL startMuted;

/// Whether to auto-skip failed feeds
@property (nonatomic, assign) BOOL autoSkipFailedFeeds;

/// Number of retry attempts for failed feeds
@property (nonatomic, assign) NSInteger retryAttempts;

#pragma mark - Display Settings

/// Display index (0 = main, 1+ = additional displays)
@property (nonatomic, assign) NSInteger displayIndex;

/// Enable grid layout
@property (nonatomic, assign) BOOL gridLayoutEnabled;

/// Grid rows
@property (nonatomic, assign) NSInteger gridRows;

/// Grid columns
@property (nonatomic, assign) NSInteger gridColumns;

#pragma mark - OSD Settings

/// Enable on-screen display
@property (nonatomic, assign) BOOL osdEnabled;

/// OSD display duration (seconds)
@property (nonatomic, assign) NSTimeInterval osdDuration;

/// OSD position (0=top-left, 1=top-right, 2=bottom-left, 3=bottom-right, 4=center)
@property (nonatomic, assign) NSInteger osdPosition;

#pragma mark - Recording Settings

/// Enable automatic snapshots
@property (nonatomic, assign) BOOL autoSnapshotsEnabled;

/// Snapshot interval (seconds)
@property (nonatomic, assign) NSTimeInterval snapshotInterval;

/// Snapshot directory
@property (nonatomic, strong, nullable) NSString *snapshotDirectory;

#pragma mark - Status Menu

/// Show status menu bar item
@property (nonatomic, assign) BOOL statusMenuEnabled;

#pragma mark - Loading Feeds

/// Load feeds based on current configuration
/// @param completion Completion handler with feeds array or error
- (void)loadFeedsWithCompletion:(void (^)(NSArray<NSString *> * _Nullable feeds, NSError * _Nullable error))completion;

/// Force refresh from remote URL (if configured)
- (void)refreshRemoteConfiguration:(void (^)(BOOL success, NSError * _Nullable error))completion;

#pragma mark - Persistence

/// Save all settings to persistent storage
- (void)save;

/// Load all settings from persistent storage
- (void)load;

/// Reset to default settings
- (void)resetToDefaults;

@end

/// Extended functionality category (implemented in RTSPPreferencesController+Extended.m)
@interface RTSPConfigurationManager (Extended)

/// Add feed with metadata
- (void)addManualFeedWithMetadata:(RTSPFeedMetadata *)metadata;

/// Update feed metadata at index
- (void)updateManualFeedMetadataAtIndex:(NSUInteger)index with:(RTSPFeedMetadata *)metadata;

/// Export feeds to file
/// @param filePath Destination file path
/// @param error Error pointer
/// @return YES if successful
- (BOOL)exportFeedsToFile:(NSString *)filePath error:(NSError **)error;

/// Import feeds from file
/// @param filePath Source file path
/// @param replace If YES, replaces existing feeds; if NO, appends
/// @param error Error pointer
/// @return Number of feeds imported
- (NSInteger)importFeedsFromFile:(NSString *)filePath replace:(BOOL)replace error:(NSError **)error;

/// Test connectivity to a feed
/// @param feedURL URL to test
/// @param completion Completion handler with success status and latency
- (void)testFeedConnectivity:(NSString *)feedURL
                  completion:(void (^)(BOOL success, NSTimeInterval latency, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
