//
//  RTSPMLXPythonPreferencesView.h
//  RTSP Rotator
//
//  Preferences UI for Python MLX toolkit configuration
//

#import <Cocoa/Cocoa.h>
#import "RTSPMLXPythonSettings.h"

NS_ASSUME_NONNULL_BEGIN

/// Preferences view for Python MLX configuration
@interface RTSPMLXPythonPreferencesView : NSView <RTSPMLXPythonSettingsDelegate>

/// Python path text field
@property (nonatomic, strong) NSTextField *pythonPathField;

/// Status indicator (colored circle)
@property (nonatomic, strong) NSView *statusIndicator;

/// Status label
@property (nonatomic, strong) NSTextField *statusLabel;

/// Check button
@property (nonatomic, strong) NSButton *checkButton;

/// Auto-detect button
@property (nonatomic, strong) NSButton *autoDetectButton;

/// Install button
@property (nonatomic, strong) NSButton *installButton;

/// Browse button
@property (nonatomic, strong) NSButton *browseButton;

/// Auto-check checkbox
@property (nonatomic, strong) NSButton *autoCheckCheckbox;

/// MLX version label
@property (nonatomic, strong) NSTextField *versionLabel;

/// Python MLX settings instance
@property (nonatomic, strong) RTSPMLXPythonSettings *settings;

/**
 * Update status indicator
 */
- (void)updateStatusIndicator;

/**
 * Refresh all fields from settings
 */
- (void)refreshFromSettings;

@end

NS_ASSUME_NONNULL_END
