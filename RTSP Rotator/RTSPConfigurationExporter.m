//
//  RTSPConfigurationExporter.m
//  RTSP Rotator
//
//  Cross-platform configuration export/import system
//

#import "RTSPConfigurationExporter.h"
#import "RTSPPreferencesController.h"
#import "RTSPBookmarkManager.h"
#import "RTSPAPIServer.h"
#import "RTSPFailoverManager.h"
#import "RTSPEventLogger.h"
#import "RTSPCloudStorage.h"
#import "RTSPTransitionController.h"
#import "RTSPAudioMonitor.h"
#import "RTSPMotionDetector.h"
#import "RTSPSmartAlerts.h"
#import "RTSPDashboardManager.h"
#import "RTSPCameraTypeManager.h"
#import "RTSPUniFiProtectAdapter.h"

@interface NSDate (ISO8601)
- (NSString *)ISO8601String;
@end

@implementation NSDate (ISO8601)
- (NSString *)ISO8601String {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    });
    return [formatter stringFromDate:self];
}
@end

@interface RTSPConfigurationExporter ()
@property (nonatomic, strong, nullable) NSTimer *autoSyncTimer;
@property (nonatomic, assign) BOOL isSyncing;
@end

@implementation RTSPConfigurationExporter

#pragma mark - Singleton

+ (instancetype)sharedExporter {
    static RTSPConfigurationExporter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RTSPConfigurationExporter alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _autoSyncEnabled = NO;
        _autoSyncInterval = 300.0; // 5 minutes
        _autoSyncUploadMethod = @"POST";
        _isSyncing = NO;

        // Load auto-sync settings
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _autoSyncEnabled = [defaults boolForKey:@"ConfigAutoSyncEnabled"];
        _autoSyncInterval = [defaults doubleForKey:@"ConfigAutoSyncInterval"] ?: 300.0;
        _autoSyncURL = [defaults stringForKey:@"ConfigAutoSyncURL"];
        _autoSyncUploadMethod = [defaults stringForKey:@"ConfigAutoSyncMethod"] ?: @"POST";

        if (_autoSyncEnabled && _autoSyncURL) {
            [self startAutoSync];
        }
    }
    return self;
}

- (void)dealloc {
    [self stopAutoSync];
}

#pragma mark - Default Paths

- (NSString *)defaultExportPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *appSupport = paths.firstObject;
    NSString *appFolder = [appSupport stringByAppendingPathComponent:@"RTSP Rotator"];

    // Create directory if needed
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:appFolder]) {
        [fm createDirectoryAtPath:appFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }

    return [appFolder stringByAppendingPathComponent:@"config.json"];
}

#pragma mark - JSON Generation

