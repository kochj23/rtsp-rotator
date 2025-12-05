//
//  RTSPKeychainManagerTests.m
//  RTSP Rotator Tests
//
//  Comprehensive tests for secure Keychain password storage
//  Tests the security fixes implemented for credential storage
//

#import <XCTest/XCTest.h>
#import "RTSPKeychainManager.h"

@interface RTSPKeychainManagerTests : XCTestCase
@property (nonatomic, strong) NSString *testAccount;
@property (nonatomic, strong) NSString *testService;
@end

@implementation RTSPKeychainManagerTests

#pragma mark - Setup and Teardown

- (void)setUp {
    [super setUp];

    // Use unique identifiers for each test to avoid conflicts
    self.testAccount = [NSString stringWithFormat:@"TestAccount_%@", [[NSUUID UUID] UUIDString]];
    self.testService = [NSString stringWithFormat:@"TestService_%@", [[NSUUID UUID] UUIDString]];

    // Ensure clean state
    [RTSPKeychainManager deletePasswordForAccount:self.testAccount service:self.testService];
}

- (void)tearDown {
    // Cleanup test data
    [RTSPKeychainManager deletePasswordForAccount:self.testAccount service:self.testService];

    [super tearDown];
}

#pragma mark - Password Storage Tests

- (void)testStorePasswordSuccess {
    // Given
    NSString *password = @"TestPassword123!";

    // When
    BOOL success = [RTSPKeychainManager setPassword:password
                                         forAccount:self.testAccount
                                            service:self.testService];

    // Then
    XCTAssertTrue(success, @"Should successfully store password");
}

- (void)testStorePasswordWithNilPassword {
    // When
    BOOL success = [RTSPKeychainManager setPassword:nil
                                         forAccount:self.testAccount
                                            service:self.testService];

    // Then
    XCTAssertFalse(success, @"Should fail to store nil password");
}

- (void)testStorePasswordWithNilAccount {
    // When
    BOOL success = [RTSPKeychainManager setPassword:@"password"
                                         forAccount:nil
                                            service:self.testService];

    // Then
    XCTAssertFalse(success, @"Should fail with nil account");
}

- (void)testStorePasswordWithNilService {
    // When
    BOOL success = [RTSPKeychainManager setPassword:@"password"
                                         forAccount:self.testAccount
                                            service:nil];

    // Then
    XCTAssertFalse(success, @"Should fail with nil service");
}

- (void)testStorePasswordWithEmptyString {
    // Given - Empty string is valid (user might want to clear password)
    NSString *emptyPassword = @"";

    // When
    BOOL success = [RTSPKeychainManager setPassword:emptyPassword
                                         forAccount:self.testAccount
                                            service:self.testService];

    // Then
    XCTAssertTrue(success, @"Should successfully store empty password");
}

- (void)testStoreComplexPassword {
    // Given - Complex password with special characters
    NSString *complexPassword = @"P@ssw0rd!#$%^&*()_+-=[]{}|;:',.<>?/~`";

    // When
    BOOL success = [RTSPKeychainManager setPassword:complexPassword
                                         forAccount:self.testAccount
                                            service:self.testService];

    // Then
    XCTAssertTrue(success, @"Should handle complex passwords with special characters");
}

- (void)testStoreLongPassword {
    // Given - Very long password (1000 characters)
    NSString *longPassword = [@"" stringByPaddingToLength:1000 withString:@"A" startingAtIndex:0];

    // When
    BOOL success = [RTSPKeychainManager setPassword:longPassword
                                         forAccount:self.testAccount
                                            service:self.testService];

    // Then
    XCTAssertTrue(success, @"Should handle very long passwords");
}

- (void)testStoreUnicodePassword {
    // Given - Unicode characters (emoji, international characters)
    NSString *unicodePassword = @"🔐パスワード密码🔑";

    // When
    BOOL success = [RTSPKeychainManager setPassword:unicodePassword
                                         forAccount:self.testAccount
                                            service:self.testService];

    // Then
    XCTAssertTrue(success, @"Should handle Unicode characters");
}

#pragma mark - Password Retrieval Tests

- (void)testRetrievePasswordSuccess {
    // Given
    NSString *originalPassword = @"SecretPassword789";
    [RTSPKeychainManager setPassword:originalPassword
                          forAccount:self.testAccount
                             service:self.testService];

    // When
    NSString *retrievedPassword = [RTSPKeychainManager passwordForAccount:self.testAccount
                                                                  service:self.testService];

    // Then
    XCTAssertNotNil(retrievedPassword, @"Should retrieve stored password");
    XCTAssertEqualObjects(retrievedPassword, originalPassword, @"Retrieved password should match original");
}

