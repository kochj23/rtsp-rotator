//
//  RTSPPreferencesController.m
//  RTSP Rotator
//
//  Created by Jordan Koch on 10/29/25.
//

#import "RTSPPreferencesController.h"
#import "RTSPUniFiProtectAdapter.h"

#pragma mark - Configuration Manager Implementation

@implementation RTSPConfigurationManager

+ (instancetype)sharedManager {
    static RTSPConfigurationManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RTSPConfigurationManager alloc] init];
        [sharedInstance load];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Set defaults
        _configurationSource = RTSPConfigurationSourceManual;
        _manualFeeds = @[];
        _rotationInterval = 60.0;
        _startMuted = YES;
        _autoSkipFailedFeeds = YES;
        _retryAttempts = 3;
    }
    return self;
}

#pragma mark - Manual Feed Management

- (void)addManualFeed:(NSString *)feedURL {
    if (!feedURL || feedURL.length == 0) {
        NSLog(@"[WARNING] Attempted to add empty feed URL");
        return;
    }

    // Add to metadata (new system)
    NSMutableArray *metadata = [self.manualFeedMetadata mutableCopy] ?: [NSMutableArray array];

    // Check if already exists
    BOOL exists = NO;
    for (RTSPFeedMetadata *existing in metadata) {
        if ([existing.url isEqualToString:feedURL]) {
            exists = YES;
            NSLog(@"[WARNING] Feed already exists: %@", feedURL);
            break;
        }
    }

    if (!exists) {
        RTSPFeedMetadata *feedMeta = [[RTSPFeedMetadata alloc] init];
        feedMeta.url = feedURL;
        feedMeta.displayName = feedURL;
        feedMeta.enabled = YES;
        feedMeta.category = @"Manual";
        [metadata addObject:feedMeta];
        self.manualFeedMetadata = [metadata copy];
        [self save];
        NSLog(@"[INFO] Added manual feed: %@", feedURL);
    }
}

- (void)removeManualFeedAtIndex:(NSUInteger)index {
    NSArray *metadata = self.manualFeedMetadata ?: @[];
    if (index >= metadata.count) {
        NSLog(@"[ERROR] Invalid index %lu for removeManualFeedAtIndex", (unsigned long)index);
        return;
    }

    NSMutableArray *mutableMetadata = [metadata mutableCopy];
    RTSPFeedMetadata *removed = mutableMetadata[index];
    [mutableMetadata removeObjectAtIndex:index];
    self.manualFeedMetadata = [mutableMetadata copy];
    [self save];

    NSLog(@"[INFO] Removed manual feed at index %lu: %@", (unsigned long)index, removed.url);
}

- (void)updateManualFeedAtIndex:(NSUInteger)index withURL:(NSString *)feedURL {
    NSArray *metadata = self.manualFeedMetadata ?: @[];
    if (index >= metadata.count) {
        NSLog(@"[ERROR] Invalid index %lu for updateManualFeedAtIndex", (unsigned long)index);
        return;
    }

    if (!feedURL || feedURL.length == 0) {
        NSLog(@"[WARNING] Attempted to update with empty feed URL");
        return;
    }

    NSMutableArray *mutableMetadata = [metadata mutableCopy];
    RTSPFeedMetadata *feedMeta = mutableMetadata[index];
    feedMeta.url = feedURL;
    feedMeta.displayName = feedURL;
    self.manualFeedMetadata = [mutableMetadata copy];
    [self save];

    NSLog(@"[INFO] Updated manual feed at index %lu: %@", (unsigned long)index, feedURL);
}

- (void)moveManualFeedFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
    NSArray *metadata = self.manualFeedMetadata ?: @[];
    if (fromIndex >= metadata.count || toIndex >= metadata.count) {
        NSLog(@"[ERROR] Invalid indices for moveManualFeedFromIndex");
        return;
    }

    NSMutableArray *mutableMetadata = [metadata mutableCopy];
    RTSPFeedMetadata *feedMeta = mutableMetadata[fromIndex];
    [mutableMetadata removeObjectAtIndex:fromIndex];
    [mutableMetadata insertObject:feedMeta atIndex:toIndex];
    self.manualFeedMetadata = [mutableMetadata copy];
    [self save];

    NSLog(@"[INFO] Moved manual feed from index %lu to %lu", (unsigned long)fromIndex, (unsigned long)toIndex);
}

