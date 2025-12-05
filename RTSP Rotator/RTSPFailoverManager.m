//
//  RTSPFailoverManager.m
//  RTSP Rotator
//

#import "RTSPFailoverManager.h"
#import <AVFoundation/AVFoundation.h>

@implementation RTSPFeedConfig
@end

@interface RTSPFailoverManager ()
@property (nonatomic, strong) NSMutableArray<RTSPFeedConfig *> *allFeeds;
@property (nonatomic, strong) NSTimer *healthCheckTimer;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *retryAttempts;
@end

@implementation RTSPFailoverManager

+ (instancetype)sharedManager {
    static RTSPFailoverManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RTSPFailoverManager alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _allFeeds = [NSMutableArray array];
        _retryAttempts = [NSMutableDictionary dictionary];
        _healthCheckInterval = 30.0;
        _connectionTimeout = 10.0;
        _maxRetryAttempts = 3;
        _autoFailoverEnabled = YES;
    }
    return self;
}

- (NSArray<RTSPFeedConfig *> *)feeds {
    return [self.allFeeds copy];
}

- (void)registerFeed:(RTSPFeedConfig *)feed {
    if ([self.allFeeds containsObject:feed]) {
        return;
    }

    feed.status = RTSPFeedStatusUnknown;
    feed.activeURL = feed.primaryURL;
    [self.allFeeds addObject:feed];

    NSLog(@"[Failover] Registered feed: %@", feed.name);

    // Initial health check
    [self checkFeedHealth:feed completion:nil];
}

- (void)unregisterFeed:(RTSPFeedConfig *)feed {
    [self.allFeeds removeObject:feed];
    [self.retryAttempts removeObjectForKey:feed.primaryURL.absoluteString];

    NSLog(@"[Failover] Unregistered feed: %@", feed.name);
}

- (NSURL *)activeURLForFeed:(RTSPFeedConfig *)feed {
    return feed.activeURL ?: feed.primaryURL;
}

- (void)checkFeedHealth:(RTSPFeedConfig *)feed completion:(void (^)(BOOL, NSError * _Nullable))completion {
    NSURL *urlToCheck = feed.activeURL;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL healthy = [self testConnection:urlToCheck timeout:self.connectionTimeout];
        NSError *error = nil;

        if (!healthy) {
            error = [NSError errorWithDomain:@"RTSPFailoverManager"
                                        code:1001
                                    userInfo:@{NSLocalizedDescriptionKey: @"Feed connection failed"}];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            feed.lastHealthCheck = [NSDate date];
            feed.lastError = error;

            if (healthy) {
                feed.status = RTSPFeedStatusHealthy;
                // Reset retry counter on success
                [self.retryAttempts removeObjectForKey:feed.primaryURL.absoluteString];
            } else {
                feed.status = RTSPFeedStatusFailed;
                [self handleFailedFeed:feed];
            }

            if ([self.delegate respondsToSelector:@selector(failoverManager:didUpdateHealthStatus:)]) {
                [self.delegate failoverManager:self didUpdateHealthStatus:feed];
            }

            if (completion) {
                completion(healthy, error);
            }

            NSLog(@"[Failover] Health check for %@: %@", feed.name, healthy ? @"HEALTHY" : @"FAILED");
        });
    });
}

- (BOOL)testConnection:(NSURL *)url timeout:(NSTimeInterval)timeout {
    // Simple connectivity test using AVPlayer
    AVPlayer *testPlayer = [[AVPlayer alloc] init];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
    [testPlayer replaceCurrentItemWithPlayerItem:playerItem];

    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    BOOL connected = NO;

    while ([[NSDate date] compare:timeoutDate] == NSOrderedAscending) {
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            connected = YES;
            break;
        } else if (playerItem.status == AVPlayerItemStatusFailed) {
            connected = NO;
            break;
        }

        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    return connected;
}

- (void)handleFailedFeed:(RTSPFeedConfig *)feed {
    if (!self.autoFailoverEnabled) {
        if ([self.delegate respondsToSelector:@selector(failoverManager:didFailFeed:withError:)]) {
            [self.delegate failoverManager:self didFailFeed:feed withError:feed.lastError];
        }
        return;
    }

    // Check retry count
    NSNumber *retries = self.retryAttempts[feed.primaryURL.absoluteString];
    NSInteger retryCount = retries ? [retries integerValue] : 0;

    if (retryCount < self.maxRetryAttempts) {
        // Increment retry counter
        self.retryAttempts[feed.primaryURL.absoluteString] = @(retryCount + 1);
        NSLog(@"[Failover] Retry %ld/%ld for %@", (long)retryCount + 1, (long)self.maxRetryAttempts, feed.name);
        return;
    }

    // Max retries reached, attempt failover
    [self failoverFeed:feed completion:nil];
}

