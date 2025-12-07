//
//  RTSPMLXPythonPreferencesView.m
//  RTSP Rotator
//
//  Preferences UI for Python MLX toolkit configuration
//

#import "RTSPMLXPythonPreferencesView.h"
#import <QuartzCore/QuartzCore.h>

@implementation RTSPMLXPythonPreferencesView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.settings = [RTSPMLXPythonSettings sharedSettings];
        self.settings.delegate = self;

        [self setupUI];
        [self refreshFromSettings];
    }
    return self;
}

- (void)setupUI {
    CGFloat yPos = self.bounds.size.height - 40;
    CGFloat margin = 20;
    CGFloat labelWidth = 120;
    CGFloat controlWidth = 300;

    // Title
    NSTextField *title = [[NSTextField alloc] initWithFrame:NSMakeRect(margin, yPos, 400, 24)];
    title.stringValue = @"Python MLX Toolkit Configuration";
    title.font = [NSFont boldSystemFontOfSize:16];
    title.bordered = NO;
    title.editable = NO;
    title.backgroundColor = [NSColor clearColor];
    [self addSubview:title];

    yPos -= 40;

    // Python path label
    NSTextField *pathLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(margin, yPos, labelWidth, 20)];
    pathLabel.stringValue = @"Python Path:";
    pathLabel.alignment = NSTextAlignmentRight;
    pathLabel.bordered = NO;
    pathLabel.editable = NO;
    pathLabel.backgroundColor = [NSColor clearColor];
    [self addSubview:pathLabel];

    // Python path field
    self.pythonPathField = [[NSTextField alloc] initWithFrame:NSMakeRect(margin + labelWidth + 10, yPos, controlWidth, 24)];
    self.pythonPathField.placeholderString = @"/usr/local/bin/python3";
    [self addSubview:self.pythonPathField];

    // Browse button
    self.browseButton = [[NSButton alloc] initWithFrame:NSMakeRect(margin + labelWidth + controlWidth + 20, yPos, 80, 24)];
    self.browseButton.title = @"Browse...";
    self.browseButton.bezelStyle = NSBezelStyleRounded;
    self.browseButton.target = self;
    self.browseButton.action = @selector(browsePythonPath:);
    [self addSubview:self.browseButton];

    yPos -= 40;

    // Status label
    NSTextField *statusTitleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(margin, yPos, labelWidth, 20)];
    statusTitleLabel.stringValue = @"Status:";
    statusTitleLabel.alignment = NSTextAlignmentRight;
    statusTitleLabel.bordered = NO;
    statusTitleLabel.editable = NO;
    statusTitleLabel.backgroundColor = [NSColor clearColor];
    [self addSubview:statusTitleLabel];

    // Status indicator (colored circle)
    self.statusIndicator = [[NSView alloc] initWithFrame:NSMakeRect(margin + labelWidth + 10, yPos + 2, 16, 16)];
    self.statusIndicator.wantsLayer = YES;
    self.statusIndicator.layer.cornerRadius = 8;
    self.statusIndicator.layer.backgroundColor = [[NSColor grayColor] CGColor];
    [self addSubview:self.statusIndicator];

    // Status text
    self.statusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(margin + labelWidth + 36, yPos, 250, 20)];
    self.statusLabel.stringValue = @"Not checked";
    self.statusLabel.bordered = NO;
    self.statusLabel.editable = NO;
    self.statusLabel.backgroundColor = [NSColor clearColor];
    [self addSubview:self.statusLabel];

    yPos -= 35;

    // Version info
    self.versionLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(margin + labelWidth + 10, yPos, 400, 20)];
    self.versionLabel.stringValue = @"";
    self.versionLabel.font = [NSFont systemFontOfSize:11];
    self.versionLabel.textColor = [NSColor secondaryLabelColor];
    self.versionLabel.bordered = NO;
    self.versionLabel.editable = NO;
    self.versionLabel.backgroundColor = [NSColor clearColor];
    [self addSubview:self.versionLabel];

    yPos -= 45;

    // Buttons row
    CGFloat buttonX = margin + labelWidth + 10;

    // Check button
    self.checkButton = [[NSButton alloc] initWithFrame:NSMakeRect(buttonX, yPos, 100, 28)];
    self.checkButton.title = @"Check Now";
    self.checkButton.bezelStyle = NSBezelStyleRounded;
    self.checkButton.target = self;
    self.checkButton.action = @selector(checkMLXStatus:);
    [self addSubview:self.checkButton];

    buttonX += 110;

    // Auto-detect button
    self.autoDetectButton = [[NSButton alloc] initWithFrame:NSMakeRect(buttonX, yPos, 110, 28)];
    self.autoDetectButton.title = @"Auto-Detect";
    self.autoDetectButton.bezelStyle = NSBezelStyleRounded;
    self.autoDetectButton.target = self;
    self.autoDetectButton.action = @selector(autoDetectPython:);
    [self addSubview:self.autoDetectButton];

    buttonX += 120;

    // Install button
    self.installButton = [[NSButton alloc] initWithFrame:NSMakeRect(buttonX, yPos, 100, 28)];
    self.installButton.title = @"Install MLX";
    self.installButton.bezelStyle = NSBezelStyleRounded;
    self.installButton.target = self;
    self.installButton.action = @selector(installMLX:);
    [self addSubview:self.installButton];

    yPos -= 40;

    // Auto-check checkbox
    self.autoCheckCheckbox = [[NSButton alloc] initWithFrame:NSMakeRect(margin + labelWidth + 10, yPos, 300, 20)];
    [self.autoCheckCheckbox setButtonType:NSButtonTypeSwitch];
    self.autoCheckCheckbox.title = @"Check MLX status on app launch";
    self.autoCheckCheckbox.target = self;
    self.autoCheckCheckbox.action = @selector(autoCheckChanged:);
    [self addSubview:self.autoCheckCheckbox];

    yPos -= 35;

    // Help text
    NSTextField *helpText = [[NSTextField alloc] initWithFrame:NSMakeRect(margin + labelWidth + 10, yPos, 450, 60)];
    helpText.stringValue = @"Python MLX toolkit enables advanced AI features. If not installed,\nthe app will use CoreML only. MLX provides additional flexibility\nfor custom models and Python-based AI processing.";
    helpText.font = [NSFont systemFontOfSize:11];
    helpText.textColor = [NSColor secondaryLabelColor];
    helpText.bordered = NO;
    helpText.editable = NO;
    helpText.backgroundColor = [NSColor clearColor];
    helpText.lineBreakMode = NSLineBreakByWordWrapping;
    helpText.maximumNumberOfLines = 3;
    [self addSubview:helpText];
}

