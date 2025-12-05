//
//  RTSPUniFiProtectPreferences.m
//  RTSP Rotator
//
//  UniFi Protect configuration and camera import UI
//

#import "RTSPUniFiProtectPreferences.h"
#import "RTSPUniFiProtectAdapter.h"
#import "RTSPCameraDiagnostics.h"

@interface RTSPUniFiProtectPreferences () <NSTableViewDataSource, NSTableViewDelegate, RTSPUniFiProtectAdapterDelegate>

// Configuration fields
@property (nonatomic, strong) NSTextField *hostField;
@property (nonatomic, strong) NSTextField *portField;
@property (nonatomic, strong) NSTextField *usernameField;
@property (nonatomic, strong) NSSecureTextField *passwordField;
@property (nonatomic, strong) NSButton *httpsCheckbox;
@property (nonatomic, strong) NSButton *verifySSLCheckbox;

// Buttons
@property (nonatomic, strong) NSButton *connectButton;
@property (nonatomic, strong) NSButton *disconnectButton;
@property (nonatomic, strong) NSButton *refreshButton;
@property (nonatomic, strong) NSButton *importButton;
@property (nonatomic, strong) NSButton *importAllButton;
@property (nonatomic, strong) NSButton *testButton;

// Status labels
@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, strong) NSProgressIndicator *progressIndicator;

// Camera list
@property (nonatomic, strong) NSTableView *camerasTableView;
@property (nonatomic, strong) NSArray<RTSPUniFiCamera *> *cameras;

// Adapter
@property (nonatomic, strong) RTSPUniFiProtectAdapter *adapter;

@end

@implementation RTSPUniFiProtectPreferences

+ (instancetype)sharedController {
    static RTSPUniFiProtectPreferences *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RTSPUniFiProtectPreferences alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    NSRect frame = NSMakeRect(0, 0, 700, 600);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:(NSWindowStyleMaskTitled |
                                                              NSWindowStyleMaskClosable |
                                                              NSWindowStyleMaskResizable)
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];

    self = [super initWithWindow:window];
    if (self) {
        _adapter = [RTSPUniFiProtectAdapter sharedAdapter];
        _adapter.delegate = self;
        _cameras = @[];
        [self createPreferencesWindowContents];
    }
    return self;
}

