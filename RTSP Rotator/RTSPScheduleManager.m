//
//  RTSPScheduleManager.m
//  RTSP Rotator
//

#import "RTSPScheduleManager.h"

@implementation RTSPScheduleProfile

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _profileID = [[NSUUID UUID] UUIDString];
        _enabled = YES;
        _rotationInterval = 10.0;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.feedURLs forKey:@"feedURLs"];
    [coder encodeDouble:self.rotationInterval forKey:@"rotationInterval"];
    [coder encodeBool:self.enabled forKey:@"enabled"];
    [coder encodeObject:self.profileID forKey:@"profileID"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _name = [coder decodeObjectOfClass:[NSString class] forKey:@"name"];
        _feedURLs = [coder decodeObjectOfClass:[NSArray class] forKey:@"feedURLs"];
        _rotationInterval = [coder decodeDoubleForKey:@"rotationInterval"];
        _enabled = [coder decodeBoolForKey:@"enabled"];
        _profileID = [coder decodeObjectOfClass:[NSString class] forKey:@"profileID"];
    }
    return self;
}

@end

@implementation RTSPScheduleRule

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _ruleID = [[NSUUID UUID] UUIDString];
        _enabled = YES;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.ruleID forKey:@"ruleID"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.profile forKey:@"profile"];
    [coder encodeObject:self.startTime forKey:@"startTime"];
    [coder encodeObject:self.endTime forKey:@"endTime"];
    [coder encodeObject:self.daysOfWeek forKey:@"daysOfWeek"];
    [coder encodeObject:self.startDate forKey:@"startDate"];
    [coder encodeObject:self.endDate forKey:@"endDate"];
    [coder encodeBool:self.enabled forKey:@"enabled"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _ruleID = [coder decodeObjectOfClass:[NSString class] forKey:@"ruleID"];
        _name = [coder decodeObjectOfClass:[NSString class] forKey:@"name"];
        _profile = [coder decodeObjectOfClass:[RTSPScheduleProfile class] forKey:@"profile"];
        _startTime = [coder decodeObjectOfClass:[NSDateComponents class] forKey:@"startTime"];
        _endTime = [coder decodeObjectOfClass:[NSDateComponents class] forKey:@"endTime"];
        _daysOfWeek = [coder decodeObjectOfClass:[NSSet class] forKey:@"daysOfWeek"];
        _startDate = [coder decodeObjectOfClass:[NSDate class] forKey:@"startDate"];
        _endDate = [coder decodeObjectOfClass:[NSDate class] forKey:@"endDate"];
        _enabled = [coder decodeBoolForKey:@"enabled"];
    }
    return self;
}

- (BOOL)isActiveAtDate:(NSDate *)date {
    if (!self.enabled) {
        return NO;
    }

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitWeekday) fromDate:date];

    // Check date range
    if (self.startDate && [date compare:self.startDate] == NSOrderedAscending) {
        return NO;
    }
    if (self.endDate && [date compare:self.endDate] == NSOrderedDescending) {
        return NO;
    }

    // Check day of week
    if (self.daysOfWeek && self.daysOfWeek.count > 0) {
        NSNumber *weekday = @(components.weekday);
        if (![self.daysOfWeek containsObject:weekday]) {
            return NO;
        }
    }

    // Check time range
    if (self.startTime && self.endTime) {
        NSInteger currentMinutes = components.hour * 60 + components.minute;
        NSInteger startMinutes = self.startTime.hour * 60 + self.startTime.minute;
        NSInteger endMinutes = self.endTime.hour * 60 + self.endTime.minute;

        if (endMinutes > startMinutes) {
            // Same day range (e.g., 9:00 AM - 5:00 PM)
            if (currentMinutes < startMinutes || currentMinutes > endMinutes) {
                return NO;
            }
        } else {
            // Crosses midnight (e.g., 10:00 PM - 6:00 AM)
            if (currentMinutes < startMinutes && currentMinutes > endMinutes) {
                return NO;
            }
        }
    }

    return YES;
}

@end

