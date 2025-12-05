//
//  RTSPKeychainManager.h
//  RTSP Rotator
//
//  Secure password storage using macOS Keychain
//  Created as part of security improvements
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Manages secure storage and retrieval of sensitive credentials using macOS Keychain
 *
 * This class provides a simple interface for storing passwords and other sensitive
 * data securely in the macOS Keychain. It handles all the complexity of the Security
 * framework and provides automatic cleanup on deletion.
 *
 * @discussion All methods are thread-safe and can be called from any queue.
 *
 * Example usage:
 * @code
 * // Store a password
 * BOOL success = [RTSPKeychainManager setPassword:@"secret123"
 *                                      forAccount:@"UniFi_Password"
 *                                         service:@"com.rtsp-rotator.unifi"];
 *
 * // Retrieve a password
 * NSString *password = [RTSPKeychainManager passwordForAccount:@"UniFi_Password"
 *                                                      service:@"com.rtsp-rotator.unifi"];
 *
 * // Delete a password
 * [RTSPKeychainManager deletePasswordForAccount:@"UniFi_Password"
 *                                       service:@"com.rtsp-rotator.unifi"];
 * @endcode
 */
@interface RTSPKeychainManager : NSObject

#pragma mark - Password Storage

/**
 * Stores a password securely in the Keychain
 *
 * @param password The password to store (required)
 * @param account The account identifier (e.g., "UniFi_Password")
 * @param service The service identifier (e.g., "com.rtsp-rotator.unifi")
 * @return YES if the password was stored successfully, NO otherwise
 *
 * @note If a password already exists for this account/service, it will be updated
 */
+ (BOOL)setPassword:(NSString *)password
         forAccount:(NSString *)account
            service:(NSString *)service;

/**
 * Retrieves a password from the Keychain
 *
 * @param account The account identifier
 * @param service The service identifier
 * @return The stored password, or nil if not found or on error
 */
+ (nullable NSString *)passwordForAccount:(NSString *)account
                                  service:(NSString *)service;

/**
 * Deletes a password from the Keychain
 *
 * @param account The account identifier
 * @param service The service identifier
 * @return YES if deleted successfully or didn't exist, NO on error
 */
+ (BOOL)deletePasswordForAccount:(NSString *)account
                         service:(NSString *)service;

#pragma mark - Generic Data Storage

/**
 * Stores arbitrary data securely in the Keychain
 *
 * @param data The data to store
 * @param account The account identifier
 * @param service The service identifier
 * @return YES if stored successfully, NO otherwise
 */
+ (BOOL)setData:(NSData *)data
     forAccount:(NSString *)account
        service:(NSString *)service;

/**
 * Retrieves data from the Keychain
 *
 * @param account The account identifier
 * @param service The service identifier
 * @return The stored data, or nil if not found
 */
+ (nullable NSData *)dataForAccount:(NSString *)account
                            service:(NSString *)service;

#pragma mark - Convenience Methods

/**
 * Checks if a password exists for the given account/service
 *
 * @param account The account identifier
 * @param service The service identifier
 * @return YES if a password exists, NO otherwise
 */
+ (BOOL)hasPasswordForAccount:(NSString *)account
                      service:(NSString *)service;

/**
 * Migrates password from NSUserDefaults to Keychain
 *
 * This is a helper method to migrate existing passwords stored insecurely
 * in NSUserDefaults to the secure Keychain.
 *
 * @param userDefaultsKey The NSUserDefaults key where the password is currently stored
 * @param account The Keychain account identifier to use
 * @param service The Keychain service identifier to use
 * @return YES if migrated successfully (or already in Keychain), NO on error
 *
 * @note This method will delete the password from NSUserDefaults after successful migration
 */
+ (BOOL)migratePasswordFromUserDefaults:(NSString *)userDefaultsKey
                              toAccount:(NSString *)account
                                service:(NSString *)service;

#pragma mark - Service Constants

/// Service identifier for UniFi Protect credentials
extern NSString * const RTSPKeychainServiceUniFiProtect;

/// Service identifier for Google Home credentials
extern NSString * const RTSPKeychainServiceGoogleHome;

/// Service identifier for RTSP camera credentials
extern NSString * const RTSPKeychainServiceRTSPCamera;

@end

NS_ASSUME_NONNULL_END