- (void)testRetrieveNonExistentPassword {
    // When
    NSString *password = [RTSPKeychainManager passwordForAccount:@"NonExistent"
                                                         service:@"NonExistentService"];

    // Then
    XCTAssertNil(password, @"Should return nil for non-existent password");
}

- (void)testRetrievePasswordWithNilAccount {
    // When
    NSString *password = [RTSPKeychainManager passwordForAccount:nil
                                                         service:self.testService];

    // Then
    XCTAssertNil(password, @"Should return nil for nil account");
}

- (void)testRetrievePasswordWithNilService {
    // When
    NSString *password = [RTSPKeychainManager passwordForAccount:self.testAccount
                                                         service:nil];

    // Then
    XCTAssertNil(password, @"Should return nil for nil service");
}

- (void)testRetrieveComplexPassword {
    // Given
    NSString *complexPassword = @"C0mpl3x!P@ssw0rd#2024$%^&*()";
    [RTSPKeychainManager setPassword:complexPassword
                          forAccount:self.testAccount
                             service:self.testService];

    // When
    NSString *retrieved = [RTSPKeychainManager passwordForAccount:self.testAccount
                                                          service:self.testService];

    // Then
    XCTAssertEqualObjects(retrieved, complexPassword, @"Should correctly retrieve complex password");
}

- (void)testRetrieveUnicodePassword {
    // Given
    NSString *unicodePassword = @"🔐パスワード密码🔑";
    [RTSPKeychainManager setPassword:unicodePassword
                          forAccount:self.testAccount
                             service:self.testService];

    // When
    NSString *retrieved = [RTSPKeychainManager passwordForAccount:self.testAccount
                                                          service:self.testService];

    // Then
    XCTAssertEqualObjects(retrieved, unicodePassword, @"Should correctly handle Unicode");
}

#pragma mark - Password Update Tests

- (void)testUpdateExistingPassword {
    // Given - Store initial password
    NSString *initialPassword = @"InitialPassword";
    [RTSPKeychainManager setPassword:initialPassword
                          forAccount:self.testAccount
                             service:self.testService];

    // When - Update with new password
    NSString *updatedPassword = @"UpdatedPassword";
    BOOL updateSuccess = [RTSPKeychainManager setPassword:updatedPassword
                                               forAccount:self.testAccount
                                                  service:self.testService];

    // Then
    XCTAssertTrue(updateSuccess, @"Should successfully update password");

    NSString *retrieved = [RTSPKeychainManager passwordForAccount:self.testAccount
                                                          service:self.testService];
    XCTAssertEqualObjects(retrieved, updatedPassword, @"Should retrieve updated password");
    XCTAssertNotEqualObjects(retrieved, initialPassword, @"Should not retrieve old password");
}

- (void)testMultipleUpdates {
    // Given
    NSString *password1 = @"Password1";
    NSString *password2 = @"Password2";
    NSString *password3 = @"Password3";

    // When - Multiple updates
    [RTSPKeychainManager setPassword:password1 forAccount:self.testAccount service:self.testService];
    [RTSPKeychainManager setPassword:password2 forAccount:self.testAccount service:self.testService];
    [RTSPKeychainManager setPassword:password3 forAccount:self.testAccount service:self.testService];

    // Then - Only latest password should be retrievable
    NSString *retrieved = [RTSPKeychainManager passwordForAccount:self.testAccount service:self.testService];
    XCTAssertEqualObjects(retrieved, password3, @"Should have latest password");
}

#pragma mark - Password Deletion Tests

- (void)testDeletePassword {
    // Given
    [RTSPKeychainManager setPassword:@"ToBeDeleted"
                          forAccount:self.testAccount
                             service:self.testService];

    // Verify it exists
    XCTAssertNotNil([RTSPKeychainManager passwordForAccount:self.testAccount service:self.testService]);

    // When
    BOOL deleteSuccess = [RTSPKeychainManager deletePasswordForAccount:self.testAccount
                                                               service:self.testService];

    // Then
    XCTAssertTrue(deleteSuccess, @"Should successfully delete password");

    NSString *retrieved = [RTSPKeychainManager passwordForAccount:self.testAccount
                                                          service:self.testService];
    XCTAssertNil(retrieved, @"Password should be deleted");
}

- (void)testDeleteNonExistentPassword {
    // When - Delete password that doesn't exist
    BOOL deleteSuccess = [RTSPKeychainManager deletePasswordForAccount:@"DoesNotExist"
                                                               service:@"DoesNotExist"];

    // Then - Should return YES (already gone is success)
    XCTAssertTrue(deleteSuccess, @"Deleting non-existent password should succeed");
}

