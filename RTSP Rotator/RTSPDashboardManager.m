//
//  RTSPDashboardManager.m
//  RTSP Rotator
//

#import "RTSPDashboardManager.h"

@implementation RTSPCameraConfig

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cameraID = [[NSUUID UUID] UUIDString];
        _enabled = YES;
        _isMuted = YES;
        _cameraType = @"RTSP";
        _gridRow = -1;
        _gridColumn = -1;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.cameraID forKey:@"cameraID"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.feedURL forKey:@"feedURL"];
    [coder encodeObject:self.username forKey:@"username"];
    [coder encodeObject:self.password forKey:@"password"];
    [coder encodeBool:self.enabled forKey:@"enabled"];
    [coder encodeBool:self.isMuted forKey:@"isMuted"];
    [coder encodeObject:self.location forKey:@"location"];
    [coder encodeObject:self.cameraType forKey:@"cameraType"];
    [coder encodeObject:self.customSettings forKey:@"customSettings"];
    [coder encodeInteger:self.gridRow forKey:@"gridRow"];
    [coder encodeInteger:self.gridColumn forKey:@"gridColumn"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _cameraID = [coder decodeObjectOfClass:[NSString class] forKey:@"cameraID"];
        _name = [coder decodeObjectOfClass:[NSString class] forKey:@"name"];
        _feedURL = [coder decodeObjectOfClass:[NSURL class] forKey:@"feedURL"];
        _username = [coder decodeObjectOfClass:[NSString class] forKey:@"username"];
        _password = [coder decodeObjectOfClass:[NSString class] forKey:@"password"];
        _enabled = [coder decodeBoolForKey:@"enabled"];
        _isMuted = [coder decodeBoolForKey:@"isMuted"];
        _location = [coder decodeObjectOfClass:[NSString class] forKey:@"location"];
        _cameraType = [coder decodeObjectOfClass:[NSString class] forKey:@"cameraType"];
        _customSettings = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"customSettings"];
        _gridRow = [coder decodeIntegerForKey:@"gridRow"];
        _gridColumn = [coder decodeIntegerForKey:@"gridColumn"];
    }
    return self;
}

@end

@implementation RTSPDashboard

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _dashboardID = [[NSUUID UUID] UUIDString];
        _cameras = @[];
        _layout = RTSPDashboardLayout3x3;
        _enabled = YES;
        _rotationInterval = 10.0;
        _autoRotate = NO;
        _showLabels = YES;
        _showTimestamp = YES;
        _syncPlayback = YES;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.dashboardID forKey:@"dashboardID"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.cameras forKey:@"cameras"];
    [coder encodeInteger:self.layout forKey:@"layout"];
    [coder encodeBool:self.enabled forKey:@"enabled"];
    [coder encodeDouble:self.rotationInterval forKey:@"rotationInterval"];
    [coder encodeBool:self.autoRotate forKey:@"autoRotate"];
    [coder encodeBool:self.showLabels forKey:@"showLabels"];
    [coder encodeBool:self.showTimestamp forKey:@"showTimestamp"];
    [coder encodeBool:self.syncPlayback forKey:@"syncPlayback"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _dashboardID = [coder decodeObjectOfClass:[NSString class] forKey:@"dashboardID"];
        _name = [coder decodeObjectOfClass:[NSString class] forKey:@"name"];
        _cameras = [coder decodeObjectOfClass:[NSArray class] forKey:@"cameras"];
        _layout = [coder decodeIntegerForKey:@"layout"];
        _enabled = [coder decodeBoolForKey:@"enabled"];
        _rotationInterval = [coder decodeDoubleForKey:@"rotationInterval"];
        _autoRotate = [coder decodeBoolForKey:@"autoRotate"];
        _showLabels = [coder decodeBoolForKey:@"showLabels"];
        _showTimestamp = [coder decodeBoolForKey:@"showTimestamp"];
        _syncPlayback = [coder decodeBoolForKey:@"syncPlayback"];
    }
    return self;
}

