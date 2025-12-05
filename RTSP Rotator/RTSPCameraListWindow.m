//
//  RTSPCameraListWindow.m
//  RTSP Rotator
//
//  Camera list viewer with status and connection testing
//

#import "RTSPCameraListWindow.h"
#import "RTSPPreferencesController.h"
#import "RTSPFeedMetadata.h"
#import <AVFoundation/AVFoundation.h>

@interface RTSPCameraInfo : NSObject
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *category;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL isOnline; // Connection test result
@property (nonatomic, assign) BOOL isTesting;
@property (nonatomic, strong) NSString *statusMessage;
@property (nonatomic, strong) NSError *lastError;
@end

@implementation RTSPCameraInfo
@end

@interface RTSPCameraListWindow () <NSTableViewDataSource, NSTableViewDelegate>
@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSButton *refreshButton;
@property (nonatomic, strong) NSButton *testAllButton;
@property (nonatomic, strong) NSButton *testSelectedButton;
@property (nonatomic, strong) NSButton *enableSelectedButton;
@property (nonatomic, strong) NSButton *disableSelectedButton;
@property (nonatomic, strong) NSButton *removeSelectedButton;
@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, strong) NSMutableArray<RTSPCameraInfo *> *cameras;
@end

@implementation RTSPCameraListWindow

+ (instancetype)sharedWindow {
    static RTSPCameraListWindow *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RTSPCameraListWindow alloc] init];
    });
    return shared;
}

- (instancetype)init {
    NSRect frame = NSMakeRect(0, 0, 900, 600);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:(NSWindowStyleMaskTitled |
                                                              NSWindowStyleMaskClosable |
                                                              NSWindowStyleMaskResizable)
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];

    self = [super initWithWindow:window];
    if (self) {
        _cameras = [NSMutableArray array];
        [self setupWindowContents];
        [self refresh];
    }
    return self;
}