#pragma mark - Loading Feeds

- (void)loadFeedsWithCompletion:(void (^)(NSArray<NSString *> * _Nullable, NSError * _Nullable))completion {
    if (!completion) return;

    switch (self.configurationSource) {
        case RTSPConfigurationSourceManual:
            [self loadManualFeedsWithCompletion:completion];
            break;

        case RTSPConfigurationSourceRemoteURL:
            [self loadRemoteFeedsWithCompletion:completion];
            break;
    }
}

- (void)loadManualFeedsWithCompletion:(void (^)(NSArray<NSString *> * _Nullable, NSError * _Nullable))completion {
    NSLog(@"[INFO] Loading manual feeds");

    if (self.manualFeeds.count == 0) {
        NSError *error = [NSError errorWithDomain:@"RTSPConfigurationManager"
                                             code:1001
                                         userInfo:@{NSLocalizedDescriptionKey: @"No manual feeds configured"}];
        completion(nil, error);
        return;
    }

    completion(self.manualFeeds, nil);
}

- (void)loadRemoteFeedsWithCompletion:(void (^)(NSArray<NSString *> * _Nullable, NSError * _Nullable))completion {
    if (!self.remoteConfigurationURL || self.remoteConfigurationURL.length == 0) {
        NSError *error = [NSError errorWithDomain:@"RTSPConfigurationManager"
                                             code:1002
                                         userInfo:@{NSLocalizedDescriptionKey: @"No remote configuration URL configured"}];
        completion(nil, error);
        return;
    }

    NSLog(@"[INFO] Loading feeds from remote URL: %@", self.remoteConfigurationURL);

    NSURL *url = [NSURL URLWithString:self.remoteConfigurationURL];
    if (!url) {
        NSError *error = [NSError errorWithDomain:@"RTSPConfigurationManager"
                                             code:1003
                                         userInfo:@{NSLocalizedDescriptionKey: @"Invalid remote configuration URL"}];
        completion(nil, error);
        return;
    }

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[ERROR] Failed to fetch remote configuration: %@", error.localizedDescription);
            completion(nil, error);
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            NSError *statusError = [NSError errorWithDomain:@"RTSPConfigurationManager"
                                                       code:httpResponse.statusCode
                                                   userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP %ld", (long)httpResponse.statusCode]}];
            NSLog(@"[ERROR] Remote configuration returned HTTP %ld", (long)httpResponse.statusCode);
            completion(nil, statusError);
            return;
        }

        NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (!content) {
            NSError *parseError = [NSError errorWithDomain:@"RTSPConfigurationManager"
                                                      code:1004
                                                  userInfo:@{NSLocalizedDescriptionKey: @"Could not parse remote configuration"}];
            completion(nil, parseError);
            return;
        }

        NSArray<NSString *> *feeds = [self parseFeedsFromString:content];
        NSLog(@"[INFO] Loaded %lu feeds from remote URL", (unsigned long)feeds.count);
        completion(feeds, nil);
    }];

    [task resume];
}

- (void)refreshRemoteConfiguration:(void (^)(BOOL, NSError * _Nullable))completion {
    if (self.configurationSource != RTSPConfigurationSourceRemoteURL) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"RTSPConfigurationManager"
                                                 code:1005
                                             userInfo:@{NSLocalizedDescriptionKey: @"Not using remote configuration"}];
            completion(NO, error);
        }
        return;
    }

    [self loadRemoteFeedsWithCompletion:^(NSArray<NSString *> *feeds, NSError *error) {
        if (completion) {
            completion(feeds != nil, error);
        }
    }];
}

#pragma mark - Feed Parsing

- (NSArray<NSString *> *)parseFeedsFromString:(NSString *)content {
    NSMutableArray<NSString *> *feeds = [NSMutableArray array];

    // Check if content is CSV format
    if ([content containsString:@","]) {
        [feeds addObjectsFromArray:[self parseCSVFeeds:content]];
    } else {
        [feeds addObjectsFromArray:[self parseLineDelimitedFeeds:content]];
    }

    return [feeds copy];
}

