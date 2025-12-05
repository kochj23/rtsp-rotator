//
//  RTSPFailoverManager.h
//  RTSP Rotator
//
//  Automatic failover to backup feeds
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTSPFeedStatus) {
    RTSPFeedStatusUnknown,
    RTSPFeedStatusHealthy,
    RTSPFeedStatusFailed,
    RTSPFeedStatusFailedOver
};

@class RTSPFailoverManager;

/// Feed configuration with backup URLs
@interface RTSPFeedConfig : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSURL *primaryURL;
@property (nonatomic, strong, nullable) NSArray<NSURL *> *backupURLs;
@property (nonatomic, assign) RTSPFeedStatus status;
@property (nonatomic, strong, nullable) NSURL *activeURL;
@property (nonatomic, strong, nullable) NSDate *lastHealthCheck;
@property (nonatomic, strong, nullable) NSError *lastError;
@end

/// Failover manager delegate
@protocol RTSPFailoverManagerDelegate <NSObject>
@optional
- (void)failoverManager:(RTSPFailoverManager *)manager didFailoverFeed:(RTSPFeedConfig *)feed toURL:(NSURL *)backupURL;
- (void)failoverManager:(RTSPFailoverManager *)manager didRestoreFeed:(RTSPFeedConfig *)feed toPrimaryURL:(NSURL *)primaryURL;
- (void)failoverManager:(RTSPFailoverManager *)manager didFailFeed:(RTSPFeedConfig *)feed withError:(NSError *)error;
- (void)failoverManager:(RTSPFailoverManager *)manager didUpdateHealthStatus:(RTSPFeedConfig *)feed;
@end

/// Manages feed failover and redundancy
@interface RTSPFailoverManager : NSObject

/// Shared instance
+ (instancetype)sharedManager;

/// Delegate for failover events
@property (nonatomic, weak) id<RTSPFailoverManagerDelegate> delegate;

/// Health check interval in seconds (default: 30)
@property (nonatomic, assign) NSTimeInterval healthCheckInterval;

/// Connection timeout in seconds (default: 10)
@property (nonatomic, assign) NSTimeInterval connectionTimeout;

/// Maximum retry attempts before failover (default: 3)
@property (nonatomic, assign) NSInteger maxRetryAttempts;

/// Enable automatic failover (default: YES)
@property (nonatomic, assign) BOOL autoFailoverEnabled;

/// All configured feeds
- (NSArray<RTSPFeedConfig *> *)feeds;

/// Register feed with backup URLs
- (void)registerFeed:(RTSPFeedConfig *)feed;

/// Unregister feed
- (void)unregisterFeed:(RTSPFeedConfig *)feed;

/// Get active URL for feed (primary or failed-over backup)
- (NSURL *)activeURLForFeed:(RTSPFeedConfig *)feed;

/// Manually trigger failover for feed
- (void)failoverFeed:(RTSPFeedConfig *)feed completion:(nullable void (^)(BOOL success, NSURL *_Nullable activeURL))completion;

/// Manually restore feed to primary
- (void)restoreToPrimaryFeed:(RTSPFeedConfig *)feed completion:(nullable void (^)(BOOL success))completion;

/// Check health of specific feed
- (void)checkFeedHealth:(RTSPFeedConfig *)feed completion:(nullable void (^)(BOOL healthy, NSError *_Nullable error))completion;

/// Start automatic health monitoring
- (void)startHealthMonitoring;

/// Stop automatic health monitoring
- (void)stopHealthMonitoring;

@end

NS_ASSUME_NONNULL_END