- (void)addCamera:(RTSPCameraConfig *)camera {
    if (![self canAddMoreCameras]) {
        NSLog(@"[Dashboard] Cannot add more cameras. Maximum for layout %ld reached.", (long)self.layout);
        return;
    }

    NSMutableArray *mutableCameras = [self.cameras mutableCopy];
    [mutableCameras addObject:camera];
    self.cameras = [mutableCameras copy];

    NSLog(@"[Dashboard] Added camera '%@' to dashboard '%@'", camera.name, self.name);
}

- (void)removeCamera:(RTSPCameraConfig *)camera {
    NSMutableArray *mutableCameras = [self.cameras mutableCopy];
    [mutableCameras removeObject:camera];
    self.cameras = [mutableCameras copy];

    NSLog(@"[Dashboard] Removed camera '%@' from dashboard '%@'", camera.name, self.name);
}

- (BOOL)canAddMoreCameras {
    return self.cameras.count < [self maxCamerasForLayout];
}

- (NSInteger)maxCamerasForLayout {
    return (NSInteger)self.layout;
}

@end

@interface RTSPDashboardManager ()
@property (nonatomic, strong) NSMutableArray<RTSPDashboard *> *allDashboards;
@property (nonatomic, strong) NSTimer *cycleTimer;
@property (nonatomic, assign) NSInteger currentDashboardIndex;
@end

@implementation RTSPDashboardManager

+ (instancetype)sharedManager {
    static RTSPDashboardManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RTSPDashboardManager alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _allDashboards = [NSMutableArray array];
        _currentDashboardIndex = 0;
        _autoCycleDashboards = NO;
        _dashboardCycleInterval = 300.0; // 5 minutes default

        [self loadDashboards];
    }
    return self;
}

- (NSArray<RTSPDashboard *> *)dashboards {
    return [self.allDashboards copy];
}

- (void)addDashboard:(RTSPDashboard *)dashboard {
    if (![self.allDashboards containsObject:dashboard]) {
        [self.allDashboards addObject:dashboard];
        [self saveDashboards];
        NSLog(@"[DashboardManager] Added dashboard: %@", dashboard.name);
    }
}

- (void)removeDashboard:(RTSPDashboard *)dashboard {
    [self.allDashboards removeObject:dashboard];
    [self saveDashboards];
    NSLog(@"[DashboardManager] Removed dashboard: %@", dashboard.name);
}

- (void)updateDashboard:(RTSPDashboard *)dashboard {
    [self saveDashboards];

    if ([self.delegate respondsToSelector:@selector(dashboardManager:didUpdateDashboard:)]) {
        [self.delegate dashboardManager:self didUpdateDashboard:dashboard];
    }

    NSLog(@"[DashboardManager] Updated dashboard: %@", dashboard.name);
}

- (RTSPDashboard *)dashboardWithID:(NSString *)dashboardID {
    for (RTSPDashboard *dashboard in self.allDashboards) {
        if ([dashboard.dashboardID isEqualToString:dashboardID]) {
            return dashboard;
        }
    }
    return nil;
}

- (void)activateDashboard:(RTSPDashboard *)dashboard {
    if (!dashboard.enabled) {
        NSLog(@"[DashboardManager] Cannot activate disabled dashboard: %@", dashboard.name);
        return;
    }

    RTSPDashboard *oldDashboard = self.activeDashboard;
    self.activeDashboard = dashboard;

    // Update current index
    NSInteger index = [self.allDashboards indexOfObject:dashboard];
    if (index != NSNotFound) {
        self.currentDashboardIndex = index;
    }

    if (oldDashboard && [self.delegate respondsToSelector:@selector(dashboardManager:didDeactivateDashboard:)]) {
        [self.delegate dashboardManager:self didDeactivateDashboard:oldDashboard];
    }

    if ([self.delegate respondsToSelector:@selector(dashboardManager:didActivateDashboard:)]) {
        [self.delegate dashboardManager:self didActivateDashboard:dashboard];
    }

    NSLog(@"[DashboardManager] Activated dashboard: %@", dashboard.name);
}

