//
//  RTSPFeedMetadata.h
//  RTSP Rotator
//
//  Created by Jordan Koch on 10/29/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Feed health status
typedef NS_ENUM(NSInteger, RTSPFeedHealthStatus) {
    RTSPFeedHealthStatusUnknown,        ///< Not yet tested
    RTSPFeedHealthStatusHealthy,        ///< Currently working
    RTSPFeedHealthStatusDegraded,       ///< Working but with issues
    RTSPFeedHealthStatusUnhealthy       ///< Not working
};

/// Represents metadata for an RTSP feed
@interface RTSPFeedMetadata : NSObject <NSCoding, NSSecureCoding>

/// The RTSP URL
@property (nonatomic, strong) NSString *url;

/// Custom display name (optional)
@property (nonatomic, strong, nullable) NSString *displayName;

/// Category/group name (optional)
@property (nonatomic, strong, nullable) NSString *category;

/// Whether this feed is enabled
@property (nonatomic, assign) BOOL enabled;

/// Health status
@property (nonatomic, assign) RTSPFeedHealthStatus healthStatus;

/// Last successful connection timestamp
@property (nonatomic, strong, nullable) NSDate *lastSuccessfulConnection;

/// Last failed connection timestamp
@property (nonatomic, strong, nullable) NSDate *lastFailedConnection;

/// Number of consecutive failures
@property (nonatomic, assign) NSInteger consecutiveFailures;

/// Total connection attempts
@property (nonatomic, assign) NSInteger totalAttempts;

/// Total successful connections
@property (nonatomic, assign) NSInteger successfulConnections;

/// Notes/description
@property (nonatomic, strong, nullable) NSString *notes;

/// Initialize with URL
- (instancetype)initWithURL:(NSString *)url;

/// Initialize with URL and display name
- (instancetype)initWithURL:(NSString *)url displayName:(nullable NSString *)displayName;

/// Get effective display name (custom name or URL)
- (NSString *)effectiveDisplayName;

/// Calculate uptime percentage
- (CGFloat)uptimePercentage;

@end

NS_ASSUME_NONNULL_END
