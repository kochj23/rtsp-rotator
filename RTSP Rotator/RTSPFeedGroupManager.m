//
//  RTSPFeedGroupManager.m
//  RTSP Rotator
//

#import "RTSPFeedGroupManager.h"

@implementation RTSPFeedGroup

+ (BOOL)supportsSecureCoding { return YES; }

- (instancetype)init {
    if (self = [super init]) {
        _groupID = [[NSUUID UUID] UUIDString];
        _enabled = YES;
        _rotationInterval = 10.0;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.groupID forKey:@"groupID"];
    [coder encodeObject:self.feedURLs forKey:@"feedURLs"];
    [coder encodeDouble:self.rotationInterval forKey:@"rotationInterval"];
    [coder encodeBool:self.enabled forKey:@"enabled"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        _name = [coder decodeObjectOfClass:[NSString class] forKey:@"name"];
        _groupID = [coder decodeObjectOfClass:[NSString class] forKey:@"groupID"];
        _feedURLs = [coder decodeObjectOfClass:[NSArray class] forKey:@"feedURLs"];
        _rotationInterval = [coder decodeDoubleForKey:@"rotationInterval"];
        _enabled = [coder decodeBoolForKey:@"enabled"];
    }
    return self;
}

@end

@interface RTSPFeedGroupManager ()
@property (nonatomic, strong) NSMutableArray<RTSPFeedGroup *> *allGroups;
@end

@implementation RTSPFeedGroupManager

+ (instancetype)sharedManager {
    static RTSPFeedGroupManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RTSPFeedGroupManager alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        _allGroups = [NSMutableArray array];
        [self loadGroups];
    }
    return self;
}

- (NSArray<RTSPFeedGroup *> *)groups {
    return [self.allGroups copy];
}

- (void)addGroup:(RTSPFeedGroup *)group {
    [self.allGroups addObject:group];
    [self saveGroups];
    NSLog(@"[Groups] Added group: %@", group.name);
}

- (void)removeGroup:(RTSPFeedGroup *)group {
    [self.allGroups removeObject:group];
    [self saveGroups];
    NSLog(@"[Groups] Removed group: %@", group.name);
}

- (void)activateGroup:(RTSPFeedGroup *)group {
    self.activeGroup = group;
    NSLog(@"[Groups] Activated group: %@", group.name);
}

- (RTSPFeedGroup *)groupWithID:(NSString *)groupID {
    for (RTSPFeedGroup *group in self.allGroups) {
        if ([group.groupID isEqualToString:groupID]) return group;
    }
    return nil;
}

- (BOOL)saveGroups {
    NSString *path = [[[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"RTSP Rotator"] stringByAppendingPathComponent:@"groups.dat"];
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.allGroups requiringSecureCoding:YES error:&error];
    return error ? NO : [data writeToFile:path atomically:YES];
}

- (BOOL)loadGroups {
    NSString *path = [[[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"RTSP Rotator"] stringByAppendingPathComponent:@"groups.dat"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) return NO;
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSError *error = nil;
    NSArray *loaded = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[[NSArray class], [RTSPFeedGroup class], [NSString class], [NSURL class]]] fromData:data error:&error];
    if (!error) self.allGroups = [NSMutableArray arrayWithArray:loaded];
    return !error;
}

@end