- (NSDictionary *)generateConfigurationDictionary {
    NSMutableDictionary *config = [NSMutableDictionary dictionary];

    // Metadata
    config[@"version"] = @"2.1";
    config[@"exportDate"] = [[NSDate date] ISO8601String];
    config[@"platform"] = @"macOS";

    // Basic Configuration
    RTSPConfigurationManager *configManager = [RTSPConfigurationManager sharedManager];
    NSMutableDictionary *basicConfig = [NSMutableDictionary dictionary];
    basicConfig[@"rotationInterval"] = @(configManager.rotationInterval);
    basicConfig[@"startMuted"] = @(configManager.startMuted);
    basicConfig[@"autoSkipFailedFeeds"] = @(configManager.autoSkipFailedFeeds);
    basicConfig[@"retryAttempts"] = @(configManager.retryAttempts);
    config[@"basic"] = basicConfig;

    // Display Settings
    NSMutableDictionary *displayConfig = [NSMutableDictionary dictionary];
    displayConfig[@"displayIndex"] = @(configManager.displayIndex);
    displayConfig[@"gridLayoutEnabled"] = @(configManager.gridLayoutEnabled);
    displayConfig[@"gridRows"] = @(configManager.gridRows);
    displayConfig[@"gridColumns"] = @(configManager.gridColumns);
    config[@"display"] = displayConfig;

    // OSD Settings
    NSMutableDictionary *osdConfig = [NSMutableDictionary dictionary];
    osdConfig[@"enabled"] = @(configManager.osdEnabled);
    osdConfig[@"duration"] = @(configManager.osdDuration);
    osdConfig[@"position"] = @(configManager.osdPosition);
    config[@"osd"] = osdConfig;

    // Recording Settings
    NSMutableDictionary *recordingConfig = [NSMutableDictionary dictionary];
    recordingConfig[@"autoSnapshotsEnabled"] = @(configManager.autoSnapshotsEnabled);
    recordingConfig[@"snapshotInterval"] = @(configManager.snapshotInterval);
    if (configManager.snapshotDirectory) {
        recordingConfig[@"snapshotDirectory"] = configManager.snapshotDirectory;
    }
    config[@"recording"] = recordingConfig;

    // Feeds (with metadata)
    NSMutableArray *feeds = [NSMutableArray array];
    for (RTSPFeedMetadata *metadata in configManager.manualFeedMetadata) {
        NSMutableDictionary *feed = [NSMutableDictionary dictionary];
        feed[@"url"] = metadata.url; // url is already NSString
        feed[@"name"] = metadata.displayName;
        feed[@"enabled"] = @(metadata.enabled);
        if (metadata.category) feed[@"category"] = metadata.category;
        [feeds addObject:feed];
    }
    config[@"feeds"] = feeds;

    // Bookmarks
    RTSPBookmarkManager *bookmarkManager = [RTSPBookmarkManager sharedManager];
    NSMutableArray *bookmarks = [NSMutableArray array];
    for (RTSPBookmark *bookmark in bookmarkManager.bookmarks) {
        NSMutableDictionary *bm = [NSMutableDictionary dictionary];
        bm[@"name"] = bookmark.name;
        bm[@"feedURL"] = bookmark.feedURL.absoluteString;
        bm[@"hotkey"] = @(bookmark.hotkey);
        bm[@"feedIndex"] = @(bookmark.feedIndex);
        [bookmarks addObject:bm];
    }
    config[@"bookmarks"] = bookmarks;
    config[@"bookmarksEnabled"] = @(bookmarkManager.hotkeysEnabled);

    // Transitions
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *transitions = [NSMutableDictionary dictionary];
    transitions[@"type"] = @([defaults integerForKey:@"TransitionType"]);
    transitions[@"duration"] = @([defaults doubleForKey:@"TransitionDuration"] ?: 0.5);
    config[@"transitions"] = transitions;

    // API Server
    RTSPAPIServer *apiServer = [RTSPAPIServer sharedServer];
    NSMutableDictionary *api = [NSMutableDictionary dictionary];
    api[@"enabled"] = @(apiServer.enabled);
    api[@"port"] = @(apiServer.port);
    api[@"requireAPIKey"] = @(apiServer.requireAPIKey);
    if (apiServer.requireAPIKey && apiServer.apiKey) {
        api[@"apiKey"] = apiServer.apiKey;
    }
    config[@"api"] = api;

    // Failover
    RTSPFailoverManager *failover = [RTSPFailoverManager sharedManager];
    NSMutableDictionary *failoverConfig = [NSMutableDictionary dictionary];
    failoverConfig[@"enabled"] = @(failover.autoFailoverEnabled);
    failoverConfig[@"healthCheckInterval"] = @(failover.healthCheckInterval);
    failoverConfig[@"connectionTimeout"] = @(failover.connectionTimeout);
    failoverConfig[@"maxRetryAttempts"] = @(failover.maxRetryAttempts);
    config[@"failover"] = failoverConfig;

    // Monitoring Features
    NSMutableDictionary *monitoring = [NSMutableDictionary dictionary];
    monitoring[@"audioMonitorEnabled"] = @([defaults boolForKey:@"AudioMonitorEnabled"]);
    monitoring[@"audioMonitorThreshold"] = @([defaults doubleForKey:@"AudioMonitorThreshold"] ?: 0.8);
    monitoring[@"motionDetectionEnabled"] = @([defaults boolForKey:@"MotionDetectionEnabled"]);
    monitoring[@"motionSensitivity"] = @([defaults doubleForKey:@"MotionSensitivity"] ?: 0.5);
    monitoring[@"smartAlertsEnabled"] = @([defaults boolForKey:@"SmartAlertsEnabled"]);
    monitoring[@"smartAlertsThreshold"] = @([defaults doubleForKey:@"SmartAlertsThreshold"] ?: 0.7);
    config[@"monitoring"] = monitoring;

    // Cloud Storage
    RTSPCloudStorage *cloud = [RTSPCloudStorage sharedManager];
    NSMutableDictionary *cloudConfig = [NSMutableDictionary dictionary];
    cloudConfig[@"enabled"] = @(cloud.autoUploadEnabled);
    cloudConfig[@"provider"] = @(cloud.provider);
    cloudConfig[@"retentionDays"] = @(cloud.retentionDays);
    config[@"cloud"] = cloudConfig;

    // Event Logging
    RTSPEventLogger *logger = [RTSPEventLogger sharedLogger];
    NSMutableDictionary *logging = [NSMutableDictionary dictionary];
    logging[@"enabled"] = @(logger.loggingEnabled);
    logging[@"maxEvents"] = @(logger.maxEventsInMemory);
    config[@"eventLogging"] = logging;

    // Full Screen
    NSMutableDictionary *fullScreen = [NSMutableDictionary dictionary];
    fullScreen[@"showControlsOnHover"] = @([defaults boolForKey:@"FullScreenShowControls"] ?: YES);
    fullScreen[@"controlsFadeDelay"] = @([defaults doubleForKey:@"FullScreenFadeDelay"] ?: 3.0);
    config[@"fullScreen"] = fullScreen;

    NSLog(@"[ConfigExporter] Generated configuration dictionary with %lu top-level keys", (unsigned long)config.count);
    return config;
}