- (NSArray<NSString *> *)parseLineDelimitedFeeds:(NSString *)content {
    NSMutableArray<NSString *> *feeds = [NSMutableArray array];
    NSArray<NSString *> *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0 && ![trimmed hasPrefix:@"#"]) {
            [feeds addObject:trimmed];
        }
    }

    return feeds;
}

- (NSArray<NSString *> *)parseCSVFeeds:(NSString *)content {
    NSMutableArray<NSString *> *feeds = [NSMutableArray array];

    // Simple CSV parser that handles quoted strings
    NSScanner *scanner = [NSScanner scannerWithString:content];
    scanner.charactersToBeSkipped = nil;

    while (!scanner.isAtEnd) {
        NSString *field = nil;

        // Skip leading whitespace and commas
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
        [scanner scanString:@"," intoString:nil];
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];

        if ([scanner scanString:@"\"" intoString:nil]) {
            // Quoted field
            NSMutableString *quotedField = [NSMutableString string];
            while (!scanner.isAtEnd) {
                NSString *chunk = nil;
                [scanner scanUpToString:@"\"" intoString:&chunk];
                if (chunk) [quotedField appendString:chunk];

                if ([scanner scanString:@"\"" intoString:nil]) {
                    if ([scanner scanString:@"\"" intoString:nil]) {
                        // Escaped quote
                        [quotedField appendString:@"\""];
                    } else {
                        // End of quoted field
                        break;
                    }
                }
            }
            field = quotedField;
        } else {
            // Unquoted field
            [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@",\n\r"]
                                    intoString:&field];
        }

        if (field) {
            NSString *trimmed = [field stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (trimmed.length > 0 && ![trimmed hasPrefix:@"#"]) {
                [feeds addObject:trimmed];
            }
        }

        // Skip trailing comma/newline
        [scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@",\n\r"] intoString:nil];
    }

    return feeds;
}

#pragma mark - Persistence

static NSString * const kConfigSourceKey = @"RTSPConfigurationSource";
static NSString * const kRemoteURLKey = @"RTSPRemoteConfigurationURL";
static NSString * const kManualFeedsKey = @"RTSPManualFeeds";
static NSString * const kRotationIntervalKey = @"RTSPRotationInterval";
static NSString * const kStartMutedKey = @"RTSPStartMuted";
static NSString * const kAutoSkipFailedKey = @"RTSPAutoSkipFailed";
static NSString * const kRetryAttemptsKey = @"RTSPRetryAttempts";

- (void)save {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setInteger:self.configurationSource forKey:kConfigSourceKey];
    [defaults setObject:self.remoteConfigurationURL forKey:kRemoteURLKey];
    [defaults setObject:self.manualFeeds forKey:kManualFeedsKey];
    [defaults setDouble:self.rotationInterval forKey:kRotationIntervalKey];
    [defaults setBool:self.startMuted forKey:kStartMutedKey];
    [defaults setBool:self.autoSkipFailedFeeds forKey:kAutoSkipFailedKey];
    [defaults setInteger:self.retryAttempts forKey:kRetryAttemptsKey];

    [defaults synchronize];

    NSLog(@"[INFO] Configuration saved to NSUserDefaults");
}

- (void)load {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults objectForKey:kConfigSourceKey]) {
        _configurationSource = [defaults integerForKey:kConfigSourceKey];
    }

    _remoteConfigurationURL = [defaults stringForKey:kRemoteURLKey];

    NSArray *savedFeeds = [defaults arrayForKey:kManualFeedsKey];
    if (savedFeeds) {
        _manualFeeds = savedFeeds;
    }

    if ([defaults objectForKey:kRotationIntervalKey]) {
        _rotationInterval = [defaults doubleForKey:kRotationIntervalKey];
    }

    if ([defaults objectForKey:kStartMutedKey]) {
        _startMuted = [defaults boolForKey:kStartMutedKey];
    }

    if ([defaults objectForKey:kAutoSkipFailedKey]) {
        _autoSkipFailedFeeds = [defaults boolForKey:kAutoSkipFailedKey];
    }

    if ([defaults objectForKey:kRetryAttemptsKey]) {
        _retryAttempts = [defaults integerForKey:kRetryAttemptsKey];
    }

    NSLog(@"[INFO] Configuration loaded from NSUserDefaults");
}