- (void)setupWindowContents {
    self.window.title = @"Camera List";
    self.window.minSize = NSMakeSize(700, 400);
    [self.window center];

    NSView *contentView = self.window.contentView;
    contentView.wantsLayer = YES;

    NSRect frame = self.window.frame;
    CGFloat yPos = frame.size.height - 20;
    CGFloat leftMargin = 20;
    CGFloat rightMargin = 20;
    CGFloat contentWidth = frame.size.width - leftMargin - rightMargin;

    // Status label at top
    self.statusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(leftMargin, yPos - 25, contentWidth, 20)];
    self.statusLabel.stringValue = @"Camera List";
    self.statusLabel.editable = NO;
    self.statusLabel.selectable = NO;
    self.statusLabel.bordered = NO;
    self.statusLabel.backgroundColor = [NSColor clearColor];
    self.statusLabel.font = [NSFont boldSystemFontOfSize:13];
    [contentView addSubview:self.statusLabel];

    yPos -= 50;

    // Table view
    self.scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(leftMargin, 60, contentWidth, yPos - 60)];
    self.scrollView.hasVerticalScroller = YES;
    self.scrollView.hasHorizontalScroller = YES;
    self.scrollView.autohidesScrollers = YES;
    self.scrollView.borderType = NSBezelBorder;
    self.scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    self.tableView = [[NSTableView alloc] initWithFrame:self.scrollView.bounds];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelection = YES;
    self.tableView.usesAlternatingRowBackgroundColors = YES;
    self.tableView.rowHeight = 24;

    // Columns
    NSTableColumn *statusCol = [[NSTableColumn alloc] initWithIdentifier:@"status"];
    statusCol.title = @"Status";
    statusCol.width = 60;
    [self.tableView addTableColumn:statusCol];

    NSTableColumn *nameCol = [[NSTableColumn alloc] initWithIdentifier:@"name"];
    nameCol.title = @"Name";
    nameCol.width = 200;
    [self.tableView addTableColumn:nameCol];

    NSTableColumn *categoryCol = [[NSTableColumn alloc] initWithIdentifier:@"category"];
    categoryCol.title = @"Category";
    categoryCol.width = 120;
    [self.tableView addTableColumn:categoryCol];

    NSTableColumn *urlCol = [[NSTableColumn alloc] initWithIdentifier:@"url"];
    urlCol.title = @"RTSP URL";
    urlCol.width = 350;
    [self.tableView addTableColumn:urlCol];

    NSTableColumn *enabledCol = [[NSTableColumn alloc] initWithIdentifier:@"enabled"];
    enabledCol.title = @"Enabled";
    enabledCol.width = 60;
    [self.tableView addTableColumn:enabledCol];

    self.scrollView.documentView = self.tableView;
    [contentView addSubview:self.scrollView];

    // Buttons at bottom
    CGFloat buttonY = 20;
    CGFloat buttonX = leftMargin;
    CGFloat buttonWidth = 120;
    CGFloat buttonHeight = 24;
    CGFloat buttonSpacing = 10;

    self.refreshButton = [[NSButton alloc] initWithFrame:NSMakeRect(buttonX, buttonY, buttonWidth, buttonHeight)];
    self.refreshButton.title = @"Refresh List";
    self.refreshButton.bezelStyle = NSBezelStyleRounded;
    self.refreshButton.target = self;
    self.refreshButton.action = @selector(refresh);
    [contentView addSubview:self.refreshButton];
    buttonX += buttonWidth + buttonSpacing;

    self.testAllButton = [[NSButton alloc] initWithFrame:NSMakeRect(buttonX, buttonY, buttonWidth, buttonHeight)];
    self.testAllButton.title = @"Test All";
    self.testAllButton.bezelStyle = NSBezelStyleRounded;
    self.testAllButton.target = self;
    self.testAllButton.action = @selector(testAll:);
    [contentView addSubview:self.testAllButton];
    buttonX += buttonWidth + buttonSpacing;

    self.testSelectedButton = [[NSButton alloc] initWithFrame:NSMakeRect(buttonX, buttonY, buttonWidth, buttonHeight)];
    self.testSelectedButton.title = @"Test Selected";
    self.testSelectedButton.bezelStyle = NSBezelStyleRounded;
    self.testSelectedButton.target = self;
    self.testSelectedButton.action = @selector(testSelected:);
    [contentView addSubview:self.testSelectedButton];
    buttonX += buttonWidth + buttonSpacing;

    self.enableSelectedButton = [[NSButton alloc] initWithFrame:NSMakeRect(buttonX, buttonY, buttonWidth, buttonHeight)];
    self.enableSelectedButton.title = @"Enable Selected";
    self.enableSelectedButton.bezelStyle = NSBezelStyleRounded;
    self.enableSelectedButton.target = self;
    self.enableSelectedButton.action = @selector(enableSelected:);
    [contentView addSubview:self.enableSelectedButton];
    buttonX += buttonWidth + buttonSpacing;

    self.disableSelectedButton = [[NSButton alloc] initWithFrame:NSMakeRect(buttonX, buttonY, buttonWidth, buttonHeight)];
    self.disableSelectedButton.title = @"Disable Selected";
    self.disableSelectedButton.bezelStyle = NSBezelStyleRounded;
    self.disableSelectedButton.target = self;
    self.disableSelectedButton.action = @selector(disableSelected:);
    [contentView addSubview:self.disableSelectedButton];
    buttonX += buttonWidth + buttonSpacing;

    self.removeSelectedButton = [[NSButton alloc] initWithFrame:NSMakeRect(buttonX, buttonY, buttonWidth, buttonHeight)];
    self.removeSelectedButton.title = @"Remove Selected";
    self.removeSelectedButton.bezelStyle = NSBezelStyleRounded;
    self.removeSelectedButton.target = self;
    self.removeSelectedButton.action = @selector(removeSelected:);
    [contentView addSubview:self.removeSelectedButton];
}

- (void)show {
    [self.window makeKeyAndOrderFront:nil];
}