- (NSData *)generateConfigurationJSON:(NSError **)error {
    NSDictionary *config = [self generateConfigurationDictionary];

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:config
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:error];

    if (!jsonData && error) {
        NSLog(@"[ConfigExporter] ERROR: Failed to generate JSON: %@", (*error).localizedDescription);
    } else {
        NSLog(@"[ConfigExporter] Generated JSON data: %lu bytes", (unsigned long)jsonData.length);
    }

    return jsonData;
}

#pragma mark - Export to File

- (void)exportConfigurationToFile:(NSString *)filePath
                       completion:(RTSPConfigurationExportCompletion)completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;

        // Use default path if none specified
        NSString *exportPath = filePath ?: [self defaultExportPath];

        // Generate JSON
        NSData *jsonData = [self generateConfigurationJSON:&error];
        if (!jsonData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil, error);
            });
            return;
        }

        // Write to file
        BOOL success = [jsonData writeToFile:exportPath options:NSDataWritingAtomic error:&error];

        if (success) {
            NSLog(@"[ConfigExporter] ✓ Configuration exported to: %@", exportPath);
        } else {
            NSLog(@"[ConfigExporter] ERROR: Failed to write file: %@", error.localizedDescription);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, exportPath, error);
        });
    });
}

#pragma mark - Import from File

- (void)importConfigurationFromFile:(NSString *)filePath
                              merge:(BOOL)merge
                         completion:(RTSPConfigurationImportCompletion)completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;

        // Read file
        NSData *jsonData = [NSData dataWithContentsOfFile:filePath options:0 error:&error];
        if (!jsonData) {
            NSLog(@"[ConfigExporter] ERROR: Failed to read file: %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
            return;
        }

        // Parse JSON
        id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (!jsonObject || ![jsonObject isKindOfClass:[NSDictionary class]]) {
            NSLog(@"[ConfigExporter] ERROR: Invalid JSON format");
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
            return;
        }

        // Apply configuration
        BOOL success = [self applyConfigurationFromDictionary:(NSDictionary *)jsonObject
                                                        merge:merge
                                                        error:&error];

        if (success) {
            NSLog(@"[ConfigExporter] ✓ Configuration imported from: %@", filePath);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, error);
        });
    });
}