- (void)resetToDefaults {
    NSLog(@"[INFO] Resetting configuration to defaults");

    self.configurationSource = RTSPConfigurationSourceManual;
    self.remoteConfigurationURL = nil;
    self.manualFeeds = @[];
    self.rotationInterval = 60.0;
    self.startMuted = YES;
    self.autoSkipFailedFeeds = YES;
    self.retryAttempts = 3;

    [self save];
}

@end

#pragma mark - Preferences Controller Implementation

@interface RTSPPreferencesController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) RTSPConfigurationManager *configManager;

// UI Elements
@property (nonatomic, strong) NSMatrix *sourceMatrix;
@property (nonatomic, strong) NSTextField *remoteURLField;
@property (nonatomic, strong) NSTableView *feedsTableView;
@property (nonatomic, strong) NSButton *addFeedButton;
@property (nonatomic, strong) NSButton *removeFeedButton;
@property (nonatomic, strong) NSTextField *rotationIntervalField;
@property (nonatomic, strong) NSButton *startMutedCheckbox;
@property (nonatomic, strong) NSButton *autoSkipCheckbox;
@property (nonatomic, strong) NSStepper *retryAttemptsStepper;
@property (nonatomic, strong) NSTextField *retryAttemptsLabel;

// UniFi Protect credentials
@property (nonatomic, strong) NSTextField *unifiHostField;
@property (nonatomic, strong) NSTextField *unifiUsernameField;
@property (nonatomic, strong) NSSecureTextField *unifiPasswordField;

// Google Home OAuth credentials
@property (nonatomic, strong) NSTextField *googleClientIDField;
@property (nonatomic, strong) NSSecureTextField *googleClientSecretField;
@property (nonatomic, strong) NSTextField *googleProjectIDField;

@end

@implementation RTSPPreferencesController

+ (instancetype)sharedController {
    static RTSPPreferencesController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RTSPPreferencesController alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _configManager = [RTSPConfigurationManager sharedManager];
        [self createPreferencesWindow];
    }
    return self;
}

