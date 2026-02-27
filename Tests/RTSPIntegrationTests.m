//
//  RTSPIntegrationTests.m
//  RTSP Rotator Tests
//
//  Integration tests to verify all fixes work together correctly
//  Tests the interaction between security, memory management, and configuration
//

#import <XCTest/XCTest.h>
#import "RTSPKeychainManager.h"
#import "RTSPFeedMetadata.h"
#import "RTSPPreferencesController.h"

@interface RTSPWallpaperController : NSObject
@property (nonatomic, strong) NSArray<NSString *> *feeds;
@property (nonatomic, assign) NSTimeInterval rotationInterval;
- (instancetype)initWithFeeds:(NSArray<NSString *> *)feeds rotationInterval:(NSTimeInterval)interval;
- (void)start;
- (void)stop;
@end

@interface RTSPIntegrationTests : XCTestCase
@end

@implementation RTSPIntegrationTests

#pragma mark - Setup and Teardown

- (void)setUp {
    [super setUp];
    // Clean up any test data
    [RTSPKeychainManager deletePasswordForAccount:@"TestIntegration" service:RTSPKeychainServiceUniFiProtect];
}

- (void)tearDown {
    // Clean up test data
    [RTSPKeychainManager deletePasswordForAccount:@"TestIntegration" service:RTSPKeychainServiceUniFiProtect];
    [super tearDown];
}

#pragma mark - End-to-End Credential Flow Tests

- (void)testCompleteCredentialLifecycle {
    // This test verifies the complete lifecycle: store → retrieve → use → delete

    // Step 1: Store credentials in Keychain
    NSString *testPassword = @"IntegrationTestPassword123!";
    BOOL storeSuccess = [RTSPKeychainManager setPassword:testPassword
                                              forAccount:@"TestIntegration"
                                                 service:RTSPKeychainServiceUniFiProtect];
    XCTAssertTrue(storeSuccess, @"Step 1: Should store password");

    // Step 2: Retrieve credentials
    NSString *retrievedPassword = [RTSPKeychainManager passwordForAccount:@"TestIntegration"
                                                                  service:RTSPKeychainServiceUniFiProtect];
    XCTAssertEqualObjects(retrievedPassword, testPassword, @"Step 2: Should retrieve correct password");

    // Step 3: Verify credentials exist
    BOOL hasPassword = [RTSPKeychainManager hasPasswordForAccount:@"TestIntegration"
                                                          service:RTSPKeychainServiceUniFiProtect];
    XCTAssertTrue(hasPassword, @"Step 3: Should confirm password exists");

    // Step 4: Update credentials
    NSString *updatedPassword = @"UpdatedPassword456!";
    BOOL updateSuccess = [RTSPKeychainManager setPassword:updatedPassword
                                               forAccount:@"TestIntegration"
                                                  service:RTSPKeychainServiceUniFiProtect];
    XCTAssertTrue(updateSuccess, @"Step 4: Should update password");

    NSString *newRetrieved = [RTSPKeychainManager passwordForAccount:@"TestIntegration"
                                                             service:RTSPKeychainServiceUniFiProtect];
    XCTAssertEqualObjects(newRetrieved, updatedPassword, @"Step 4b: Should retrieve updated password");

    // Step 5: Delete credentials
    BOOL deleteSuccess = [RTSPKeychainManager deletePasswordForAccount:@"TestIntegration"
                                                               service:RTSPKeychainServiceUniFiProtect];
    XCTAssertTrue(deleteSuccess, @"Step 5: Should delete password");

    // Step 6: Verify deleted
    NSString *afterDelete = [RTSPKeychainManager passwordForAccount:@"TestIntegration"
                                                            service:RTSPKeychainServiceUniFiProtect];
    XCTAssertNil(afterDelete, @"Step 6: Password should be deleted");
}

#pragma mark - Migration Integration Tests