#pragma mark - Import from URL

- (void)importConfigurationFromURL:(NSString *)urlString
                             merge:(BOOL)merge
                        completion:(RTSPConfigurationImportCompletion)completion {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        NSError *error = [NSError errorWithDomain:@"RTSPConfigurationExporter"
                                             code:1001
                                         userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
        completion(NO, error);
        return;
    }

    NSLog(@"[ConfigExporter] Importing configuration from URL: %@", urlString);

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[ConfigExporter] ERROR: Failed to fetch URL: %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            NSError *statusError = [NSError errorWithDomain:@"RTSPConfigurationExporter"
                                                       code:httpResponse.statusCode
                                                   userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP %ld", (long)httpResponse.statusCode]}];
            NSLog(@"[ConfigExporter] ERROR: HTTP %ld", (long)httpResponse.statusCode);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, statusError);
            });
            return;
        }

        // Parse JSON
        NSError *jsonError = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (!jsonObject || ![jsonObject isKindOfClass:[NSDictionary class]]) {
            NSLog(@"[ConfigExporter] ERROR: Invalid JSON format from URL");
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, jsonError);
            });
            return;
        }

        // Apply configuration
        BOOL success = [self applyConfigurationFromDictionary:(NSDictionary *)jsonObject
                                                        merge:merge
                                                        error:&jsonError];

        if (success) {
            NSLog(@"[ConfigExporter] ✓ Configuration imported from URL");
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, jsonError);
        });
    }];

    [task resume];
}

#pragma mark - Upload to URL

- (void)uploadConfigurationToURL:(NSString *)urlString
                          method:(NSString *)method
                      completion:(RTSPConfigurationUploadCompletion)completion {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        NSError *error = [NSError errorWithDomain:@"RTSPConfigurationExporter"
                                             code:1001
                                         userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
        completion(NO, nil, error);
        return;
    }

    NSLog(@"[ConfigExporter] Uploading configuration to URL: %@ (method: %@)", urlString, method);

    // Generate JSON
    NSError *jsonError = nil;
    NSData *jsonData = [self generateConfigurationJSON:&jsonError];
    if (!jsonData) {
        completion(NO, nil, jsonError);
        return;
    }

    // Create request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = method;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = jsonData;

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[ConfigExporter] ERROR: Failed to upload: %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil, error);
            });
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        BOOL success = (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300);

        if (success) {
            NSLog(@"[ConfigExporter] ✓ Configuration uploaded successfully (HTTP %ld)", (long)httpResponse.statusCode);
        } else {
            NSLog(@"[ConfigExporter] ERROR: Upload failed (HTTP %ld)", (long)httpResponse.statusCode);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                completion(YES, urlString, nil);
            } else {
                NSError *statusError = [NSError errorWithDomain:@"RTSPConfigurationExporter"
                                                           code:httpResponse.statusCode
                                                       userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP %ld", (long)httpResponse.statusCode]}];
                completion(NO, nil, statusError);
            }
        });
    }];

    [task resume];
}

#pragma mark - Configuration Application