- (void)createPreferencesWindow {
    // Create window - increased height for additional credentials
    NSRect frame = NSMakeRect(0, 0, 650, 800);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:(NSWindowStyleMaskTitled |
                                                              NSWindowStyleMaskClosable)
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    window.title = @"RTSP Rotator Preferences";
    [window center];

    self.window = window;

    NSView *contentView = window.contentView;

    CGFloat yPos = frame.size.height - 40;
    CGFloat leftMargin = 20;
    CGFloat rightMargin = 20;
    CGFloat contentWidth = frame.size.width - leftMargin - rightMargin;

    // Configuration Source Section
    NSTextField *sourceLabel = [self createLabel:@"Configuration Source:" frame:NSMakeRect(leftMargin, yPos, 200, 20)];
    [contentView addSubview:sourceLabel];
    yPos -= 25;

    self.sourceMatrix = [[NSMatrix alloc] initWithFrame:NSMakeRect(leftMargin + 20, yPos - 40, 200, 50)];
    [self.sourceMatrix setMode:NSRadioModeMatrix];
    [self.sourceMatrix addRow];
    [self.sourceMatrix addRow];

    NSButtonCell *manualCell = [self.sourceMatrix cellAtRow:0 column:0];
    manualCell.title = @"Manual Entry";
    manualCell.tag = RTSPConfigurationSourceManual;

    NSButtonCell *remoteCell = [self.sourceMatrix cellAtRow:1 column:0];
    remoteCell.title = @"Remote URL";
    remoteCell.tag = RTSPConfigurationSourceRemoteURL;

    [self.sourceMatrix selectCellAtRow:self.configManager.configurationSource column:0];
    [self.sourceMatrix setTarget:self];
    [self.sourceMatrix setAction:@selector(sourceChanged:)];
    [contentView addSubview:self.sourceMatrix];
    yPos -= 60;

    // Remote URL Field
    NSTextField *remoteLabel = [self createLabel:@"Remote Configuration URL:" frame:NSMakeRect(leftMargin, yPos, 200, 20)];
    [contentView addSubview:remoteLabel];
    yPos -= 25;

    self.remoteURLField = [[NSTextField alloc] initWithFrame:NSMakeRect(leftMargin, yPos, contentWidth, 22)];
    self.remoteURLField.placeholderString = @"https://example.com/feeds.txt";
    self.remoteURLField.stringValue = self.configManager.remoteConfigurationURL ?: @"";
    [contentView addSubview:self.remoteURLField];
    yPos -= 35;

    // Manual Feeds Section
    NSTextField *feedsLabel = [self createLabel:@"Manual Feeds:" frame:NSMakeRect(leftMargin, yPos, 200, 20)];
    [contentView addSubview:feedsLabel];
    yPos -= 25;

    // Table view for feeds
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(leftMargin, yPos - 120, contentWidth - 100, 120)];
    scrollView.hasVerticalScroller = YES;
    scrollView.autohidesScrollers = YES;
    scrollView.borderType = NSBezelBorder;

    self.feedsTableView = [[NSTableView alloc] initWithFrame:scrollView.bounds];
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"url"];
    column.title = @"RTSP URL";
    column.width = contentWidth - 120;
    [self.feedsTableView addTableColumn:column];
    self.feedsTableView.delegate = self;
    self.feedsTableView.dataSource = self;
    scrollView.documentView = self.feedsTableView;
    [contentView addSubview:scrollView];

    // Add/Remove buttons
    CGFloat buttonX = leftMargin + contentWidth - 80;
    self.addFeedButton = [self createButton:@"+" frame:NSMakeRect(buttonX, yPos - 30, 30, 24) action:@selector(addFeed:)];
    [contentView addSubview:self.addFeedButton];

    self.removeFeedButton = [self createButton:@"−" frame:NSMakeRect(buttonX + 40, yPos - 30, 30, 24) action:@selector(removeFeed:)];
    [contentView addSubview:self.removeFeedButton];

    yPos -= 140;

    // Playback Settings Section
    NSTextField *playbackLabel = [self createLabel:@"Playback Settings:" frame:NSMakeRect(leftMargin, yPos, 200, 20)];
    [contentView addSubview:playbackLabel];
    yPos -= 30;

    // Rotation interval
    NSTextField *intervalLabel = [self createLabel:@"Rotation Interval (seconds):" frame:NSMakeRect(leftMargin + 20, yPos, 200, 20)];
    [contentView addSubview:intervalLabel];

    self.rotationIntervalField = [[NSTextField alloc] initWithFrame:NSMakeRect(leftMargin + 230, yPos, 60, 22)];
    self.rotationIntervalField.stringValue = [NSString stringWithFormat:@"%.0f", self.configManager.rotationInterval];
    [contentView addSubview:self.rotationIntervalField];
    yPos -= 30;

    // Start muted
    self.startMutedCheckbox = [self createCheckbox:@"Start Muted" frame:NSMakeRect(leftMargin + 20, yPos, 200, 20) state:self.configManager.startMuted];
    [contentView addSubview:self.startMutedCheckbox];
    yPos -= 30;

    // Auto-skip failed feeds
    self.autoSkipCheckbox = [self createCheckbox:@"Auto-skip Failed Feeds" frame:NSMakeRect(leftMargin + 20, yPos, 200, 20) state:self.configManager.autoSkipFailedFeeds];
    [contentView addSubview:self.autoSkipCheckbox];
    yPos -= 30;

    // Retry attempts
    NSTextField *retryLabel = [self createLabel:@"Retry Attempts:" frame:NSMakeRect(leftMargin + 20, yPos, 150, 20)];
    [contentView addSubview:retryLabel];

    self.retryAttemptsLabel = [self createLabel:[NSString stringWithFormat:@"%ld", (long)self.configManager.retryAttempts]
                                          frame:NSMakeRect(leftMargin + 180, yPos, 30, 20)];
    [contentView addSubview:self.retryAttemptsLabel];

    self.retryAttemptsStepper = [[NSStepper alloc] initWithFrame:NSMakeRect(leftMargin + 210, yPos, 20, 20)];
    self.retryAttemptsStepper.minValue = 0;
    self.retryAttemptsStepper.maxValue = 10;
    self.retryAttemptsStepper.integerValue = self.configManager.retryAttempts;
    [self.retryAttemptsStepper setTarget:self];
    [self.retryAttemptsStepper setAction:@selector(retryAttemptsChanged:)];
    [contentView addSubview:self.retryAttemptsStepper];
    yPos -= 50;

    // UniFi Protect Credentials Section
    NSTextField *unifiHeaderLabel = [self createLabel:@"UniFi Protect Credentials:" frame:NSMakeRect(leftMargin, yPos, 250, 20)];
    unifiHeaderLabel.font = [NSFont boldSystemFontOfSize:13];
    [contentView addSubview:unifiHeaderLabel];
    yPos -= 25;

    NSTextField *unifiHostLabel = [self createLabel:@"Controller IP:" frame:NSMakeRect(leftMargin + 20, yPos, 150, 20)];
    [contentView addSubview:unifiHostLabel];

    self.unifiHostField = [self createTextField:@"" frame:NSMakeRect(leftMargin + 170, yPos, 200, 22)];
    self.unifiHostField.placeholderString = @"10.0.0.1";
    [contentView addSubview:self.unifiHostField];
    yPos -= 25;

    NSTextField *unifiUsernameLabel = [self createLabel:@"Username:" frame:NSMakeRect(leftMargin + 20, yPos, 150, 20)];
    [contentView addSubview:unifiUsernameLabel];

    self.unifiUsernameField = [self createTextField:@"" frame:NSMakeRect(leftMargin + 170, yPos, 200, 22)];
    self.unifiUsernameField.placeholderString = @"user@example.com";
    [contentView addSubview:self.unifiUsernameField];
    yPos -= 25;

    NSTextField *unifiPasswordLabel = [self createLabel:@"Password:" frame:NSMakeRect(leftMargin + 20, yPos, 150, 20)];
    [contentView addSubview:unifiPasswordLabel];

    self.unifiPasswordField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(leftMargin + 170, yPos, 200, 22)];
    self.unifiPasswordField.placeholderString = @"Password";
    [contentView addSubview:self.unifiPasswordField];
    yPos -= 40;

    // Google Home OAuth Section
    NSTextField *googleHeaderLabel = [self createLabel:@"Google Home OAuth Credentials:" frame:NSMakeRect(leftMargin, yPos, 300, 20)];
    googleHeaderLabel.font = [NSFont boldSystemFontOfSize:13];
    [contentView addSubview:googleHeaderLabel];
    yPos -= 25;

    NSTextField *googleClientIDLabel = [self createLabel:@"Client ID:" frame:NSMakeRect(leftMargin + 20, yPos, 150, 20)];
    [contentView addSubview:googleClientIDLabel];

    self.googleClientIDField = [self createTextField:@"" frame:NSMakeRect(leftMargin + 170, yPos, 350, 22)];
    self.googleClientIDField.placeholderString = @"123456789.apps.googleusercontent.com";
    [contentView addSubview:self.googleClientIDField];
    yPos -= 25;

    NSTextField *googleClientSecretLabel = [self createLabel:@"Client Secret:" frame:NSMakeRect(leftMargin + 20, yPos, 150, 20)];
    [contentView addSubview:googleClientSecretLabel];

    self.googleClientSecretField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(leftMargin + 170, yPos, 350, 22)];
    self.googleClientSecretField.placeholderString = @"GOCSPX-...";
    [contentView addSubview:self.googleClientSecretField];
    yPos -= 25;

    NSTextField *googleProjectIDLabel = [self createLabel:@"Project ID:" frame:NSMakeRect(leftMargin + 20, yPos, 150, 20)];
    [contentView addSubview:googleProjectIDLabel];

    self.googleProjectIDField = [self createTextField:@"" frame:NSMakeRect(leftMargin + 170, yPos, 350, 22)];
    self.googleProjectIDField.placeholderString = @"my-sdm-project";
    [contentView addSubview:self.googleProjectIDField];
    yPos -= 40;

    // Save/Cancel buttons
    NSButton *saveButton = [self createButton:@"Save" frame:NSMakeRect(frame.size.width - 170, 20, 70, 24) action:@selector(savePreferences:)];
    saveButton.keyEquivalent = @"\r";
    [contentView addSubview:saveButton];

    NSButton *cancelButton = [self createButton:@"Cancel" frame:NSMakeRect(frame.size.width - 90, 20, 70, 24) action:@selector(cancelPreferences:)];
    cancelButton.keyEquivalent = @"\e";
    [contentView addSubview:cancelButton];

    [self updateUIState];
}