- (void)testMigrationAndImmediateUse {
    // This test verifies that migrated passwords can be used immediately

    // Step 1: Store password in NSUserDefaults (simulating old version)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userDefaultsKey = @"TestMigrationIntegration";
    NSString *oldPassword = @"OldStylePassword";
    [defaults setObject:oldPassword forKey:userDefaultsKey];
    [defaults synchronize];

    // Step 2: Migrate to Keychain
    BOOL migrationSuccess = [RTSPKeychainManager migratePasswordFromUserDefaults:userDefaultsKey
                                                                       toAccount:@"TestIntegration"
                                                                         service:RTSPKeychainServiceUniFiProtect];
    XCTAssertTrue(migrationSuccess, @"Migration should succeed");

    // Step 3: Immediately use migrated password
    NSString *retrieved = [RTSPKeychainManager passwordForAccount:@"TestIntegration"
                                                          service:RTSPKeychainServiceUniFiProtect];
    XCTAssertEqualObjects(retrieved, oldPassword, @"Should immediately retrieve migrated password");

    // Step 4: Verify NSUserDefaults is cleaned
    NSString *shouldBeNil = [defaults stringForKey:userDefaultsKey];
    XCTAssertNil(shouldBeNil, @"NSUserDefaults should be cleaned after migration");

    // Cleanup
    [defaults removeObjectForKey:userDefaultsKey];
}

#pragma mark - Multi-Service Integration Tests

- (void)testMultipleServicesDoNotInterfere {
    // Test that UniFi and Google Home credentials are properly isolated

    // Given - Store passwords for different services
    NSString *unifiPassword = @"UniFiPassword123";
    NSString *googlePassword = @"GooglePassword456";

    [RTSPKeychainManager setPassword:unifiPassword
                          forAccount:@"TestIntegration"
                             service:RTSPKeychainServiceUniFiProtect];

    [RTSPKeychainManager setPassword:googlePassword
                          forAccount:@"TestIntegration"
                             service:RTSPKeychainServiceGoogleHome];

    // When - Retrieve both
    NSString *retrievedUnifi = [RTSPKeychainManager passwordForAccount:@"TestIntegration"
                                                               service:RTSPKeychainServiceUniFiProtect];

    NSString *retrievedGoogle = [RTSPKeychainManager passwordForAccount:@"TestIntegration"
                                                                service:RTSPKeychainServiceGoogleHome];

    // Then - Both should be correct and isolated
    XCTAssertEqualObjects(retrievedUnifi, unifiPassword);
    XCTAssertEqualObjects(retrievedGoogle, googlePassword);
    XCTAssertNotEqualObjects(retrievedUnifi, retrievedGoogle);

    // Cleanup
    [RTSPKeychainManager deletePasswordForAccount:@"TestIntegration" service:RTSPKeychainServiceUniFiProtect];
    [RTSPKeychainManager deletePasswordForAccount:@"TestIntegration" service:RTSPKeychainServiceGoogleHome];
}

#pragma mark - Controller + Configuration Integration Tests

- (void)testControllerWithConfigurationManager {
    // This tests that controller works properly with configuration manager

    // Given
    RTSPConfigurationManager *config = [[RTSPConfigurationManager alloc] init];
    config.rotationInterval = 30.0;

    NSArray *feeds = @[@"rtsp://camera1.example.com", @"rtsp://camera2.example.com"];
    config.manualFeeds = feeds;

    // When
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:config.manualFeeds
                                                                           rotationInterval:config.rotationInterval];

    // Then
    XCTAssertNotNil(controller);
    XCTAssertEqual(controller.feeds.count, 2);
    XCTAssertEqual(controller.rotationInterval, 30.0);

    // Cleanup
    [controller stop];
}

#pragma mark - Real-World Scenario Tests