- (void)createPreferencesWindowContents {
    self.window.title = @"UniFi Protect Configuration";
    self.window.minSize = NSMakeSize(600, 500);
    [self.window center];

    NSView *contentView = self.window.contentView;
    contentView.wantsLayer = YES;

    NSRect frame = self.window.frame;
    CGFloat yPos = frame.size.height - 30;
    CGFloat leftMargin = 20;
    CGFloat rightMargin = 20;
    CGFloat contentWidth = frame.size.width - leftMargin - rightMargin;

    // Title
    NSTextField *titleLabel = [self createBoldLabel:@"UniFi Protect Integration"
                                             frame:NSMakeRect(leftMargin, yPos, contentWidth, 24)];
    titleLabel.font = [NSFont boldSystemFontOfSize:16];
    [contentView addSubview:titleLabel];
    yPos -= 40;

    // Connection Settings Section
    NSBox *connectionBox = [[NSBox alloc] initWithFrame:NSMakeRect(leftMargin, yPos - 200, contentWidth, 200)];
    connectionBox.title = @"Controller Settings";
    connectionBox.titlePosition = NSAtTop;
    [contentView addSubview:connectionBox];

    NSView *connectionView = connectionBox.contentView;
    CGFloat boxYPos = 160;
    CGFloat labelWidth = 100;
    CGFloat fieldWidth = contentWidth - labelWidth - 60;

    // Host
    [connectionView addSubview:[self createLabel:@"Host:" frame:NSMakeRect(10, boxYPos, labelWidth, 20)]];
    self.hostField = [[NSTextField alloc] initWithFrame:NSMakeRect(labelWidth + 10, boxYPos, fieldWidth, 22)];
    self.hostField.placeholderString = @"192.168.1.1 or protect.local";
    self.hostField.stringValue = self.adapter.controllerHost ?: @"";
    [connectionView addSubview:self.hostField];
    boxYPos -= 30;

    // Port
    [connectionView addSubview:[self createLabel:@"Port:" frame:NSMakeRect(10, boxYPos, labelWidth, 20)]];
    self.portField = [[NSTextField alloc] initWithFrame:NSMakeRect(labelWidth + 10, boxYPos, 80, 22)];
    self.portField.placeholderString = @"443";
    self.portField.integerValue = self.adapter.controllerPort;
    [connectionView addSubview:self.portField];
    boxYPos -= 30;

    // Username
    [connectionView addSubview:[self createLabel:@"Username:" frame:NSMakeRect(10, boxYPos, labelWidth, 20)]];
    self.usernameField = [[NSTextField alloc] initWithFrame:NSMakeRect(labelWidth + 10, boxYPos, fieldWidth, 22)];
    self.usernameField.placeholderString = @"UniFi Protect username";
    self.usernameField.stringValue = self.adapter.username ?: @"";
    [connectionView addSubview:self.usernameField];
    boxYPos -= 30;

    // Password
    [connectionView addSubview:[self createLabel:@"Password:" frame:NSMakeRect(10, boxYPos, labelWidth, 20)]];
    self.passwordField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(labelWidth + 10, boxYPos, fieldWidth, 22)];
    self.passwordField.placeholderString = @"UniFi Protect password";
    self.passwordField.stringValue = self.adapter.password ?: @"";
    [connectionView addSubview:self.passwordField];
    boxYPos -= 30;

    // HTTPS checkbox
    self.httpsCheckbox = [[NSButton alloc] initWithFrame:NSMakeRect(labelWidth + 10, boxYPos, 150, 20)];
    [self.httpsCheckbox setButtonType:NSButtonTypeSwitch];
    self.httpsCheckbox.title = @"Use HTTPS";
    self.httpsCheckbox.state = self.adapter.useHTTPS ? NSControlStateValueOn : NSControlStateValueOff;
    [connectionView addSubview:self.httpsCheckbox];

    // Verify SSL checkbox
    self.verifySSLCheckbox = [[NSButton alloc] initWithFrame:NSMakeRect(labelWidth + 180, boxYPos, 200, 20)];
    [self.verifySSLCheckbox setButtonType:NSButtonTypeSwitch];
    self.verifySSLCheckbox.title = @"Verify SSL Certificate";
    self.verifySSLCheckbox.state = self.adapter.verifySSL ? NSControlStateValueOn : NSControlStateValueOff;
    [connectionView addSubview:self.verifySSLCheckbox];
    boxYPos -= 35;

    // Connect/Disconnect buttons
    self.connectButton = [self createButton:@"Connect & Discover Cameras"
                                     frame:NSMakeRect(labelWidth + 10, boxYPos, 200, 28)
                                    action:@selector(connect:)];
    self.connectButton.keyEquivalent = @"\r";
    [connectionView addSubview:self.connectButton];

    self.disconnectButton = [self createButton:@"Disconnect"
                                        frame:NSMakeRect(labelWidth + 220, boxYPos, 120, 28)
                                       action:@selector(disconnect:)];
    self.disconnectButton.enabled = NO;
    [connectionView addSubview:self.disconnectButton];

    yPos -= 220;

    // Status Section
    self.statusLabel = [self createLabel:@"Not connected"
                                  frame:NSMakeRect(leftMargin, yPos, contentWidth - 40, 20)];
    self.statusLabel.textColor = [NSColor secondaryLabelColor];
    [contentView addSubview:self.statusLabel];

    self.progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(contentWidth - 10, yPos + 2, 16, 16)];
    self.progressIndicator.style = NSProgressIndicatorStyleSpinning;
    self.progressIndicator.displayedWhenStopped = NO;
    [contentView addSubview:self.progressIndicator];

    yPos -= 30;

    // Cameras Section
    NSBox *camerasBox = [[NSBox alloc] initWithFrame:NSMakeRect(leftMargin, yPos - 230, contentWidth, 230)];
    camerasBox.title = @"Discovered Cameras";
    camerasBox.titlePosition = NSAtTop;
    [contentView addSubview:camerasBox];

    NSView *camerasView = camerasBox.contentView;

    // Camera table view
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(10, 40, contentWidth - 40, 150)];
    scrollView.hasVerticalScroller = YES;
    scrollView.autohidesScrollers = YES;
    scrollView.borderType = NSBezelBorder;
    scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    self.camerasTableView = [[NSTableView alloc] initWithFrame:scrollView.bounds];

    // Name column
    NSTableColumn *nameColumn = [[NSTableColumn alloc] initWithIdentifier:@"name"];
    nameColumn.title = @"Camera Name";
    nameColumn.width = 200;
    [self.camerasTableView addTableColumn:nameColumn];

    // Model column
    NSTableColumn *modelColumn = [[NSTableColumn alloc] initWithIdentifier:@"model"];
    modelColumn.title = @"Model";
    modelColumn.width = 120;
    [self.camerasTableView addTableColumn:modelColumn];

    // IP column
    NSTableColumn *ipColumn = [[NSTableColumn alloc] initWithIdentifier:@"ip"];
    ipColumn.title = @"IP Address";
    ipColumn.width = 120;
    [self.camerasTableView addTableColumn:ipColumn];

    // Status column
    NSTableColumn *statusColumn = [[NSTableColumn alloc] initWithIdentifier:@"status"];
    statusColumn.title = @"Status";
    statusColumn.width = 80;
    [self.camerasTableView addTableColumn:statusColumn];

    self.camerasTableView.delegate = self;
    self.camerasTableView.dataSource = self;
    self.camerasTableView.allowsMultipleSelection = YES;
    scrollView.documentView = self.camerasTableView;
    [camerasView addSubview:scrollView];

    // Action buttons
    CGFloat buttonY = 10;
    CGFloat buttonX = 10;

    self.refreshButton = [self createButton:@"Refresh"
                                     frame:NSMakeRect(buttonX, buttonY, 80, 24)
                                    action:@selector(refreshCameras:)];
    self.refreshButton.enabled = NO;
    [camerasView addSubview:self.refreshButton];
    buttonX += 90;

    self.importButton = [self createButton:@"Import Selected"
                                    frame:NSMakeRect(buttonX, buttonY, 120, 24)
                                   action:@selector(importSelected:)];
    self.importButton.enabled = NO;
    [camerasView addSubview:self.importButton];
    buttonX += 130;

    self.importAllButton = [self createButton:@"Import All"
                                       frame:NSMakeRect(buttonX, buttonY, 100, 24)
                                      action:@selector(importAll:)];
    self.importAllButton.enabled = NO;
    [camerasView addSubview:self.importAllButton];
    buttonX += 110;

    self.testButton = [self createButton:@"Test Selected"
                                  frame:NSMakeRect(buttonX, buttonY, 110, 24)
                                 action:@selector(testSelected:)];
    self.testButton.enabled = NO;
    [camerasView addSubview:self.testButton];

    yPos -= 250;

    // Help text at bottom
    NSTextField *helpText = [self createLabel:@"Connect to your UniFi Protect controller to automatically discover and import cameras. Imported cameras will be added to your manual feeds list."
                                       frame:NSMakeRect(leftMargin, 20, contentWidth, 40)];
    helpText.textColor = [NSColor secondaryLabelColor];
    helpText.font = [NSFont systemFontOfSize:11];
    helpText.lineBreakMode = NSLineBreakByWordWrapping;
    [contentView addSubview:helpText];
}