- (void)switchToNextDashboard {
    if (self.allDashboards.count == 0) return;

    NSInteger nextIndex = (self.currentDashboardIndex + 1) % self.allDashboards.count;
    RTSPDashboard *nextDashboard = self.allDashboards[nextIndex];

    // Skip disabled dashboards
    NSInteger attempts = 0;
    while (!nextDashboard.enabled && attempts < self.allDashboards.count) {
        nextIndex = (nextIndex + 1) % self.allDashboards.count;
        nextDashboard = self.allDashboards[nextIndex];
        attempts++;
    }

    if (nextDashboard.enabled) {
        [self activateDashboard:nextDashboard];
    }
}

- (void)switchToPreviousDashboard {
    if (self.allDashboards.count == 0) return;

    NSInteger prevIndex = (self.currentDashboardIndex - 1);
    if (prevIndex < 0) prevIndex = self.allDashboards.count - 1;

    RTSPDashboard *prevDashboard = self.allDashboards[prevIndex];

    // Skip disabled dashboards
    NSInteger attempts = 0;
    while (!prevDashboard.enabled && attempts < self.allDashboards.count) {
        prevIndex = prevIndex - 1;
        if (prevIndex < 0) prevIndex = self.allDashboards.count - 1;
        prevDashboard = self.allDashboards[prevIndex];
        attempts++;
    }

    if (prevDashboard.enabled) {
        [self activateDashboard:prevDashboard];
    }
}

- (void)startDashboardCycling {
    if (self.cycleTimer) {
        return;
    }

    self.cycleTimer = [NSTimer scheduledTimerWithTimeInterval:self.dashboardCycleInterval
                                                        target:self
                                                      selector:@selector(cycleDashboards)
                                                      userInfo:nil
                                                       repeats:YES];

    NSLog(@"[DashboardManager] Started dashboard cycling (interval: %.0fs)", self.dashboardCycleInterval);
}

- (void)stopDashboardCycling {
    [self.cycleTimer invalidate];
    self.cycleTimer = nil;

    NSLog(@"[DashboardManager] Stopped dashboard cycling");
}

- (void)cycleDashboards {
    [self switchToNextDashboard];
}

- (BOOL)saveDashboards {
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *appFolder = [appSupport stringByAppendingPathComponent:@"RTSP Rotator"];

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:appFolder]) {
        [fm createDirectoryAtPath:appFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *dashboardsPath = [appFolder stringByAppendingPathComponent:@"dashboards.dat"];

    NSError *error = nil;
    NSData *archiveData = [NSKeyedArchiver archivedDataWithRootObject:self.allDashboards requiringSecureCoding:YES error:&error];

    if (error) {
        NSLog(@"[DashboardManager] Failed to archive dashboards: %@", error);
        return NO;
    }

    BOOL success = [archiveData writeToFile:dashboardsPath atomically:YES];

    if (success) {
        NSLog(@"[DashboardManager] Saved %lu dashboards to disk", (unsigned long)self.allDashboards.count);
    } else {
        NSLog(@"[DashboardManager] Failed to save dashboards to disk");
    }

    return success;
}

- (BOOL)loadDashboards {
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dashboardsPath = [[appSupport stringByAppendingPathComponent:@"RTSP Rotator"] stringByAppendingPathComponent:@"dashboards.dat"];

    if (![[NSFileManager defaultManager] fileExistsAtPath:dashboardsPath]) {
        NSLog(@"[DashboardManager] No saved dashboards found, creating defaults");
        [self createDefaultDashboards];
        return NO;
    }

    NSError *error = nil;
    NSData *archiveData = [NSData dataWithContentsOfFile:dashboardsPath];

    NSSet *classes = [NSSet setWithArray:@[
        [NSArray class],
        [NSMutableArray class],
        [RTSPDashboard class],
        [RTSPCameraConfig class],
        [NSString class],
        [NSURL class],
        [NSDictionary class],
        [NSMutableDictionary class]
    ]];

    NSArray *loadedDashboards = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:archiveData error:&error];

    if (error) {
        NSLog(@"[DashboardManager] Failed to unarchive dashboards: %@", error);
        return NO;
    }

    self.allDashboards = [NSMutableArray arrayWithArray:loadedDashboards];

    NSLog(@"[DashboardManager] Loaded %lu dashboards from disk", (unsigned long)self.allDashboards.count);
    return YES;
}