#pragma mark - UI Creation Helpers

- (NSTextField *)createLabel:(NSString *)text frame:(NSRect)frame {
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    label.stringValue = text;
    label.editable = NO;
    label.selectable = NO;
    label.bordered = NO;
    label.backgroundColor = [NSColor clearColor];
    return label;
}

- (NSTextField *)createTextField:(NSString *)text frame:(NSRect)frame {
    NSTextField *textField = [[NSTextField alloc] initWithFrame:frame];
    textField.stringValue = text;
    textField.editable = YES;
    textField.selectable = YES;
    textField.bordered = YES;
    textField.bezelStyle = NSTextFieldSquareBezel;
    return textField;
}

- (NSButton *)createButton:(NSString *)title frame:(NSRect)frame action:(SEL)action {
    NSButton *button = [[NSButton alloc] initWithFrame:frame];
    button.title = title;
    button.bezelStyle = NSBezelStyleRounded;
    [button setTarget:self];
    [button setAction:action];
    return button;
}

- (NSButton *)createCheckbox:(NSString *)title frame:(NSRect)frame state:(BOOL)state {
    NSButton *checkbox = [[NSButton alloc] initWithFrame:frame];
    [checkbox setButtonType:NSButtonTypeSwitch];
    checkbox.title = title;
    checkbox.state = state ? NSControlStateValueOn : NSControlStateValueOff;
    return checkbox;
}

