//
//  RTSPMLXPythonSettings.h
//  RTSP Rotator
//
//  Python MLX toolkit configuration and health check
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTSPPythonMLXStatus) {
    RTSPPythonMLXStatusUnknown,      // Not yet checked
    RTSPPythonMLXStatusAvailable,    // Working correctly
    RTSPPythonMLXStatusNotFound,     // Python not found
    RTSPPythonMLXStatusMLXMissing,   // Python found, MLX not installed
    RTSPPythonMLXStatusError         // Other error
};

@class RTSPMLXPythonSettings;

/// Delegate for Python MLX status updates
@protocol RTSPMLXPythonSettingsDelegate <NSObject>
@optional
- (void)mlxPythonSettings:(RTSPMLXPythonSettings *)settings didUpdateStatus:(RTSPPythonMLXStatus)status;
- (void)mlxPythonSettings:(RTSPMLXPythonSettings *)settings didDetectMLXVersion:(NSString *)version;
@end

/// Python MLX toolkit configuration manager
@interface RTSPMLXPythonSettings : NSObject

/// Shared instance
+ (instancetype)sharedSettings;

/// Delegate
@property (nonatomic, weak) id<RTSPMLXPythonSettingsDelegate> delegate;

/// Python executable path (e.g., /usr/local/bin/python3)
@property (nonatomic, copy) NSString *pythonPath;

/// MLX toolkit installation path (usually auto-detected)
@property (nonatomic, copy, nullable) NSString *mlxPath;

/// Current MLX status
@property (nonatomic, readonly) RTSPPythonMLXStatus status;

/// MLX version string (if available)
@property (nonatomic, copy, readonly, nullable) NSString *mlxVersion;

/// Python version string
@property (nonatomic, copy, readonly, nullable) NSString *pythonVersion;

/// Last check timestamp
@property (nonatomic, strong, readonly, nullable) NSDate *lastCheckTime;

/// Auto-check on launch
@property (nonatomic, assign) BOOL autoCheckOnLaunch;

/**
 * Check Python MLX toolkit availability
 * @param completion Completion handler with status and error
 */
- (void)checkMLXAvailability:(void (^)(RTSPPythonMLXStatus status, NSError * _Nullable error))completion;

/**
 * Check Python MLX toolkit availability synchronously
 * @return Current status
 */
- (RTSPPythonMLXStatus)checkMLXAvailabilitySync;

/**
 * Get user-friendly status message
 * @return Status description
 */
- (NSString *)statusMessage;

/**
 * Get status indicator color
 * @return NSColor for status light
 */
- (NSColor *)statusColor;

/**
 * Reset to default Python path
 */
- (void)resetToDefaultPythonPath;

/**
 * Attempt to auto-detect Python and MLX
 * @param completion Completion handler with success status
 */
- (void)autoDetect:(void (^)(BOOL success))completion;

/**
 * Install MLX via pip (requires Python)
 * @param completion Completion handler with success status
 */
- (void)installMLXToolkit:(void (^)(BOOL success, NSString * _Nullable output, NSError * _Nullable error))completion;

/**
 * Save settings to user defaults
 */
- (void)saveSettings;

/**
 * Load settings from user defaults
 */
- (void)loadSettings;

@end

NS_ASSUME_NONNULL_END