- (BOOL)applyConfigurationFromDictionary:(NSDictionary *)dictionary
                                   merge:(BOOL)merge
                                   error:(NSError **)error {
    @try {
        NSLog(@"[ConfigExporter] Applying configuration (merge: %@)", merge ? @"YES" : @"NO");

        RTSPConfigurationManager *configManager = [RTSPConfigurationManager sharedManager];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        // Basic Configuration
        if (dictionary[@"basic"]) {
            NSDictionary *basic = dictionary[@"basic"];
            if (basic[@"rotationInterval"]) configManager.rotationInterval = [basic[@"rotationInterval"] doubleValue];
            if (basic[@"startMuted"]) configManager.startMuted = [basic[@"startMuted"] boolValue];
            if (basic[@"autoSkipFailedFeeds"]) configManager.autoSkipFailedFeeds = [basic[@"autoSkipFailedFeeds"] boolValue];
            if (basic[@"retryAttempts"]) configManager.retryAttempts = [basic[@"retryAttempts"] integerValue];
        }

        // Display Settings
        if (dictionary[@"display"]) {
            NSDictionary *display = dictionary[@"display"];
            if (display[@"displayIndex"]) configManager.displayIndex = [display[@"displayIndex"] integerValue];
            if (display[@"gridLayoutEnabled"]) configManager.gridLayoutEnabled = [display[@"gridLayoutEnabled"] boolValue];
            if (display[@"gridRows"]) configManager.gridRows = [display[@"gridRows"] integerValue];
            if (display[@"gridColumns"]) configManager.gridColumns = [display[@"gridColumns"] integerValue];
        }

        // OSD Settings
        if (dictionary[@"osd"]) {
            NSDictionary *osd = dictionary[@"osd"];
            if (osd[@"enabled"]) configManager.osdEnabled = [osd[@"enabled"] boolValue];
            if (osd[@"duration"]) configManager.osdDuration = [osd[@"duration"] doubleValue];
            if (osd[@"position"]) configManager.osdPosition = [osd[@"position"] integerValue];
        }

        // Recording Settings
        if (dictionary[@"recording"]) {
            NSDictionary *recording = dictionary[@"recording"];
            if (recording[@"autoSnapshotsEnabled"]) configManager.autoSnapshotsEnabled = [recording[@"autoSnapshotsEnabled"] boolValue];
            if (recording[@"snapshotInterval"]) configManager.snapshotInterval = [recording[@"snapshotInterval"] doubleValue];
            if (recording[@"snapshotDirectory"]) configManager.snapshotDirectory = recording[@"snapshotDirectory"];
        }

        // Feeds
        if (dictionary[@"feeds"] && !merge) {
            NSArray *feedsArray = dictionary[@"feeds"];
            NSMutableArray *metadata = [NSMutableArray array];
            for (NSDictionary *feedDict in feedsArray) {
                RTSPFeedMetadata *meta = [[RTSPFeedMetadata alloc] init];
                meta.url = feedDict[@"url"]; // url is NSString
                meta.displayName = feedDict[@"name"];
                meta.enabled = [feedDict[@"enabled"] boolValue];
                meta.category = feedDict[@"category"];
                [metadata addObject:meta];
            }
            configManager.manualFeedMetadata = metadata;
        }

        // Bookmarks
        if (dictionary[@"bookmarks"] && !merge) {
            NSArray *bookmarksArray = dictionary[@"bookmarks"];
            NSMutableArray *bookmarks = [NSMutableArray array];
            for (NSDictionary *bmDict in bookmarksArray) {
                RTSPBookmark *bookmark = [[RTSPBookmark alloc] init];
                bookmark.name = bmDict[@"name"];
                bookmark.feedURL = [NSURL URLWithString:bmDict[@"feedURL"]];
                bookmark.hotkey = [bmDict[@"hotkey"] integerValue];
                bookmark.feedIndex = [bmDict[@"feedIndex"] integerValue];
                [bookmarks addObject:bookmark];
            }
            // Note: Would need to expose setBookmarks: method on RTSPBookmarkManager
            // For now, bookmarks would need to be added individually via addBookmark:
        }

        if (dictionary[@"bookmarksEnabled"]) {
            [RTSPBookmarkManager sharedManager].hotkeysEnabled = [dictionary[@"bookmarksEnabled"] boolValue];
        }

        // Transitions
        if (dictionary[@"transitions"]) {
            NSDictionary *trans = dictionary[@"transitions"];
            if (trans[@"type"]) [defaults setInteger:[trans[@"type"] integerValue] forKey:@"TransitionType"];
            if (trans[@"duration"]) [defaults setDouble:[trans[@"duration"] doubleValue] forKey:@"TransitionDuration"];
        }

        // API Server
        if (dictionary[@"api"]) {
            NSDictionary *api = dictionary[@"api"];
            RTSPAPIServer *apiServer = [RTSPAPIServer sharedServer];
            if (api[@"enabled"]) apiServer.enabled = [api[@"enabled"] boolValue];
            if (api[@"port"]) apiServer.port = [api[@"port"] integerValue];
            if (api[@"requireAPIKey"]) apiServer.requireAPIKey = [api[@"requireAPIKey"] boolValue];
            if (api[@"apiKey"]) apiServer.apiKey = api[@"apiKey"];
        }

        // Failover
        if (dictionary[@"failover"]) {
            NSDictionary *failover = dictionary[@"failover"];
            RTSPFailoverManager *manager = [RTSPFailoverManager sharedManager];
            if (failover[@"enabled"]) manager.autoFailoverEnabled = [failover[@"enabled"] boolValue];
            if (failover[@"healthCheckInterval"]) manager.healthCheckInterval = [failover[@"healthCheckInterval"] doubleValue];
            if (failover[@"connectionTimeout"]) manager.connectionTimeout = [failover[@"connectionTimeout"] doubleValue];
            if (failover[@"maxRetryAttempts"]) manager.maxRetryAttempts = [failover[@"maxRetryAttempts"] integerValue];
        }

        // Monitoring
        if (dictionary[@"monitoring"]) {
            NSDictionary *monitoring = dictionary[@"monitoring"];
            if (monitoring[@"audioMonitorEnabled"]) [defaults setBool:[monitoring[@"audioMonitorEnabled"] boolValue] forKey:@"AudioMonitorEnabled"];
            if (monitoring[@"audioMonitorThreshold"]) [defaults setDouble:[monitoring[@"audioMonitorThreshold"] doubleValue] forKey:@"AudioMonitorThreshold"];
            if (monitoring[@"motionDetectionEnabled"]) [defaults setBool:[monitoring[@"motionDetectionEnabled"] boolValue] forKey:@"MotionDetectionEnabled"];
            if (monitoring[@"motionSensitivity"]) [defaults setDouble:[monitoring[@"motionSensitivity"] doubleValue] forKey:@"MotionSensitivity"];
            if (monitoring[@"smartAlertsEnabled"]) [defaults setBool:[monitoring[@"smartAlertsEnabled"] boolValue] forKey:@"SmartAlertsEnabled"];
            if (monitoring[@"smartAlertsThreshold"]) [defaults setDouble:[monitoring[@"smartAlertsThreshold"] doubleValue] forKey:@"SmartAlertsThreshold"];
        }

        // Cloud Storage
        if (dictionary[@"cloud"]) {
            NSDictionary *cloud = dictionary[@"cloud"];
            RTSPCloudStorage *storage = [RTSPCloudStorage sharedManager];
            if (cloud[@"enabled"]) storage.autoUploadEnabled = [cloud[@"enabled"] boolValue];
            if (cloud[@"provider"]) storage.provider = [cloud[@"provider"] integerValue];
            if (cloud[@"retentionDays"]) storage.retentionDays = [cloud[@"retentionDays"] integerValue];
        }

        // Event Logging
        if (dictionary[@"eventLogging"]) {
            NSDictionary *logging = dictionary[@"eventLogging"];
            RTSPEventLogger *logger = [RTSPEventLogger sharedLogger];
            if (logging[@"enabled"]) logger.loggingEnabled = [logging[@"enabled"] boolValue];
            if (logging[@"maxEvents"]) logger.maxEventsInMemory = [logging[@"maxEvents"] integerValue];
        }

        // Full Screen
        if (dictionary[@"fullScreen"]) {
            NSDictionary *fs = dictionary[@"fullScreen"];
            if (fs[@"showControlsOnHover"]) [defaults setBool:[fs[@"showControlsOnHover"] boolValue] forKey:@"FullScreenShowControls"];
            if (fs[@"controlsFadeDelay"]) [defaults setDouble:[fs[@"controlsFadeDelay"] doubleValue] forKey:@"FullScreenFadeDelay"];
        }

        // Save all changes
        [configManager save];
        [defaults synchronize];

        NSLog(@"[ConfigExporter] ✓ Configuration applied successfully");
        return YES;

    } @catch (NSException *exception) {
        NSLog(@"[ConfigExporter] ERROR: Exception applying configuration: %@", exception);
        if (error) {
            *error = [NSError errorWithDomain:@"RTSPConfigurationExporter"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"Unknown error"}];
        }
        return NO;
    }
}

