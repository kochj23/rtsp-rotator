//
//  RTSPKeychainManager.m
//  RTSP Rotator
//
//  Secure password storage using macOS Keychain
//  Created as part of security improvements
//

#import "RTSPKeychainManager.h"
#import <Security/Security.h>

// Service constants
NSString * const RTSPKeychainServiceUniFiProtect = @"com.rtsp-rotator.unifi-protect";
NSString * const RTSPKeychainServiceGoogleHome = @"com.rtsp-rotator.google-home";
NSString * const RTSPKeychainServiceRTSPCamera = @"com.rtsp-rotator.rtsp-camera";

@implementation RTSPKeychainManager

#pragma mark - Password Storage

+ (BOOL)setPassword:(NSString *)password
         forAccount:(NSString *)account
            service:(NSString *)service {
    if (!password || !account || !service) {
        NSLog(@"[Keychain] Error: password, account, and service are required");
        return NO;
    }

    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    if (!passwordData) {
        NSLog(@"[Keychain] Error: failed to convert password to data");
        return NO;
    }

    // Try to update existing item first
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecAttrService: service
    };

    NSDictionary *updateAttributes = @{
        (__bridge id)kSecValueData: passwordData
    };

    OSStatus updateStatus = SecItemUpdate((__bridge CFDictionaryRef)query,
                                         (__bridge CFDictionaryRef)updateAttributes);

    if (updateStatus == errSecSuccess) {
        NSLog(@"[Keychain] Password updated for account: %@", account);
        return YES;
    }

    if (updateStatus == errSecItemNotFound) {
        // Item doesn't exist, create new one
        NSDictionary *addQuery = @{
            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrAccount: account,
            (__bridge id)kSecAttrService: service,
            (__bridge id)kSecValueData: passwordData,
            (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenUnlocked
        };

        OSStatus addStatus = SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
        if (addStatus == errSecSuccess) {
            NSLog(@"[Keychain] Password stored for account: %@", account);
            return YES;
        } else {
            NSLog(@"[Keychain] Error storing password: %d", (int)addStatus);
            return NO;
        }
    }

    NSLog(@"[Keychain] Error updating password: %d", (int)updateStatus);
    return NO;
}

+ (nullable NSString *)passwordForAccount:(NSString *)account
                                  service:(NSString *)service {
    if (!account || !service) {
        NSLog(@"[Keychain] Error: account and service are required");
        return nil;
    }

    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecAttrService: service,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);

    if (status == errSecSuccess && result) {
        NSData *passwordData = (__bridge_transfer NSData *)result;
        NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
        return password;
    }

    if (status == errSecItemNotFound) {
        NSLog(@"[Keychain] No password found for account: %@", account);
    } else {
        NSLog(@"[Keychain] Error retrieving password: %d", (int)status);
    }

    return nil;
}

+ (BOOL)deletePasswordForAccount:(NSString *)account
                         service:(NSString *)service {
    if (!account || !service) {
        NSLog(@"[Keychain] Error: account and service are required");
        return NO;
    }

    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecAttrService: service
    };

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);

    if (status == errSecSuccess) {
        NSLog(@"[Keychain] Password deleted for account: %@", account);
        return YES;
    }

    if (status == errSecItemNotFound) {
        // Not found is OK - already deleted
        return YES;
    }

    NSLog(@"[Keychain] Error deleting password: %d", (int)status);
    return NO;
}

#pragma mark - Generic Data Storage

+ (BOOL)setData:(NSData *)data
     forAccount:(NSString *)account
        service:(NSString *)service {
    if (!data || !account || !service) {
        NSLog(@"[Keychain] Error: data, account, and service are required");
        return NO;
    }

    // Try to update existing item first
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecAttrService: service
    };

    NSDictionary *updateAttributes = @{
        (__bridge id)kSecValueData: data
    };

    OSStatus updateStatus = SecItemUpdate((__bridge CFDictionaryRef)query,
                                         (__bridge CFDictionaryRef)updateAttributes);

    if (updateStatus == errSecSuccess) {
        return YES;
    }

    if (updateStatus == errSecItemNotFound) {
        // Item doesn't exist, create new one
        NSDictionary *addQuery = @{
            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrAccount: account,
            (__bridge id)kSecAttrService: service,
            (__bridge id)kSecValueData: data,
            (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenUnlocked
        };

        OSStatus addStatus = SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
        return (addStatus == errSecSuccess);
    }

    return NO;
}

+ (nullable NSData *)dataForAccount:(NSString *)account
                            service:(NSString *)service {
    if (!account || !service) {
        return nil;
    }

    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecAttrService: service,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);

    if (status == errSecSuccess && result) {
        return (__bridge_transfer NSData *)result;
    }

    return nil;
}

#pragma mark - Convenience Methods

+ (BOOL)hasPasswordForAccount:(NSString *)account
                      service:(NSString *)service {
    if (!account || !service) {
        return NO;
    }

    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecAttrService: service,
        (__bridge id)kSecReturnData: @NO
    };

    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
    return (status == errSecSuccess);
}

+ (BOOL)migratePasswordFromUserDefaults:(NSString *)userDefaultsKey
                              toAccount:(NSString *)account
                                service:(NSString *)service {
    if (!userDefaultsKey || !account || !service) {
        NSLog(@"[Keychain] Migration error: all parameters required");
        return NO;
    }

    // Check if already in Keychain
    if ([self hasPasswordForAccount:account service:service]) {
        NSLog(@"[Keychain] Password already in Keychain for account: %@", account);
        return YES;
    }

    // Get password from NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *password = [defaults stringForKey:userDefaultsKey];

    if (!password || password.length == 0) {
        NSLog(@"[Keychain] No password found in NSUserDefaults for key: %@", userDefaultsKey);
        return YES; // Not an error - just nothing to migrate
    }

    // Store in Keychain
    BOOL success = [self setPassword:password forAccount:account service:service];

    if (success) {
        // Remove from NSUserDefaults for security
        [defaults removeObjectForKey:userDefaultsKey];
        [defaults synchronize];

        NSLog(@"[Keychain] ✓ Successfully migrated password from NSUserDefaults to Keychain");
        NSLog(@"[Keychain] ✓ Removed password from NSUserDefaults for security");
        return YES;
    } else {
        NSLog(@"[Keychain] ✗ Failed to migrate password to Keychain");
        return NO;
    }
}

@end