- (void)testUniFiProtectWorkflow {
    // Simulate a real UniFi Protect setup workflow

    // Step 1: User enters credentials
    NSString *host = @"10.0.0.1";
    NSString *username = @"testuser@example.com";
    NSString *password = @"TestPassword123!";

    // Step 2: Save to preferences and Keychain
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:host forKey:@"UniFi_ControllerHost"];
    [defaults setObject:username forKey:@"UniFi_Username"];
    [defaults synchronize];

    [RTSPKeychainManager setPassword:password
                          forAccount:@"UniFi_Password"
                             service:RTSPKeychainServiceUniFiProtect];

    // Step 3: Later retrieve credentials (simulating app restart)
    NSString *retrievedHost = [defaults stringForKey:@"UniFi_ControllerHost"];
    NSString *retrievedUsername = [defaults stringForKey:@"UniFi_Username"];
    NSString *retrievedPassword = [RTSPKeychainManager passwordForAccount:@"UniFi_Password"
                                                                  service:RTSPKeychainServiceUniFiProtect];

    // Then
    XCTAssertEqualObjects(retrievedHost, host);
    XCTAssertEqualObjects(retrievedUsername, username);
    XCTAssertEqualObjects(retrievedPassword, password);

    // Step 4: User updates password
    NSString *newPassword = @"NewPassword789!";
    [RTSPKeychainManager setPassword:newPassword
                          forAccount:@"UniFi_Password"
                             service:RTSPKeychainServiceUniFiProtect];

    NSString *updatedPassword = [RTSPKeychainManager passwordForAccount:@"UniFi_Password"
                                                                service:RTSPKeychainServiceUniFiProtect];
    XCTAssertEqualObjects(updatedPassword, newPassword);

    // Cleanup
    [defaults removeObjectForKey:@"UniFi_ControllerHost"];
    [defaults removeObjectForKey:@"UniFi_Username"];
    [RTSPKeychainManager deletePasswordForAccount:@"UniFi_Password" service:RTSPKeychainServiceUniFiProtect];
}

- (void)testGoogleHomeWorkflow {
    // Simulate a real Google Home setup workflow

    // Step 1: User enters OAuth credentials
    NSString *clientID = @"123456789.apps.googleusercontent.com";
    NSString *clientSecret = @"GOCSPX-TestSecret";

    // Step 2: Save to preferences and Keychain
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:clientID forKey:@"GoogleHome_ClientID"];
    [defaults synchronize];

    [RTSPKeychainManager setPassword:clientSecret
                          forAccount:@"GoogleHome_ClientSecret"
                             service:RTSPKeychainServiceGoogleHome];

    // Step 3: Retrieve for use
    NSString *retrievedID = [defaults stringForKey:@"GoogleHome_ClientID"];
    NSString *retrievedSecret = [RTSPKeychainManager passwordForAccount:@"GoogleHome_ClientSecret"
                                                                 service:RTSPKeychainServiceGoogleHome];

    // Then
    XCTAssertEqualObjects(retrievedID, clientID);
    XCTAssertEqualObjects(retrievedSecret, clientSecret);

    // Cleanup
    [defaults removeObjectForKey:@"GoogleHome_ClientID"];
    [RTSPKeychainManager deletePasswordForAccount:@"GoogleHome_ClientSecret" service:RTSPKeychainServiceGoogleHome];
}

#pragma mark - Memory + Security Integration Tests

- (void)testControllerLifecycleWithSecureCredentials {
    // This test combines memory management and security features

    @autoreleasepool {
        // Step 1: Setup secure credentials
        [RTSPKeychainManager setPassword:@"TestPassword"
                              forAccount:@"TestIntegration"
                                 service:RTSPKeychainServiceRTSPCamera];

        // Step 2: Create controller
        RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                               rotationInterval:60.0];

        // Step 3: Start/stop (tests memory management)
        [controller start];
        [controller stop];

        // Step 4: Credentials should still be accessible
        NSString *password = [RTSPKeychainManager passwordForAccount:@"TestIntegration"
                                                             service:RTSPKeychainServiceRTSPCamera];
        XCTAssertEqualObjects(password, @"TestPassword", @"Credentials should persist through controller lifecycle");
    }

    // Cleanup
    [RTSPKeychainManager deletePasswordForAccount:@"TestIntegration" service:RTSPKeychainServiceRTSPCamera];
}

#pragma mark - Stress Tests

