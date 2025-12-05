//
//  RTSPScheduleManager.h
//  RTSP Rotator
//
//  Time-based scheduling for feed rotation profiles
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Schedule profile with specific feeds and settings
@interface RTSPScheduleProfile : NSObject <NSCoding, NSSecureCoding>
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray<NSString *> *feedURLs;
@property (nonatomic, assign) NSTimeInterval rotationInterval;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, strong) NSString *profileID;
@end

/// Time-based schedule rule
@interface RTSPScheduleRule : NSObject <NSCoding, NSSecureCoding>
@property (nonatomic, strong) NSString *ruleID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) RTSPScheduleProfile *profile;

// Time constraints
@property (nonatomic, strong, nullable) NSDateComponents *startTime; // Hour and minute
@property (nonatomic, strong, nullable) NSDateComponents *endTime;   // Hour and minute

// Day constraints (1=Sunday, 2=Monday, ..., 7=Saturday)
@property (nonatomic, strong, nullable) NSSet<NSNumber *> *daysOfWeek;

// Date constraints
@property (nonatomic, strong, nullable) NSDate *startDate;
@property (nonatomic, strong, nullable) NSDate *endDate;

@property (nonatomic, assign) BOOL enabled;

/// Check if rule is active at given date
- (BOOL)isActiveAtDate:(NSDate *)date;

@end

@class RTSPScheduleManager;

/// Schedule manager delegate
@protocol RTSPScheduleManagerDelegate <NSObject>
@optional
- (void)scheduleManager:(RTSPScheduleManager *)manager didActivateProfile:(RTSPScheduleProfile *)profile;
- (void)scheduleManager:(RTSPScheduleManager *)manager didDeactivateProfile:(RTSPScheduleProfile *)profile;
@end

/// Manages scheduled feed rotation profiles
@interface RTSPScheduleManager : NSObject

/// Shared instance
+ (instancetype)sharedManager;

/// Delegate for schedule events
@property (nonatomic, weak) id<RTSPScheduleManagerDelegate> delegate;

/// All profiles (read-only access)
- (NSArray<RTSPScheduleProfile *> *)profiles;

/// All rules (read-only access)
- (NSArray<RTSPScheduleRule *> *)rules;

/// Currently active profile
@property (nonatomic, strong, nullable, readonly) RTSPScheduleProfile *activeProfile;

/// Default profile (used when no rules match)
@property (nonatomic, strong, nullable) RTSPScheduleProfile *defaultProfile;

/// Enable automatic scheduling (default: YES)
@property (nonatomic, assign) BOOL schedulingEnabled;

/// Check interval in seconds (default: 60)
@property (nonatomic, assign) NSTimeInterval checkInterval;

/// Add profile
- (void)addProfile:(RTSPScheduleProfile *)profile;

/// Remove profile
- (void)removeProfile:(RTSPScheduleProfile *)profile;

/// Update profile
- (void)updateProfile:(RTSPScheduleProfile *)profile;

/// Get profile by ID
- (nullable RTSPScheduleProfile *)profileWithID:(NSString *)profileID;

/// Add schedule rule
- (void)addRule:(RTSPScheduleRule *)rule;

/// Remove rule
- (void)removeRule:(RTSPScheduleRule *)rule;

/// Update rule
- (void)updateRule:(RTSPScheduleRule *)rule;

/// Get rule by ID
- (nullable RTSPScheduleRule *)ruleWithID:(NSString *)ruleID;

/// Get active profile at specific time
- (nullable RTSPScheduleProfile *)activeProfileAtDate:(NSDate *)date;

/// Start schedule monitoring
- (void)startMonitoring;

/// Stop schedule monitoring
- (void)stopMonitoring;

/// Manually activate profile
- (void)activateProfile:(RTSPScheduleProfile *)profile;

/// Save schedules to disk
- (BOOL)saveSchedules;

/// Load schedules from disk
- (BOOL)loadSchedules;

@end

NS_ASSUME_NONNULL_END
