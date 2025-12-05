//
//  RTSPFeedMetadata.m
//  RTSP Rotator
//
//  Created by Jordan Koch on 10/29/25.
//

#import "RTSPFeedMetadata.h"

@implementation RTSPFeedMetadata

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithURL:(NSString *)url {
    return [self initWithURL:url displayName:nil];
}

- (instancetype)initWithURL:(NSString *)url displayName:(NSString *)displayName {
    self = [super init];
    if (self) {
        _url = url;
        _displayName = displayName;
        _enabled = YES;
        _healthStatus = RTSPFeedHealthStatusUnknown;
        _consecutiveFailures = 0;
        _totalAttempts = 0;
        _successfulConnections = 0;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _url = [coder decodeObjectOfClass:[NSString class] forKey:@"url"];
        _displayName = [coder decodeObjectOfClass:[NSString class] forKey:@"displayName"];
        _category = [coder decodeObjectOfClass:[NSString class] forKey:@"category"];
        _enabled = [coder decodeBoolForKey:@"enabled"];
        _healthStatus = [coder decodeIntegerForKey:@"healthStatus"];
        _lastSuccessfulConnection = [coder decodeObjectOfClass:[NSDate class] forKey:@"lastSuccessfulConnection"];
        _lastFailedConnection = [coder decodeObjectOfClass:[NSDate class] forKey:@"lastFailedConnection"];
        _consecutiveFailures = [coder decodeIntegerForKey:@"consecutiveFailures"];
        _totalAttempts = [coder decodeIntegerForKey:@"totalAttempts"];
        _successfulConnections = [coder decodeIntegerForKey:@"successfulConnections"];
        _notes = [coder decodeObjectOfClass:[NSString class] forKey:@"notes"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_url forKey:@"url"];
    [coder encodeObject:_displayName forKey:@"displayName"];
    [coder encodeObject:_category forKey:@"category"];
    [coder encodeBool:_enabled forKey:@"enabled"];
    [coder encodeInteger:_healthStatus forKey:@"healthStatus"];
    [coder encodeObject:_lastSuccessfulConnection forKey:@"lastSuccessfulConnection"];
    [coder encodeObject:_lastFailedConnection forKey:@"lastFailedConnection"];
    [coder encodeInteger:_consecutiveFailures forKey:@"consecutiveFailures"];
    [coder encodeInteger:_totalAttempts forKey:@"totalAttempts"];
    [coder encodeInteger:_successfulConnections forKey:@"successfulConnections"];
    [coder encodeObject:_notes forKey:@"notes"];
}

- (NSString *)effectiveDisplayName {
    return self.displayName ?: self.url;
}

- (CGFloat)uptimePercentage {
    if (self.totalAttempts == 0) {
        return 0.0;
    }
    return (CGFloat)self.successfulConnections / (CGFloat)self.totalAttempts * 100.0;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<RTSPFeedMetadata: %@ (%@) - %@ - Uptime: %.1f%%>",
            self.effectiveDisplayName,
            self.url,
            [self healthStatusString],
            [self uptimePercentage]];
}

- (NSString *)healthStatusString {
    switch (self.healthStatus) {
        case RTSPFeedHealthStatusUnknown: return @"Unknown";
        case RTSPFeedHealthStatusHealthy: return @"Healthy";
        case RTSPFeedHealthStatusDegraded: return @"Degraded";
        case RTSPFeedHealthStatusUnhealthy: return @"Unhealthy";
    }
}

@end