- (void)testMultipleControllersWithDifferentCredentials {
    // Test that multiple controllers with different credentials don't interfere

    // Given - Multiple credentials
    for (int i = 0; i < 5; i++) {
        NSString *account = [NSString stringWithFormat:@"Camera_%d", i];
        NSString *password = [NSString stringWithFormat:@"Password_%d", i];

        [RTSPKeychainManager setPassword:password
                              forAccount:account
                                 service:RTSPKeychainServiceRTSPCamera];
    }

    // When - Create multiple controllers
    NSMutableArray *controllers = [NSMutableArray array];
    for (int i = 0; i < 5; i++) {
        RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[[NSString stringWithFormat:@"rtsp://camera%d.example.com", i]]
                                                                               rotationInterval:60.0];
        [controllers addObject:controller];
    }

    // Then - All passwords should still be retrievable
    for (int i = 0; i < 5; i++) {
        NSString *account = [NSString stringWithFormat:@"Camera_%d", i];
        NSString *expected = [NSString stringWithFormat:@"Password_%d", i];
        NSString *retrieved = [RTSPKeychainManager passwordForAccount:account
                                                              service:RTSPKeychainServiceRTSPCamera];
        XCTAssertEqualObjects(retrieved, expected, @"Password %d should be correct", i);
    }

    // Cleanup
    for (RTSPWallpaperController *controller in controllers) {
        [controller stop];
    }
    for (int i = 0; i < 5; i++) {
        [RTSPKeychainManager deletePasswordForAccount:[NSString stringWithFormat:@"Camera_%d", i]
                                              service:RTSPKeychainServiceRTSPCamera];
    }
}

#pragma mark - Configuration + Security Integration

- (void)testConfigurationManagerWithKeychainIntegration {
    // Test that configuration manager works with Keychain-secured passwords

    // Given - Configuration with metadata
    RTSPConfigurationManager *config = [[RTSPConfigurationManager alloc] init];

    RTSPFeedMetadata *feed1 = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://camera1.example.com"
                                                         displayName:@"Camera 1"];
    feed1.category = @"Test";

    RTSPFeedMetadata *feed2 = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://camera2.example.com"
                                                         displayName:@"Camera 2"];
    feed2.category = @"Test";

    config.manualFeedMetadata = @[feed1, feed2];

    // Store passwords for these cameras
    [RTSPKeychainManager setPassword:@"Password1"
                          forAccount:@"camera1.example.com"
                             service:RTSPKeychainServiceRTSPCamera];

    [RTSPKeychainManager setPassword:@"Password2"
                          forAccount:@"camera2.example.com"
                             service:RTSPKeychainServiceRTSPCamera];

    // When - Create controller with this configuration
    NSArray *feedURLs = [config.manualFeedMetadata valueForKey:@"url"];
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:feedURLs
                                                                           rotationInterval:config.rotationInterval];

    // Then
    XCTAssertNotNil(controller);
    XCTAssertEqual(controller.feeds.count, 2);

    // Verify passwords are accessible
    NSString *pass1 = [RTSPKeychainManager passwordForAccount:@"camera1.example.com"
                                                      service:RTSPKeychainServiceRTSPCamera];
    NSString *pass2 = [RTSPKeychainManager passwordForAccount:@"camera2.example.com"
                                                      service:RTSPKeychainServiceRTSPCamera];
    XCTAssertEqualObjects(pass1, @"Password1");
    XCTAssertEqualObjects(pass2, @"Password2");

    // Cleanup
    [controller stop];
    [RTSPKeychainManager deletePasswordForAccount:@"camera1.example.com" service:RTSPKeychainServiceRTSPCamera];
    [RTSPKeychainManager deletePasswordForAccount:@"camera2.example.com" service:RTSPKeychainServiceRTSPCamera];
}

#pragma mark - Backwards Compatibility Tests