@interface RTSPScheduleManager ()
@property (nonatomic, strong) NSMutableArray<RTSPScheduleProfile *> *allProfiles;
@property (nonatomic, strong) NSMutableArray<RTSPScheduleRule *> *allRules;
@property (nonatomic, strong, nullable) RTSPScheduleProfile *activeProfile;
@property (nonatomic, strong) NSTimer *monitoringTimer;
@end

@implementation RTSPScheduleManager

+ (instancetype)sharedManager {
    static RTSPScheduleManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RTSPScheduleManager alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _allProfiles = [NSMutableArray array];
        _allRules = [NSMutableArray array];
        _schedulingEnabled = YES;
        _checkInterval = 60.0;

        [self loadSchedules];
    }
    return self;
}

- (NSArray<RTSPScheduleProfile *> *)profiles {
    return [self.allProfiles copy];
}

- (NSArray<RTSPScheduleRule *> *)rules {
    return [self.allRules copy];
}

- (void)addProfile:(RTSPScheduleProfile *)profile {
    if (![self.allProfiles containsObject:profile]) {
        [self.allProfiles addObject:profile];
        [self saveSchedules];

        NSLog(@"[Schedule] Added profile: %@", profile.name);
    }
}

- (void)removeProfile:(RTSPScheduleProfile *)profile {
    // Remove associated rules
    NSArray *rulesToRemove = [self.allRules filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(RTSPScheduleRule *rule, NSDictionary *bindings) {
        return [rule.profile.profileID isEqualToString:profile.profileID];
    }]];

    for (RTSPScheduleRule *rule in rulesToRemove) {
        [self.allRules removeObject:rule];
    }

    [self.allProfiles removeObject:profile];
    [self saveSchedules];

    NSLog(@"[Schedule] Removed profile: %@", profile.name);
}

- (void)updateProfile:(RTSPScheduleProfile *)profile {
    [self saveSchedules];
    NSLog(@"[Schedule] Updated profile: %@", profile.name);
}

- (RTSPScheduleProfile *)profileWithID:(NSString *)profileID {
    for (RTSPScheduleProfile *profile in self.allProfiles) {
        if ([profile.profileID isEqualToString:profileID]) {
            return profile;
        }
    }
    return nil;
}

- (void)addRule:(RTSPScheduleRule *)rule {
    if (![self.allRules containsObject:rule]) {
        [self.allRules addObject:rule];
        [self saveSchedules];

        NSLog(@"[Schedule] Added rule: %@", rule.name);
    }
}

- (void)removeRule:(RTSPScheduleRule *)rule {
    [self.allRules removeObject:rule];
    [self saveSchedules];

    NSLog(@"[Schedule] Removed rule: %@", rule.name);
}

- (void)updateRule:(RTSPScheduleRule *)rule {
    [self saveSchedules];
    NSLog(@"[Schedule] Updated rule: %@", rule.name);
}

- (RTSPScheduleRule *)ruleWithID:(NSString *)ruleID {
    for (RTSPScheduleRule *rule in self.allRules) {
        if ([rule.ruleID isEqualToString:ruleID]) {
            return rule;
        }
    }
    return nil;
}

- (RTSPScheduleProfile *)activeProfileAtDate:(NSDate *)date {
    // Find first matching rule
    for (RTSPScheduleRule *rule in self.allRules) {
        if ([rule isActiveAtDate:date]) {
            return rule.profile;
        }
    }

    // Return default if no rule matches
    return self.defaultProfile;
}

- (void)startMonitoring {
    if (self.monitoringTimer) {
        return;
    }

    self.monitoringTimer = [NSTimer scheduledTimerWithTimeInterval:self.checkInterval
                                                            target:self
                                                          selector:@selector(checkSchedule)
                                                          userInfo:nil
                                                           repeats:YES];

    // Check immediately
    [self checkSchedule];

    NSLog(@"[Schedule] Started monitoring (interval: %.0fs)", self.checkInterval);
}

- (void)stopMonitoring {
    [self.monitoringTimer invalidate];
    self.monitoringTimer = nil;

    NSLog(@"[Schedule] Stopped monitoring");
}

