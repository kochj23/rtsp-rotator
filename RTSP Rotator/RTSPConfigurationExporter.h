//
//  RTSPConfigurationExporter.h
//  RTSP Rotator
//
//  Cross-platform configuration export/import system
//  Supports JSON export for use with iOS, tvOS, and screensaver versions
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Result handler for export operations
typedef void (^RTSPConfigurationExportCompletion)(BOOL success, NSString * _Nullable filePath, NSError * _Nullable error);

/// Result handler for import operations
typedef void (^RTSPConfigurationImportCompletion)(BOOL success, NSError * _Nullable error);

/// Result handler for upload operations
typedef void (^RTSPConfigurationUploadCompletion)(BOOL success, NSString * _Nullable uploadURL, NSError * _Nullable error);

/// Manages export and import of all RTSP Rotator configuration
/// Supports cross-platform JSON format for iOS, tvOS, and screensaver apps
@interface RTSPConfigurationExporter : NSObject

#pragma mark - Singleton

/// Shared instance
+ (instancetype)sharedExporter;

#pragma mark - Export to File

/// Export complete configuration to JSON file
/// @param filePath Destination file path (use nil for default location)
/// @param completion Completion handler with success status
- (void)exportConfigurationToFile:(nullable NSString *)filePath
                       completion:(RTSPConfigurationExportCompletion)completion;

/// Get default export file path
/// @return Path in ~/Library/Application Support/RTSP Rotator/config.json
- (NSString *)defaultExportPath;

#pragma mark - Import from File

/// Import configuration from JSON file
/// @param filePath Source file path
/// @param merge If YES, merges with existing config; if NO, replaces
/// @param completion Completion handler with success status
- (void)importConfigurationFromFile:(NSString *)filePath
                              merge:(BOOL)merge
                         completion:(RTSPConfigurationImportCompletion)completion;

#pragma mark - Import from URL

/// Import configuration from remote URL
/// @param urlString URL to fetch configuration from
/// @param merge If YES, merges with existing config; if NO, replaces
/// @param completion Completion handler with success status
- (void)importConfigurationFromURL:(NSString *)urlString
                             merge:(BOOL)merge
                        completion:(RTSPConfigurationImportCompletion)completion;

#pragma mark - Upload to URL

/// Upload configuration to remote URL (HTTP POST or PUT)
/// @param urlString Destination URL
/// @param method HTTP method ("POST" or "PUT")
/// @param completion Completion handler with success status
- (void)uploadConfigurationToURL:(NSString *)urlString
                          method:(NSString *)method
                      completion:(RTSPConfigurationUploadCompletion)completion;

#pragma mark - Auto-Sync

/// Enable/disable automatic sync
@property (nonatomic, assign) BOOL autoSyncEnabled;

/// Auto-sync interval in seconds (default: 300 = 5 minutes)
@property (nonatomic, assign) NSTimeInterval autoSyncInterval;

/// URL for auto-sync (both download and upload)
@property (nonatomic, strong, nullable) NSString *autoSyncURL;

/// Upload method for auto-sync ("POST" or "PUT")
@property (nonatomic, strong) NSString *autoSyncUploadMethod;

/// Start auto-sync timer
- (void)startAutoSync;

/// Stop auto-sync timer
- (void)stopAutoSync;

/// Manually trigger sync now
- (void)syncNow:(nullable void (^)(BOOL downloadSuccess, BOOL uploadSuccess))completion;

#pragma mark - JSON Generation

/// Generate JSON dictionary from current configuration
/// @return Dictionary containing all settings
- (NSDictionary *)generateConfigurationDictionary;

/// Generate JSON data from current configuration
/// @param error Error pointer
/// @return JSON data or nil on error
- (nullable NSData *)generateConfigurationJSON:(NSError **)error;

#pragma mark - JSON Parsing

/// Apply configuration from dictionary
/// @param dictionary Configuration dictionary
/// @param merge If YES, merges with existing; if NO, replaces
/// @param error Error pointer
/// @return YES if successful
- (BOOL)applyConfigurationFromDictionary:(NSDictionary *)dictionary
                                   merge:(BOOL)merge
                                   error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