#pragma mark - UI Actions

- (void)sourceChanged:(id)sender {
    [self updateUIState];
}

- (void)updateUIState {
    RTSPConfigurationSource source = [[self.sourceMatrix selectedCell] tag];

    self.remoteURLField.enabled = (source == RTSPConfigurationSourceRemoteURL);
    self.feedsTableView.enabled = (source == RTSPConfigurationSourceManual);
    self.addFeedButton.enabled = (source == RTSPConfigurationSourceManual);
    self.removeFeedButton.enabled = (source == RTSPConfigurationSourceManual);
}

- (void)addFeed:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Add RTSP Feed";
    alert.informativeText = @"Enter the RTSP/RTSPS URL:";
    [alert addButtonWithTitle:@"Add"];
    [alert addButtonWithTitle:@"Cancel"];

    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
    input.placeholderString = @"rtsp://camera.local:554/stream or rtsps://...";
    alert.accessoryView = input;

    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            NSString *url = input.stringValue;
            if (url.length > 0) {
                [self.configManager addManualFeed:url];
                [self.feedsTableView reloadData];
            }
        }
    }];
}

- (void)removeFeed:(id)sender {
    NSInteger selectedRow = self.feedsTableView.selectedRow;
    if (selectedRow >= 0) {
        [self.configManager removeManualFeedAtIndex:selectedRow];
        [self.feedsTableView reloadData];
    }
}

- (void)retryAttemptsChanged:(id)sender {
    self.retryAttemptsLabel.stringValue = [NSString stringWithFormat:@"%ld", (long)self.retryAttemptsStepper.integerValue];
}