- (void)refresh {
    [self.cameras removeAllObjects];

    RTSPConfigurationManager *config = [RTSPConfigurationManager sharedManager];
    NSArray<RTSPFeedMetadata *> *metadata = config.manualFeedMetadata;

    NSLog(@"[CameraList] Loading %lu cameras", (unsigned long)metadata.count);

    for (RTSPFeedMetadata *feed in metadata) {
        RTSPCameraInfo *info = [[RTSPCameraInfo alloc] init];
        info.displayName = feed.displayName ?: feed.url;
        info.url = feed.url;
        info.category = feed.category ?: @"Unknown";
        info.enabled = feed.enabled;
        info.isOnline = NO; // Unknown until tested
        info.isTesting = NO;
        info.statusMessage = @"Unknown";

        [self.cameras addObject:info];
    }

    self.statusLabel.stringValue = [NSString stringWithFormat:@"Found %lu cameras", (unsigned long)self.cameras.count];
    [self.tableView reloadData];
}

- (void)testAll:(id)sender {
    NSLog(@"[CameraList] Testing all %lu cameras...", (unsigned long)self.cameras.count);
    self.statusLabel.stringValue = @"Testing all cameras...";

    for (NSInteger i = 0; i < self.cameras.count; i++) {
        [self testCameraAtIndex:i];
    }
}

- (void)testSelected:(id)sender {
    NSIndexSet *selectedRows = self.tableView.selectedRowIndexes;
    if (selectedRows.count == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"No Selection";
        alert.informativeText = @"Please select one or more cameras to test.";
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }

    NSLog(@"[CameraList] Testing %lu selected cameras...", (unsigned long)selectedRows.count);
    self.statusLabel.stringValue = [NSString stringWithFormat:@"Testing %lu cameras...", (unsigned long)selectedRows.count];

    [selectedRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self testCameraAtIndex:idx];
    }];
}

- (void)testCameraAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.cameras.count) return;

    RTSPCameraInfo *info = self.cameras[index];
    info.isTesting = YES;
    info.statusMessage = @"Testing...";
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index]
                               columnIndexes:[NSIndexSet indexSetWithIndex:0]];

    NSLog(@"[CameraList] Testing camera: %@", info.url);

    NSURL *url = [NSURL URLWithString:info.url];
    if (!url) {
        info.isTesting = NO;
        info.isOnline = NO;
        info.statusMessage = @"Invalid URL";
        [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index]
                                   columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        return;
    }

    AVAsset *asset = [AVAsset assetWithURL:url];
    [asset loadValuesAsynchronouslyForKeys:@[@"playable"] completionHandler:^{
        NSError *error = nil;
        AVKeyValueStatus status = [asset statusOfValueForKey:@"playable" error:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            info.isTesting = NO;

            if (status == AVKeyValueStatusLoaded && asset.playable) {
                info.isOnline = YES;
                info.statusMessage = @"✓ Online";
                info.lastError = nil;
                NSLog(@"[CameraList] Camera online: %@", info.displayName);
            } else {
                info.isOnline = NO;
                info.lastError = error;
                if (error) {
                    info.statusMessage = [NSString stringWithFormat:@"✗ Error %ld", (long)error.code];
                    NSLog(@"[CameraList] Camera offline: %@ - %@", info.displayName, error.localizedDescription);
                } else {
                    info.statusMessage = @"✗ Not Playable";
                    NSLog(@"[CameraList] Camera not playable: %@", info.displayName);
                }
            }

            [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index]
                                       columnIndexes:[NSIndexSet indexSetWithIndex:0]];

            // Update status label
            NSInteger onlineCount = 0;
            NSInteger testingCount = 0;
            for (RTSPCameraInfo *cam in self.cameras) {
                if (cam.isOnline) onlineCount++;
                if (cam.isTesting) testingCount++;
            }

            if (testingCount == 0) {
                self.statusLabel.stringValue = [NSString stringWithFormat:@"%ld/%lu cameras online",
                                                (long)onlineCount, (unsigned long)self.cameras.count];
            }
        });
    }];
}

- (void)enableSelected:(id)sender {
    [self setSelectedCamerasEnabled:YES];
}

- (void)disableSelected:(id)sender {
    [self setSelectedCamerasEnabled:NO];
}