- (void)testLegacyUserDefaultsMigration {
    // Simulate upgrading from old version with passwords in NSUserDefaults

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Given - Old version had passwords in NSUserDefaults
    [defaults setObject:@"10.0.0.1" forKey:@"UniFi_ControllerHost"];
    [defaults setObject:@"admin@example.com" forKey:@"UniFi_Username"];
    [defaults setObject:@"OldInsecurePassword" forKey:@"UniFi_Password"]; // OLD INSECURE WAY
    [defaults synchronize];

    // When - App starts and migrates
    [RTSPKeychainManager migratePasswordFromUserDefaults:@"UniFi_Password"
                                              toAccount:@"UniFi_Password"
                                                service:RTSPKeychainServiceUniFiProtect];

    // Then - Host and username should still be in NSUserDefaults
    XCTAssertEqualObjects([defaults stringForKey:@"UniFi_ControllerHost"], @"10.0.0.1");
    XCTAssertEqualObjects([defaults stringForKey:@"UniFi_Username"], @"admin@example.com");

    // Password should be removed from NSUserDefaults
    XCTAssertNil([defaults stringForKey:@"UniFi_Password"], @"Password should be removed from NSUserDefaults");

    // Password should be in Keychain
    NSString *keychainPassword = [RTSPKeychainManager passwordForAccount:@"UniFi_Password"
                                                                 service:RTSPKeychainServiceUniFiProtect];
    XCTAssertEqualObjects(keychainPassword, @"OldInsecurePassword", @"Password should be migrated to Keychain");

    // Cleanup
    [defaults removeObjectForKey:@"UniFi_ControllerHost"];
    [defaults removeObjectForKey:@"UniFi_Username"];
    [RTSPKeychainManager deletePasswordForAccount:@"UniFi_Password" service:RTSPKeychainServiceUniFiProtect];
}

#pragma mark - Error Recovery Tests

- (void)testKeychainAccessAfterMultipleFailures {
    // Test that Keychain access works properly after failures

    // Try to retrieve non-existent password multiple times
    for (int i = 0; i < 10; i++) {
        NSString *password = [RTSPKeychainManager passwordForAccount:@"DoesNotExist"
                                                             service:@"DoesNotExist"];
        XCTAssertNil(password, @"Should handle non-existent passwords gracefully");
    }

    // Then - Normal operations should still work
    BOOL success = [RTSPKeychainManager setPassword:@"WorksAfterFailures"
                                         forAccount:@"TestIntegration"
                                            service:RTSPKeychainServiceRTSPCamera];
    XCTAssertTrue(success, @"Should work after multiple failures");

    NSString *retrieved = [RTSPKeychainManager passwordForAccount:@"TestIntegration"
                                                          service:RTSPKeychainServiceRTSPCamera];
    XCTAssertEqualObjects(retrieved, @"WorksAfterFailures");

    // Cleanup
    [RTSPKeychainManager deletePasswordForAccount:@"TestIntegration" service:RTSPKeychainServiceRTSPCamera];
}

#pragma mark - Thread Safety Tests

- (void)testConcurrentKeychainAccess {
    // Test that Keychain manager handles concurrent access properly

    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Thread 1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Thread 2"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"Thread 3"];

    // Thread 1: Store passwords
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (int i = 0; i < 5; i++) {
            [RTSPKeychainManager setPassword:@"Password1"
                                  forAccount:[NSString stringWithFormat:@"Account_%d", i]
                                     service:RTSPKeychainServiceRTSPCamera];
        }
        [expectation1 fulfill];
    });

    // Thread 2: Retrieve passwords
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:0.2];
        for (int i = 0; i < 5; i++) {
            [RTSPKeychainManager passwordForAccount:[NSString stringWithFormat:@"Account_%d", i]
                                            service:RTSPKeychainServiceRTSPCamera];
        }
        [expectation2 fulfill];
    });

    // Thread 3: Delete passwords
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [NSThread sleepForTimeInterval:0.4];
        for (int i = 0; i < 5; i++) {
            [RTSPKeychainManager deletePasswordForAccount:[NSString stringWithFormat:@"Account_%d", i]
                                                  service:RTSPKeychainServiceRTSPCamera];
        }
        [expectation3 fulfill];
    });

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