- (void)checkSchedule {
    if (!self.schedulingEnabled) {
        return;
    }

    RTSPScheduleProfile *newProfile = [self activeProfileAtDate:[NSDate date]];

    if (newProfile && ![newProfile.profileID isEqualToString:self.activeProfile.profileID]) {
        RTSPScheduleProfile *oldProfile = self.activeProfile;
        self.activeProfile = newProfile;

        if (oldProfile && [self.delegate respondsToSelector:@selector(scheduleManager:didDeactivateProfile:)]) {
            [self.delegate scheduleManager:self didDeactivateProfile:oldProfile];
        }

        if ([self.delegate respondsToSelector:@selector(scheduleManager:didActivateProfile:)]) {
            [self.delegate scheduleManager:self didActivateProfile:newProfile];
        }

        NSLog(@"[Schedule] Activated profile: %@", newProfile.name);
    }
}

- (void)activateProfile:(RTSPScheduleProfile *)profile {
    RTSPScheduleProfile *oldProfile = self.activeProfile;
    self.activeProfile = profile;

    if (oldProfile && [self.delegate respondsToSelector:@selector(scheduleManager:didDeactivateProfile:)]) {
        [self.delegate scheduleManager:self didDeactivateProfile:oldProfile];
    }

    if ([self.delegate respondsToSelector:@selector(scheduleManager:didActivateProfile:)]) {
        [self.delegate scheduleManager:self didActivateProfile:profile];
    }

    NSLog(@"[Schedule] Manually activated profile: %@", profile.name);
}

- (BOOL)saveSchedules {
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *appFolder = [appSupport stringByAppendingPathComponent:@"RTSP Rotator"];

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:appFolder]) {
        [fm createDirectoryAtPath:appFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *schedulesPath = [appFolder stringByAppendingPathComponent:@"schedules.dat"];

    NSDictionary *data = @{
        @"profiles": self.allProfiles,
        @"rules": self.allRules,
        @"defaultProfile": self.defaultProfile ?: [NSNull null]
    };

    NSError *error = nil;
    NSData *archiveData = [NSKeyedArchiver archivedDataWithRootObject:data requiringSecureCoding:YES error:&error];

    if (error) {
        NSLog(@"[Schedule] Failed to archive schedules: %@", error);
        return NO;
    }

    BOOL success = [archiveData writeToFile:schedulesPath atomically:YES];

    if (success) {
        NSLog(@"[Schedule] Saved schedules to disk");
    } else {
        NSLog(@"[Schedule] Failed to save schedules to disk");
    }

    return success;
}

- (BOOL)loadSchedules {
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *schedulesPath = [[appSupport stringByAppendingPathComponent:@"RTSP Rotator"] stringByAppendingPathComponent:@"schedules.dat"];

    if (![[NSFileManager defaultManager] fileExistsAtPath:schedulesPath]) {
        NSLog(@"[Schedule] No saved schedules found");
        return NO;
    }

    NSError *error = nil;
    NSData *archiveData = [NSData dataWithContentsOfFile:schedulesPath];

    NSSet *classes = [NSSet setWithArray:@[[NSDictionary class], [NSArray class], [RTSPScheduleProfile class], [RTSPScheduleRule class], [NSString class], [NSDateComponents class], [NSDate class], [NSSet class], [NSNumber class], [NSNull class]]];
    NSDictionary *data = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:archiveData error:&error];

    if (error) {
        NSLog(@"[Schedule] Failed to unarchive schedules: %@", error);
        return NO;
    }

    self.allProfiles = [NSMutableArray arrayWithArray:data[@"profiles"]];
    self.allRules = [NSMutableArray arrayWithArray:data[@"rules"]];

    id defaultProfile = data[@"defaultProfile"];
    if (defaultProfile && ![defaultProfile isKindOfClass:[NSNull class]]) {
        self.defaultProfile = defaultProfile;
    }

    NSLog(@"[Schedule] Loaded schedules from disk");
    return YES;
}

- (void)dealloc {
    [self stopMonitoring];
}

@end