- (void)removeSelected:(id)sender {
    NSIndexSet *selectedRows = self.tableView.selectedRowIndexes;
    if (selectedRows.count == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"No Selection";
        alert.informativeText = @"Please select one or more cameras to remove.";
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }

    // Confirm removal
    NSAlert *confirmAlert = [[NSAlert alloc] init];
    confirmAlert.messageText = @"Remove Cameras";
    confirmAlert.informativeText = [NSString stringWithFormat:@"Are you sure you want to remove %lu camera(s)? This cannot be undone.", (unsigned long)selectedRows.count];
    confirmAlert.alertStyle = NSAlertStyleWarning;
    [confirmAlert addButtonWithTitle:@"Remove"];
    [confirmAlert addButtonWithTitle:@"Cancel"];

    if ([confirmAlert runModal] != NSAlertFirstButtonReturn) {
        return;
    }

    RTSPConfigurationManager *config = [RTSPConfigurationManager sharedManager];
    NSMutableArray<RTSPFeedMetadata *> *metadata = [config.manualFeedMetadata mutableCopy];

    // Remove in reverse order to maintain indices
    [selectedRows enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
        if (idx < metadata.count) {
            RTSPFeedMetadata *removed = metadata[idx];
            NSLog(@"[CameraList] Removing camera: %@", removed.url);
            [metadata removeObjectAtIndex:idx];
        }
    }];

    config.manualFeedMetadata = metadata;
    [config save];

    // Refresh the list
    [self refresh];

    self.statusLabel.stringValue = [NSString stringWithFormat:@"Removed %lu camera(s)", (unsigned long)selectedRows.count];
    NSLog(@"[CameraList] Removed %lu cameras", (unsigned long)selectedRows.count);
}

- (void)setSelectedCamerasEnabled:(BOOL)enabled {
    NSIndexSet *selectedRows = self.tableView.selectedRowIndexes;
    if (selectedRows.count == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"No Selection";
        alert.informativeText = @"Please select one or more cameras.";
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }

    RTSPConfigurationManager *config = [RTSPConfigurationManager sharedManager];
    NSMutableArray<RTSPFeedMetadata *> *metadata = [config.manualFeedMetadata mutableCopy];

    [selectedRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (idx < self.cameras.count && idx < metadata.count) {
            RTSPCameraInfo *info = self.cameras[idx];
            RTSPFeedMetadata *feed = metadata[idx];
            feed.enabled = enabled;
            info.enabled = enabled;
        }
    }];

    config.manualFeedMetadata = metadata;
    [config save];

    [self.tableView reloadData];

    NSLog(@"[CameraList] %@ %lu cameras", enabled ? @"Enabled" : @"Disabled", (unsigned long)selectedRows.count);
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.cameras.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < 0 || row >= self.cameras.count) return nil;

    RTSPCameraInfo *info = self.cameras[row];
    NSString *identifier = tableColumn.identifier;

    if ([identifier isEqualToString:@"status"]) {
        return info.statusMessage;
    } else if ([identifier isEqualToString:@"name"]) {
        return info.displayName;
    } else if ([identifier isEqualToString:@"category"]) {
        return info.category;
    } else if ([identifier isEqualToString:@"url"]) {
        // Truncate long URLs
        if (info.url.length > 60) {
            return [NSString stringWithFormat:@"%@...", [info.url substringToIndex:57]];
        }
        return info.url;
    } else if ([identifier isEqualToString:@"enabled"]) {
        return info.enabled ? @"Yes" : @"No";
    }

    return nil;
}

#pragma mark - NSTableViewDelegate

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < 0 || row >= self.cameras.count) return;

    RTSPCameraInfo *info = self.cameras[row];
    NSString *identifier = tableColumn.identifier;

    if ([identifier isEqualToString:@"status"] && [cell isKindOfClass:[NSTextFieldCell class]]) {
        NSTextFieldCell *textCell = (NSTextFieldCell *)cell;
        if (info.isTesting) {
            textCell.textColor = [NSColor orangeColor];
        } else if (info.isOnline) {
            textCell.textColor = [NSColor greenColor];
        } else if ([info.statusMessage isEqualToString:@"Unknown"]) {
            textCell.textColor = [NSColor grayColor];
        } else {
            textCell.textColor = [NSColor redColor];
        }
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    // Could enable/disable buttons based on selection
}

@end