- (NSArray<RTSPCameraConfig *> *)importCamerasFromURLs:(NSArray<NSString *> *)urls {
    NSMutableArray<RTSPCameraConfig *> *cameras = [NSMutableArray array];

    for (NSString *urlString in urls) {
        RTSPCameraConfig *camera = [[RTSPCameraConfig alloc] init];
        camera.feedURL = [NSURL URLWithString:urlString];

        // Try to extract camera name from URL
        NSString *lastComponent = [[camera.feedURL lastPathComponent] stringByDeletingPathExtension];
        camera.name = lastComponent.length > 0 ? lastComponent : [NSString stringWithFormat:@"Camera %lu", (unsigned long)(cameras.count + 1)];

        // Detect camera type
        if ([urlString containsString:@"rtsp://"]) {
            camera.cameraType = @"RTSP";
        } else if ([urlString containsString:@"http"]) {
            camera.cameraType = @"HTTP";
        } else {
            camera.cameraType = @"Unknown";
        }

        [cameras addObject:camera];
    }

    NSLog(@"[DashboardManager] Imported %lu cameras from URLs", (unsigned long)cameras.count);
    return [cameras copy];
}

- (void)createDefaultDashboards {
    // Create example dashboards for demonstration

    // Dashboard 1: External Cameras (12 cameras)
    RTSPDashboard *externalDash = [[RTSPDashboard alloc] init];
    externalDash.name = @"External Cameras";
    externalDash.layout = RTSPDashboardLayout4x3;

    for (int i = 1; i <= 12; i++) {
        RTSPCameraConfig *camera = [[RTSPCameraConfig alloc] init];
        camera.name = [NSString stringWithFormat:@"External Cam %d", i];
        camera.feedURL = [NSURL URLWithString:[NSString stringWithFormat:@"rtsp://example.com/external%d", i]];
        camera.location = @"Exterior";
        [externalDash addCamera:camera];
    }

    [self addDashboard:externalDash];

    // Dashboard 2: Internal Cameras (12 cameras)
    RTSPDashboard *internalDash = [[RTSPDashboard alloc] init];
    internalDash.name = @"Internal Cameras";
    internalDash.layout = RTSPDashboardLayout4x3;

    for (int i = 1; i <= 12; i++) {
        RTSPCameraConfig *camera = [[RTSPCameraConfig alloc] init];
        camera.name = [NSString stringWithFormat:@"Internal Cam %d", i];
        camera.feedURL = [NSURL URLWithString:[NSString stringWithFormat:@"rtsp://example.com/internal%d", i]];
        camera.location = @"Interior";
        [internalDash addCamera:camera];
    }

    [self addDashboard:internalDash];

    // Dashboard 3: Overflow/Additional Cameras (12 cameras)
    RTSPDashboard *additionalDash = [[RTSPDashboard alloc] init];
    additionalDash.name = @"Additional Cameras";
    additionalDash.layout = RTSPDashboardLayout4x3;

    for (int i = 1; i <= 12; i++) {
        RTSPCameraConfig *camera = [[RTSPCameraConfig alloc] init];
        camera.name = [NSString stringWithFormat:@"Additional Cam %d", i];
        camera.feedURL = [NSURL URLWithString:[NSString stringWithFormat:@"rtsp://example.com/additional%d", i]];
        [additionalDash addCamera:camera];
    }

    [self addDashboard:additionalDash];

    NSLog(@"[DashboardManager] Created 3 default dashboards (36 total cameras)");

    // Activate first dashboard
    if (self.allDashboards.count > 0) {
        [self activateDashboard:self.allDashboards[0]];
    }
}

- (void)dealloc {
    [self stopDashboardCycling];
}

@end