- (void)savePreferences:(id)sender {
    // Update configuration manager
    self.configManager.configurationSource = [[self.sourceMatrix selectedCell] tag];
    self.configManager.remoteConfigurationURL = self.remoteURLField.stringValue;
    self.configManager.rotationInterval = [self.rotationIntervalField.stringValue doubleValue];
    self.configManager.startMuted = (self.startMutedCheckbox.state == NSControlStateValueOn);
    self.configManager.autoSkipFailedFeeds = (self.autoSkipCheckbox.state == NSControlStateValueOn);
    self.configManager.retryAttempts = self.retryAttemptsStepper.integerValue;

    // Save UniFi Protect credentials
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (self.unifiHostField.stringValue.length > 0) {
        [defaults setObject:self.unifiHostField.stringValue forKey:@"UniFi_ControllerHost"];
    }
    if (self.unifiUsernameField.stringValue.length > 0) {
        [defaults setObject:self.unifiUsernameField.stringValue forKey:@"UniFi_Username"];
    }
    if (self.unifiPasswordField.stringValue.length > 0) {
        [defaults setObject:self.unifiPasswordField.stringValue forKey:@"UniFi_Password"];
    }

    // Save Google OAuth credentials
    if (self.googleClientIDField.stringValue.length > 0) {
        [defaults setObject:self.googleClientIDField.stringValue forKey:@"GoogleHome_ClientID"];
    }
    if (self.googleClientSecretField.stringValue.length > 0) {
        [defaults setObject:self.googleClientSecretField.stringValue forKey:@"GoogleHome_ClientSecret"];
    }
    if (self.googleProjectIDField.stringValue.length > 0) {
        [defaults setObject:self.googleProjectIDField.stringValue forKey:@"GoogleHome_ProjectID"];
    }

    [defaults synchronize];

    // Update UniFi adapter with stored credentials
    RTSPUniFiProtectAdapter *unifiAdapter = [RTSPUniFiProtectAdapter sharedAdapter];
    unifiAdapter.controllerHost = self.unifiHostField.stringValue;
    unifiAdapter.username = self.unifiUsernameField.stringValue;
    unifiAdapter.password = self.unifiPasswordField.stringValue;
    [unifiAdapter saveConfiguration];

    // Save to persistent storage
    [self.configManager save];

    // Post notification that configuration changed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTSPConfigurationDidChangeNotification" object:nil];

    NSLog(@"[INFO] Preferences saved");
    [self.window close];
}

- (void)cancelPreferences:(id)sender {
    // Reload from saved settings
    [self.configManager load];
    [self.window close];
}

- (void)showWindow:(id)sender {
    // Reload UI from current config
    [self.sourceMatrix selectCellAtRow:self.configManager.configurationSource column:0];
    self.remoteURLField.stringValue = self.configManager.remoteConfigurationURL ?: @"";
    self.rotationIntervalField.stringValue = [NSString stringWithFormat:@"%.0f", self.configManager.rotationInterval];
    self.startMutedCheckbox.state = self.configManager.startMuted ? NSControlStateValueOn : NSControlStateValueOff;
    self.autoSkipCheckbox.state = self.configManager.autoSkipFailedFeeds ? NSControlStateValueOn : NSControlStateValueOff;
    self.retryAttemptsStepper.integerValue = self.configManager.retryAttempts;
    self.retryAttemptsLabel.stringValue = [NSString stringWithFormat:@"%ld", (long)self.configManager.retryAttempts];

    // Load UniFi Protect credentials
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.unifiHostField.stringValue = [defaults stringForKey:@"UniFi_ControllerHost"] ?: @"";
    self.unifiUsernameField.stringValue = [defaults stringForKey:@"UniFi_Username"] ?: @"";
    self.unifiPasswordField.stringValue = [defaults stringForKey:@"UniFi_Password"] ?: @"";

    // Load Google OAuth credentials
    self.googleClientIDField.stringValue = [defaults stringForKey:@"GoogleHome_ClientID"] ?: @"";
    self.googleClientSecretField.stringValue = [defaults stringForKey:@"GoogleHome_ClientSecret"] ?: @"";
    self.googleProjectIDField.stringValue = [defaults stringForKey:@"GoogleHome_ProjectID"] ?: @"";

    [self.feedsTableView reloadData];
    [self updateUIState];

    [self.window makeKeyAndOrderFront:sender];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSArray *metadata = self.configManager.manualFeedMetadata ?: @[];
    return metadata.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSArray *metadata = self.configManager.manualFeedMetadata ?: @[];
    if (row < metadata.count) {
        RTSPFeedMetadata *feedMeta = metadata[row];
        return feedMeta.url;
    }
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSArray *metadata = self.configManager.manualFeedMetadata ?: @[];
    if (row < metadata.count && [object isKindOfClass:[NSString class]]) {
        [self.configManager updateManualFeedAtIndex:row withURL:object];
    }
}

#pragma mark - NSTableViewDelegate

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return YES;
}

@end