#pragma mark - Actions

- (void)connect:(id)sender {
    // Save configuration
    self.adapter.controllerHost = self.hostField.stringValue;
    self.adapter.controllerPort = self.portField.integerValue;
    self.adapter.username = self.usernameField.stringValue;
    self.adapter.password = self.passwordField.stringValue;
    self.adapter.useHTTPS = (self.httpsCheckbox.state == NSControlStateValueOn);
    self.adapter.verifySSL = (self.verifySSLCheckbox.state == NSControlStateValueOn);
    [self.adapter saveConfiguration];

    // Update UI
    self.connectButton.enabled = NO;
    self.statusLabel.stringValue = @"Connecting...";
    self.statusLabel.textColor = [NSColor secondaryLabelColor];
    [self.progressIndicator startAnimation:nil];

    // Authenticate and discover
    [self.adapter authenticateWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            [self.adapter discoverCamerasWithCompletion:^(NSArray<RTSPUniFiCamera *> *cameras, NSError *discError) {
                if (cameras) {
                    self.cameras = cameras;
                    [self.camerasTableView reloadData];

                    self.statusLabel.stringValue = [NSString stringWithFormat:@"Connected - %lu cameras found", (unsigned long)cameras.count];
                    self.statusLabel.textColor = [NSColor systemGreenColor];

                    self.disconnectButton.enabled = YES;
                    self.refreshButton.enabled = YES;
                    self.importButton.enabled = YES;
                    self.importAllButton.enabled = YES;
                    self.testButton.enabled = YES;
                } else {
                    self.statusLabel.stringValue = [NSString stringWithFormat:@"Discovery failed: %@", discError.localizedDescription];
                    self.statusLabel.textColor = [NSColor systemRedColor];
                    self.connectButton.enabled = YES;
                }
                [self.progressIndicator stopAnimation:nil];
            }];
        } else {
            self.statusLabel.stringValue = [NSString stringWithFormat:@"Connection failed: %@", error.localizedDescription];
            self.statusLabel.textColor = [NSColor systemRedColor];
            self.connectButton.enabled = YES;
            [self.progressIndicator stopAnimation:nil];
        }
    }];
}