- (void)browsePythonPath:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.title = @"Select Python Executable";
    panel.message = @"Choose the Python 3 executable";

    // Start in common directories
    panel.directoryURL = [NSURL fileURLWithPath:@"/usr/local/bin/"];

    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSURL *url = panel.URL;
            self.pythonPathField.stringValue = url.path;
            self.settings.pythonPath = url.path;
            [self.settings saveSettings];

            NSLog(@"[MLXPython] Selected Python path: %@", url.path);

            // Auto-check after selection
            [self checkMLXStatus:nil];
        }
    }];
}

- (void)checkMLXStatus:(id)sender {
    self.statusLabel.stringValue = @"Checking...";
    self.statusIndicator.layer.backgroundColor = [[NSColor systemBlueColor] CGColor];
    self.checkButton.enabled = NO;

    // Save current path
    self.settings.pythonPath = self.pythonPathField.stringValue;
    [self.settings saveSettings];

    [self.settings checkMLXAvailability:^(RTSPPythonMLXStatus status, NSError *error) {
        self.checkButton.enabled = YES;
        [self updateStatusIndicator];
    }];
}

- (void)autoDetectPython:(id)sender {
    self.statusLabel.stringValue = @"Auto-detecting...";
    self.autoDetectButton.enabled = NO;

    [self.settings autoDetect:^(BOOL success) {
        self.autoDetectButton.enabled = YES;

        if (success) {
            self.pythonPathField.stringValue = self.settings.pythonPath;
            [self updateStatusIndicator];

            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Auto-Detection Successful";
            alert.informativeText = [NSString stringWithFormat:@"Found working Python with MLX at:\n%@\n\nMLX Version: %@",
                                    self.settings.pythonPath, self.settings.mlxVersion];
            [alert runModal];
        } else {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Auto-Detection Failed";
            alert.informativeText = @"Could not find Python with MLX installed.\n\nPlease install MLX or manually specify Python path.";
            alert.alertStyle = NSAlertStyleWarning;
            [alert runModal];
        }
    }];
}