#pragma mark - Auto-Sync

- (void)setAutoSyncEnabled:(BOOL)autoSyncEnabled {
    _autoSyncEnabled = autoSyncEnabled;
    [[NSUserDefaults standardUserDefaults] setBool:autoSyncEnabled forKey:@"ConfigAutoSyncEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if (autoSyncEnabled && self.autoSyncURL) {
        [self startAutoSync];
    } else {
        [self stopAutoSync];
    }
}

- (void)setAutoSyncInterval:(NSTimeInterval)autoSyncInterval {
    _autoSyncInterval = autoSyncInterval;
    [[NSUserDefaults standardUserDefaults] setDouble:autoSyncInterval forKey:@"ConfigAutoSyncInterval"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if (self.autoSyncEnabled) {
        [self stopAutoSync];
        [self startAutoSync];
    }
}

- (void)setAutoSyncURL:(NSString *)autoSyncURL {
    _autoSyncURL = autoSyncURL;
    [[NSUserDefaults standardUserDefaults] setObject:autoSyncURL forKey:@"ConfigAutoSyncURL"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoSyncUploadMethod:(NSString *)autoSyncUploadMethod {
    _autoSyncUploadMethod = autoSyncUploadMethod;
    [[NSUserDefaults standardUserDefaults] setObject:autoSyncUploadMethod forKey:@"ConfigAutoSyncMethod"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)startAutoSync {
    if (self.autoSyncTimer) {
        [self stopAutoSync];
    }

    NSLog(@"[ConfigExporter] Starting auto-sync (interval: %.0f seconds)", self.autoSyncInterval);

    self.autoSyncTimer = [NSTimer scheduledTimerWithTimeInterval:self.autoSyncInterval
                                                          target:self
                                                        selector:@selector(autoSyncTimerFired:)
                                                        userInfo:nil
                                                         repeats:YES];

    // Fire immediately
    [self syncNow:nil];
}

- (void)stopAutoSync {
    if (self.autoSyncTimer) {
        [self.autoSyncTimer invalidate];
        self.autoSyncTimer = nil;
        NSLog(@"[ConfigExporter] Auto-sync stopped");
    }
}

- (void)autoSyncTimerFired:(NSTimer *)timer {
    [self syncNow:nil];
}

- (void)syncNow:(void (^)(BOOL downloadSuccess, BOOL uploadSuccess))completion {
    if (self.isSyncing) {
        NSLog(@"[ConfigExporter] Sync already in progress, skipping");
        if (completion) completion(NO, NO);
        return;
    }

    if (!self.autoSyncURL) {
        NSLog(@"[ConfigExporter] No sync URL configured");
        if (completion) completion(NO, NO);
        return;
    }

    self.isSyncing = YES;
    NSLog(@"[ConfigExporter] Starting sync with: %@", self.autoSyncURL);

    // First, download latest configuration
    [self importConfigurationFromURL:self.autoSyncURL merge:YES completion:^(BOOL downloadSuccess, NSError *downloadError) {
        if (downloadSuccess) {
            NSLog(@"[ConfigExporter] ✓ Downloaded configuration from sync URL");
        } else {
            NSLog(@"[ConfigExporter] ⚠ Failed to download: %@", downloadError.localizedDescription);
        }

        // Then, upload current configuration
        [self uploadConfigurationToURL:self.autoSyncURL method:self.autoSyncUploadMethod completion:^(BOOL uploadSuccess, NSString *uploadURL, NSError *uploadError) {
            if (uploadSuccess) {
                NSLog(@"[ConfigExporter] ✓ Uploaded configuration to sync URL");
            } else {
                NSLog(@"[ConfigExporter] ⚠ Failed to upload: %@", uploadError.localizedDescription);
            }

            self.isSyncing = NO;

            if (completion) {
                completion(downloadSuccess, uploadSuccess);
            }
        }];
    }];
}

@end