- (void)disconnect:(id)sender {
    [self.adapter logout];

    self.cameras = @[];
    [self.camerasTableView reloadData];

    self.statusLabel.stringValue = @"Disconnected";
    self.statusLabel.textColor = [NSColor secondaryLabelColor];

    self.connectButton.enabled = YES;
    self.disconnectButton.enabled = NO;
    self.refreshButton.enabled = NO;
    self.importButton.enabled = NO;
    self.importAllButton.enabled = NO;
    self.testButton.enabled = NO;
}

- (void)refreshCameras:(id)sender {
    self.refreshButton.enabled = NO;
    self.statusLabel.stringValue = @"Refreshing...";
    [self.progressIndicator startAnimation:nil];

    [self.adapter discoverCamerasWithCompletion:^(NSArray<RTSPUniFiCamera *> *cameras, NSError *error) {
        self.refreshButton.enabled = YES;
        [self.progressIndicator stopAnimation:nil];

        if (cameras) {
            self.cameras = cameras;
            [self.camerasTableView reloadData];
            self.statusLabel.stringValue = [NSString stringWithFormat:@"Refreshed - %lu cameras found", (unsigned long)self.cameras.count];
            self.statusLabel.textColor = [NSColor systemGreenColor];
        } else {
            self.statusLabel.stringValue = [NSString stringWithFormat:@"Refresh failed: %@", error.localizedDescription];
            self.statusLabel.textColor = [NSColor systemRedColor];
        }
    }];
}

- (void)importSelected:(id)sender {
    NSIndexSet *selectedRows = self.camerasTableView.selectedRowIndexes;
    if (selectedRows.count == 0) {
        self.statusLabel.stringValue = @"Please select cameras to import";
        self.statusLabel.textColor = [NSColor systemOrangeColor];
        return;
    }

    NSMutableArray *selectedCameras = [NSMutableArray array];
    [selectedRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [selectedCameras addObject:self.cameras[idx]];
    }];

    [self importCameras:selectedCameras];
}

- (void)importAll:(id)sender {
    if (self.cameras.count == 0) {
        self.statusLabel.stringValue = @"No cameras to import";
        self.statusLabel.textColor = [NSColor systemOrangeColor];
        return;
    }

    [self importCameras:self.cameras];
}

- (void)importCameras:(NSArray<RTSPUniFiCamera *> *)cameras {
    self.statusLabel.stringValue = @"Importing cameras...";
    self.statusLabel.textColor = [NSColor secondaryLabelColor];
    [self.progressIndicator startAnimation:nil];

    [self.adapter importCameras:cameras completion:^(NSInteger importedCount) {
        [self.progressIndicator stopAnimation:nil];

        if (importedCount > 0) {
            self.statusLabel.stringValue = [NSString stringWithFormat:@"✓ Imported %ld camera%@", (long)importedCount, importedCount == 1 ? @"" : @"s"];
            self.statusLabel.textColor = [NSColor systemGreenColor];

            // Show alert
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Cameras Imported";
            alert.informativeText = [NSString stringWithFormat:@"Successfully imported %ld camera%@ to your feed list.", (long)importedCount, importedCount == 1 ? @"" : @"s"];
            alert.alertStyle = NSAlertStyleInformational;
            [alert addButtonWithTitle:@"OK"];
            [alert runModal];
        } else {
            self.statusLabel.stringValue = @"No new cameras to import (all already exist)";
            self.statusLabel.textColor = [NSColor systemOrangeColor];
        }
    }];
}