- (void)testDeleteWithNilAccount {
    // When
    BOOL deleteSuccess = [RTSPKeychainManager deletePasswordForAccount:nil
                                                               service:self.testService];

    // Then
    XCTAssertFalse(deleteSuccess, @"Should fail with nil account");
}

#pragma mark - hasPassword Tests

- (void)testHasPasswordWhenExists {
    // Given
    [RTSPKeychainManager setPassword:@"Exists"
                          forAccount:self.testAccount
                             service:self.testService];

    // When
    BOOL hasPassword = [RTSPKeychainManager hasPasswordForAccount:self.testAccount
                                                          service:self.testService];

    // Then
    XCTAssertTrue(hasPassword, @"Should return YES when password exists");
}

- (void)testHasPasswordWhenDoesNotExist {
    // When
    BOOL hasPassword = [RTSPKeychainManager hasPasswordForAccount:@"DoesNotExist"
                                                          service:@"DoesNotExist"];

    // Then
    XCTAssertFalse(hasPassword, @"Should return NO when password does not exist");
}

- (void)testHasPasswordWithNilParameters {
    // When/Then
    XCTAssertFalse([RTSPKeychainManager hasPasswordForAccount:nil service:self.testService]);
    XCTAssertFalse([RTSPKeychainManager hasPasswordForAccount:self.testAccount service:nil]);
    XCTAssertFalse([RTSPKeychainManager hasPasswordForAccount:nil service:nil]);
}

#pragma mark - Migration Tests

- (void)testMigratePasswordFromUserDefaults {
    // Given - Store password in NSUserDefaults (old insecure way)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userDefaultsKey = [NSString stringWithFormat:@"TestMigration_%@", [[NSUUID UUID] UUIDString]];
    NSString *password = @"OldPassword123";
    [defaults setObject:password forKey:userDefaultsKey];
    [defaults synchronize];

    // When - Migrate to Keychain
    BOOL migrationSuccess = [RTSPKeychainManager migratePasswordFromUserDefaults:userDefaultsKey
                                                                       toAccount:self.testAccount
                                                                         service:self.testService];

    // Then
    XCTAssertTrue(migrationSuccess, @"Migration should succeed");

    // Verify password is in Keychain
    NSString *keychainPassword = [RTSPKeychainManager passwordForAccount:self.testAccount
                                                                 service:self.testService];
    XCTAssertEqualObjects(keychainPassword, password, @"Password should be in Keychain");

    // Verify password is removed from NSUserDefaults
    NSString *userDefaultsPassword = [defaults stringForKey:userDefaultsKey];
    XCTAssertNil(userDefaultsPassword, @"Password should be removed from NSUserDefaults for security");

    // Cleanup
    [defaults removeObjectForKey:userDefaultsKey];
}

- (void)testMigrateNonExistentPassword {
    // When - Try to migrate password that doesn't exist
    BOOL migrationSuccess = [RTSPKeychainManager migratePasswordFromUserDefaults:@"DoesNotExist"
                                                                       toAccount:self.testAccount
                                                                         service:self.testService];

    // Then - Should return YES (nothing to migrate is success)
    XCTAssertTrue(migrationSuccess, @"Migrating non-existent password should succeed");
}

- (void)testMigrateAlreadyInKeychain {
    // Given - Password already in Keychain
    NSString *password = @"AlreadyInKeychain";
    [RTSPKeychainManager setPassword:password
                          forAccount:self.testAccount
                             service:self.testService];

    // And - Password in NSUserDefaults too
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userDefaultsKey = [NSString stringWithFormat:@"TestDuplicate_%@", [[NSUUID UUID] UUIDString]];
    [defaults setObject:@"DifferentPassword" forKey:userDefaultsKey];
    [defaults synchronize];

    // When - Try to migrate
    BOOL migrationSuccess = [RTSPKeychainManager migratePasswordFromUserDefaults:userDefaultsKey
                                                                       toAccount:self.testAccount
                                                                         service:self.testService];

    // Then
    XCTAssertTrue(migrationSuccess, @"Should succeed when already in Keychain");

    // Original password should remain
    NSString *retrieved = [RTSPKeychainManager passwordForAccount:self.testAccount
                                                          service:self.testService];
    XCTAssertEqualObjects(retrieved, password, @"Original Keychain password should be preserved");

    // Cleanup
    [defaults removeObjectForKey:userDefaultsKey];
}

#pragma mark - Generic Data Storage Tests

- (void)testStoreAndRetrieveData {
    // Given
    NSString *testString = @"TestData";
    NSData *testData = [testString dataUsingEncoding:NSUTF8StringEncoding];

    // When
    BOOL storeSuccess = [RTSPKeychainManager setData:testData
                                          forAccount:self.testAccount
                                             service:self.testService];

    // Then
    XCTAssertTrue(storeSuccess, @"Should store data successfully");

    NSData *retrievedData = [RTSPKeychainManager dataForAccount:self.testAccount
                                                        service:self.testService];
    XCTAssertNotNil(retrievedData, @"Should retrieve data");

    NSString *retrievedString = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(retrievedString, testString, @"Retrieved data should match original");
}