- (void)installMLX:(id)sender {
    NSAlert *confirmAlert = [[NSAlert alloc] init];
    confirmAlert.messageText = @"Install MLX Toolkit";
    confirmAlert.informativeText = @"This will run: pip install mlx\n\nThis may take a few minutes. Continue?";
    [confirmAlert addButtonWithTitle:@"Install"];
    [confirmAlert addButtonWithTitle:@"Cancel"];

    if ([confirmAlert runModal] != NSAlertFirstButtonReturn) {
        return;
    }

    self.installButton.enabled = NO;
    self.statusLabel.stringValue = @"Installing MLX...";

    [self.settings installMLXToolkit:^(BOOL success, NSString *output, NSError *error) {
        self.installButton.enabled = YES;

        NSAlert *resultAlert = [[NSAlert alloc] init];

        if (success) {
            resultAlert.messageText = @"Installation Successful";
            resultAlert.informativeText = @"MLX toolkit has been installed successfully!";
            resultAlert.alertStyle = NSAlertStyleInformational;

            // Refresh status
            [self checkMLXStatus:nil];
        } else {
            resultAlert.messageText = @"Installation Failed";
            resultAlert.informativeText = [NSString stringWithFormat:@"Error: %@\n\nOutput:\n%@",
                                          error ?: @"Unknown error", output ?: @""];
            resultAlert.alertStyle = NSAlertStyleCritical;
        }

        [resultAlert runModal];
    }];
}

- (void)autoCheckChanged:(id)sender {
    self.settings.autoCheckOnLaunch = (self.autoCheckCheckbox.state == NSControlStateValueOn);
    [self.settings saveSettings];
}

- (void)refreshFromSettings {
    self.pythonPathField.stringValue = self.settings.pythonPath;
    self.autoCheckCheckbox.state = self.settings.autoCheckOnLaunch ? NSControlStateValueOn : NSControlStateValueOff;
    [self updateStatusIndicator];
}

- (void)updateStatusIndicator {
    self.statusLabel.stringValue = [self.settings statusMessage];
    self.statusIndicator.layer.backgroundColor = [[self.settings statusColor] CGColor];

    // Update version info
    NSMutableString *versionInfo = [NSMutableString string];

    if (self.settings.pythonVersion) {
        [versionInfo appendFormat:@"Python: %@", self.settings.pythonVersion];
    }

    if (self.settings.mlxVersion) {
        if (versionInfo.length > 0) [versionInfo appendString:@"  |  "];
        [versionInfo appendFormat:@"MLX: %@", self.settings.mlxVersion];
    }

    if (self.settings.lastCheckTime) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterNoStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;

        if (versionInfo.length > 0) [versionInfo appendString:@"  |  "];
        [versionInfo appendFormat:@"Last checked: %@", [formatter stringFromDate:self.settings.lastCheckTime]];
    }

    self.versionLabel.stringValue = versionInfo;

    // Enable/disable install button based on status
    BOOL pythonExists = (self.settings.status != RTSPPythonMLXStatusNotFound &&
                         self.settings.status != RTSPPythonMLXStatusUnknown);
    self.installButton.enabled = pythonExists;
}

#pragma mark - RTSPMLXPythonSettingsDelegate

- (void)mlxPythonSettings:(RTSPMLXPythonSettings *)settings didUpdateStatus:(RTSPPythonMLXStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateStatusIndicator];
    });
}

- (void)mlxPythonSettings:(RTSPMLXPythonSettings *)settings didDetectMLXVersion:(NSString *)version {
    NSLog(@"[MLXPythonView] Detected MLX version: %@", version);
}

@end