- (void)testSelected:(id)sender {
    NSIndexSet *selectedRows = self.camerasTableView.selectedRowIndexes;
    if (selectedRows.count == 0) {
        self.statusLabel.stringValue = @"Please select cameras to test";
        self.statusLabel.textColor = [NSColor systemOrangeColor];
        return;
    }

    self.statusLabel.stringValue = @"Testing connections...";
    self.statusLabel.textColor = [NSColor secondaryLabelColor];
    [self.progressIndicator startAnimation:nil];

    __block NSInteger testsCompleted = 0;
    __block NSInteger testsSuccessful = 0;
    NSInteger totalTests = selectedRows.count;

    [selectedRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        RTSPUniFiCamera *camera = self.cameras[idx];
        [self.adapter testCameraConnection:camera completion:^(BOOL success, NSTimeInterval latency, NSError *error) {
            testsCompleted++;
            if (success) testsSuccessful++;

            if (testsCompleted == totalTests) {
                [self.progressIndicator stopAnimation:nil];
                self.statusLabel.stringValue = [NSString stringWithFormat:@"Test complete: %ld/%ld cameras reachable", (long)testsSuccessful, (long)totalTests];
                self.statusLabel.textColor = (testsSuccessful == totalTests) ? [NSColor systemGreenColor] : [NSColor systemOrangeColor];
            }
        }];
    }];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.cameras.count;
}

- (nullable id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row >= self.cameras.count) return nil;

    RTSPUniFiCamera *camera = self.cameras[row];
    NSString *identifier = tableColumn.identifier;

    if ([identifier isEqualToString:@"name"]) {
        return camera.name;
    } else if ([identifier isEqualToString:@"model"]) {
        return camera.model;
    } else if ([identifier isEqualToString:@"ip"]) {
        return camera.ipAddress;
    } else if ([identifier isEqualToString:@"status"]) {
        return camera.isOnline ? @"Online" : @"Offline";
    }

    return nil;
}

#pragma mark - NSTableViewDelegate

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([tableColumn.identifier isEqualToString:@"status"]) {
        RTSPUniFiCamera *camera = self.cameras[row];
        NSTextFieldCell *textCell = (NSTextFieldCell *)cell;
        textCell.textColor = camera.isOnline ? [NSColor systemGreenColor] : [NSColor systemRedColor];
    }
}

#pragma mark - RTSPUniFiProtectAdapterDelegate

- (void)unifiProtectAdapterDidAuthenticate:(RTSPUniFiProtectAdapter *)adapter {
    NSLog(@"[UniFiPrefs] Authentication successful");
}

- (void)unifiProtectAdapter:(RTSPUniFiProtectAdapter *)adapter didFailAuthenticationWithError:(NSError *)error {
    NSLog(@"[UniFiPrefs] Authentication failed: %@", error.localizedDescription);
}

- (void)unifiProtectAdapter:(RTSPUniFiProtectAdapter *)adapter didDiscoverCameras:(NSArray<RTSPUniFiCamera *> *)cameras {
    NSLog(@"[UniFiPrefs] Discovered %lu cameras", (unsigned long)cameras.count);
}

#pragma mark - Window Management

- (void)showWindow:(id)sender {
    [self.window makeKeyAndOrderFront:sender];
}

#pragma mark - Helper Methods

- (NSTextField *)createLabel:(NSString *)text frame:(NSRect)frame {
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    label.stringValue = text;
    label.editable = NO;
    label.selectable = NO;
    label.bezeled = NO;
    label.drawsBackground = NO;
    return label;
}

- (NSTextField *)createBoldLabel:(NSString *)text frame:(NSRect)frame {
    NSTextField *label = [self createLabel:text frame:frame];
    label.font = [NSFont boldSystemFontOfSize:13];
    return label;
}

- (NSButton *)createButton:(NSString *)title frame:(NSRect)frame action:(SEL)action {
    NSButton *button = [[NSButton alloc] initWithFrame:frame];
    [button setButtonType:NSButtonTypeMomentaryPushIn];
    button.bezelStyle = NSBezelStyleRounded;
    button.title = title;
    button.target = self;
    button.action = action;
    return button;
}

@end