- (void)failoverFeed:(RTSPFeedConfig *)feed completion:(void (^)(BOOL, NSURL * _Nullable))completion {
    if (!feed.backupURLs || feed.backupURLs.count == 0) {
        NSLog(@"[Failover] No backup URLs available for %@", feed.name);

        if ([self.delegate respondsToSelector:@selector(failoverManager:didFailFeed:withError:)]) {
            NSError *error = [NSError errorWithDomain:@"RTSPFailoverManager"
                                                code:1002
                                            userInfo:@{NSLocalizedDescriptionKey: @"No backup URLs configured"}];
            [self.delegate failoverManager:self didFailFeed:feed withError:error];
        }

        if (completion) completion(NO, nil);
        return;
    }

    // Try each backup URL
    for (NSURL *backupURL in feed.backupURLs) {
        BOOL connected = [self testConnection:backupURL timeout:self.connectionTimeout];

        if (connected) {
            feed.activeURL = backupURL;
            feed.status = RTSPFeedStatusFailedOver;
            [self.retryAttempts removeObjectForKey:feed.primaryURL.absoluteString];

            if ([self.delegate respondsToSelector:@selector(failoverManager:didFailoverFeed:toURL:)]) {
                [self.delegate failoverManager:self didFailoverFeed:feed toURL:backupURL];
            }

            NSLog(@"[Failover] Successfully failed over %@ to backup: %@", feed.name, backupURL.absoluteString);

            if (completion) completion(YES, backupURL);
            return;
        }
    }

    // All backups failed
    NSLog(@"[Failover] All backup URLs failed for %@", feed.name);

    if ([self.delegate respondsToSelector:@selector(failoverManager:didFailFeed:withError:)]) {
        NSError *error = [NSError errorWithDomain:@"RTSPFailoverManager"
                                            code:1003
                                        userInfo:@{NSLocalizedDescriptionKey: @"All backup URLs failed"}];
        [self.delegate failoverManager:self didFailFeed:feed withError:error];
    }

    if (completion) completion(NO, nil);
}

- (void)restoreToPrimaryFeed:(RTSPFeedConfig *)feed completion:(void (^)(BOOL))completion {
    BOOL connected = [self testConnection:feed.primaryURL timeout:self.connectionTimeout];

    if (connected) {
        feed.activeURL = feed.primaryURL;
        feed.status = RTSPFeedStatusHealthy;
        [self.retryAttempts removeObjectForKey:feed.primaryURL.absoluteString];

        if ([self.delegate respondsToSelector:@selector(failoverManager:didRestoreFeed:toPrimaryURL:)]) {
            [self.delegate failoverManager:self didRestoreFeed:feed toPrimaryURL:feed.primaryURL];
        }

        NSLog(@"[Failover] Restored %@ to primary URL", feed.name);

        if (completion) completion(YES);
    } else {
        NSLog(@"[Failover] Cannot restore %@ - primary still unavailable", feed.name);

        if (completion) completion(NO);
    }
}

- (void)startHealthMonitoring {
    if (self.healthCheckTimer) {
        return;
    }

    self.healthCheckTimer = [NSTimer scheduledTimerWithTimeInterval:self.healthCheckInterval
                                                             target:self
                                                           selector:@selector(performHealthChecks)
                                                           userInfo:nil
                                                            repeats:YES];

    NSLog(@"[Failover] Started health monitoring (interval: %.0fs)", self.healthCheckInterval);
}

- (void)stopHealthMonitoring {
    [self.healthCheckTimer invalidate];
    self.healthCheckTimer = nil;

    NSLog(@"[Failover] Stopped health monitoring");
}

- (void)performHealthChecks {
    for (RTSPFeedConfig *feed in self.allFeeds) {
        [self checkFeedHealth:feed completion:nil];
    }
}

- (void)dealloc {
    [self stopHealthMonitoring];
}

@end