- (void)testStoreNilData {
    // When
    BOOL success = [RTSPKeychainManager setData:nil
                                     forAccount:self.testAccount
                                        service:self.testService];

    // Then
    XCTAssertFalse(success, @"Should fail to store nil data");
}

#pragma mark - Service Constants Tests

- (void)testServiceConstantsAreDefined {
    // When/Then
    XCTAssertNotNil(RTSPKeychainServiceUniFiProtect, @"UniFi service constant should be defined");
    XCTAssertNotNil(RTSPKeychainServiceGoogleHome, @"Google Home service constant should be defined");
    XCTAssertNotNil(RTSPKeychainServiceRTSPCamera, @"RTSP Camera service constant should be defined");

    // Verify they're different
    XCTAssertNotEqualObjects(RTSPKeychainServiceUniFiProtect, RTSPKeychainServiceGoogleHome);
    XCTAssertNotEqualObjects(RTSPKeychainServiceUniFiProtect, RTSPKeychainServiceRTSPCamera);
    XCTAssertNotEqualObjects(RTSPKeychainServiceGoogleHome, RTSPKeychainServiceRTSPCamera);
}

#pragma mark - Isolation Tests

- (void)testPasswordsAreIsolatedByAccount {
    // Given - Same service, different accounts
    NSString *account1 = [NSString stringWithFormat:@"Account1_%@", [[NSUUID UUID] UUIDString]];
    NSString *account2 = [NSString stringWithFormat:@"Account2_%@", [[NSUUID UUID] UUIDString]];

    // When
    [RTSPKeychainManager setPassword:@"Password1" forAccount:account1 service:self.testService];
    [RTSPKeychainManager setPassword:@"Password2" forAccount:account2 service:self.testService];

    // Then
    NSString *retrieved1 = [RTSPKeychainManager passwordForAccount:account1 service:self.testService];
    NSString *retrieved2 = [RTSPKeychainManager passwordForAccount:account2 service:self.testService];

    XCTAssertEqualObjects(retrieved1, @"Password1");
    XCTAssertEqualObjects(retrieved2, @"Password2");
    XCTAssertNotEqualObjects(retrieved1, retrieved2, @"Passwords should be isolated by account");

    // Cleanup
    [RTSPKeychainManager deletePasswordForAccount:account1 service:self.testService];
    [RTSPKeychainManager deletePasswordForAccount:account2 service:self.testService];
}

- (void)testPasswordsAreIsolatedByService {
    // Given - Same account, different services
    NSString *service1 = [NSString stringWithFormat:@"Service1_%@", [[NSUUID UUID] UUIDString]];
    NSString *service2 = [NSString stringWithFormat:@"Service2_%@", [[NSUUID UUID] UUIDString]];

    // When
    [RTSPKeychainManager setPassword:@"Password1" forAccount:self.testAccount service:service1];
    [RTSPKeychainManager setPassword:@"Password2" forAccount:self.testAccount service:service2];

    // Then
    NSString *retrieved1 = [RTSPKeychainManager passwordForAccount:self.testAccount service:service1];
    NSString *retrieved2 = [RTSPKeychainManager passwordForAccount:self.testAccount service:service2];

    XCTAssertEqualObjects(retrieved1, @"Password1");
    XCTAssertEqualObjects(retrieved2, @"Password2");
    XCTAssertNotEqualObjects(retrieved1, retrieved2, @"Passwords should be isolated by service");

    // Cleanup
    [RTSPKeychainManager deletePasswordForAccount:self.testAccount service:service1];
    [RTSPKeychainManager deletePasswordForAccount:self.testAccount service:service2];
}

#pragma mark - Performance Tests

- (void)testPasswordStoragePerformance {
    [self measureBlock:^{
        for (int i = 0; i < 10; i++) {
            NSString *account = [NSString stringWithFormat:@"PerfTest_%d", i];
            [RTSPKeychainManager setPassword:@"TestPassword" forAccount:account service:self.testService];
            [RTSPKeychainManager deletePasswordForAccount:account service:self.testService];
        }
    }];
}

- (void)testPasswordRetrievalPerformance {
    // Given
    [RTSPKeychainManager setPassword:@"TestPassword" forAccount:self.testAccount service:self.testService];

    // When/Then
    [self measureBlock:^{
        for (int i = 0; i < 100; i++) {
            [RTSPKeychainManager passwordForAccount:self.testAccount service:self.testService];
        }
    }];
}

@end
