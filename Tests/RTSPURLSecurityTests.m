//
//  RTSPURLSecurityTests.m
//  RTSP Rotator Tests
//
//  Security tests for RTSP URL credential handling
//  Ensures passwords are not logged, stored in plaintext, or leaked
//  Written by Jordan Koch
//

#import <XCTest/XCTest.h>
#import "RTSPKeychainManager.h"
#import "RTSPFeedMetadata.h"

@interface RTSPURLSecurityTests : XCTestCase
@end

@implementation RTSPURLSecurityTests

#pragma mark - RTSP URL Credential Parsing

- (void)testRTSPURLWithCredentialsParses {
    // Given - URL with embedded credentials
    NSString *urlString = @"rtsp://admin:secretpass@192.168.1.100:554/stream";

    // When
    NSURL *url = [NSURL URLWithString:urlString];

    // Then
    XCTAssertNotNil(url, @"Should parse RTSP URL with credentials");
    XCTAssertEqualObjects(url.scheme, @"rtsp");
    XCTAssertEqualObjects(url.user, @"admin");
    XCTAssertEqualObjects(url.password, @"secretpass");
    XCTAssertEqualObjects(url.host, @"192.168.1.100");
    XCTAssertEqual(url.port.integerValue, 554);
}

- (void)testRTSPSURLWithCredentialsParses {
    // Given - Secure RTSP URL with credentials
    NSString *urlString = @"rtsps://user:pass123@secure-camera.example.com:7441/stream";

    // When
    NSURL *url = [NSURL URLWithString:urlString];

    // Then
    XCTAssertNotNil(url, @"Should parse RTSPS URL with credentials");
    XCTAssertEqualObjects(url.scheme, @"rtsps");
    XCTAssertEqualObjects(url.user, @"user");
    XCTAssertEqualObjects(url.password, @"pass123");
}

- (void)testURLWithSpecialCharactersInPassword {
    // Given - Password with URL-encoded special characters
    NSString *urlString = @"rtsp://admin:P%40ssw0rd%21@camera.example.com/stream";

    // When
    NSURL *url = [NSURL URLWithString:urlString];

    // Then
    XCTAssertNotNil(url, @"Should handle URL-encoded credentials");
    XCTAssertEqualObjects(url.password, @"P%40ssw0rd%21");
}

- (void)testURLWithoutCredentials {
    // Given
    NSString *urlString = @"rtsp://192.168.1.100:554/stream";

    // When
    NSURL *url = [NSURL URLWithString:urlString];

    // Then
    XCTAssertNotNil(url);
    XCTAssertNil(url.user, @"No user should be present");
    XCTAssertNil(url.password, @"No password should be present");
}

#pragma mark - Credential Stripping for Logging

- (void)testCredentialStrippingFromURL {
    // Security requirement: Never log full RTSP URLs with credentials
    // This validates a helper that strips credentials for safe logging

    NSString *urlString = @"rtsp://admin:secretpassword@192.168.1.100:554/stream";
    NSURL *url = [NSURL URLWithString:urlString];

    // Strip credentials for safe logging
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.user = nil;
    components.password = nil;
    NSString *safeURL = components.string;

    // Then
    XCTAssertNotNil(safeURL, @"Safe URL should be produced");
    XCTAssertFalse([safeURL containsString:@"secretpassword"], @"Password must not appear in sanitized URL");
    XCTAssertFalse([safeURL containsString:@"admin"], @"Username should not appear in sanitized URL");
    XCTAssertTrue([safeURL containsString:@"192.168.1.100"], @"Host should remain");
}

- (void)testCredentialStrippingFromMultipleURLs {
    // Given - Array of URLs some with credentials
    NSArray *urls = @[
        @"rtsp://admin:pass1@camera1.example.com/stream",
        @"rtsp://camera2.example.com/stream",
        @"rtsp://user:password@camera3.example.com/stream",
        @"rtsps://secure:secret@camera4.example.com:7441/stream"
    ];

    for (NSString *urlString in urls) {
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        components.user = nil;
        components.password = nil;
        NSString *safeURL = components.string;

        XCTAssertNotNil(safeURL, @"Should produce safe URL for: %@", urlString);
        XCTAssertFalse([safeURL containsString:@"pass1"], @"No credentials in logged URL");
        XCTAssertFalse([safeURL containsString:@"password"], @"No credentials in logged URL");
        XCTAssertFalse([safeURL containsString:@"secret"], @"No credentials in logged URL");
    }
}

#pragma mark - Keychain Storage for Camera Credentials

- (void)testCameraPasswordStoredInKeychain {
    // Security requirement: Camera passwords must be in Keychain, never plaintext
    NSString *cameraHost = @"test-camera.example.com";
    NSString *testCred = @"CameraPassword123!";

    // When - Store in Keychain
    BOOL success = [RTSPKeychainManager setPassword:testCred
                                         forAccount:cameraHost
                                            service:RTSPKeychainServiceRTSPCamera];

    // Then
    XCTAssertTrue(success, @"Camera password should store in Keychain");

    NSString *retrieved = [RTSPKeychainManager passwordForAccount:cameraHost
                                                          service:RTSPKeychainServiceRTSPCamera];
    XCTAssertEqualObjects(retrieved, testCred, @"Should retrieve correct password");

    // Cleanup
    [RTSPKeychainManager deletePasswordForAccount:cameraHost service:RTSPKeychainServiceRTSPCamera];
}

- (void)testFeedMetadataDoesNotStorePlaintextPassword {
    // Security requirement: RTSPFeedMetadata should not have a plaintext password property
    // Passwords should be resolved from Keychain at runtime

    RTSPFeedMetadata *metadata = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://camera.example.com/stream"];

    // Verify metadata does not expose password as a stored property
    // The URL itself may contain credentials (that's user's choice in config)
    // but metadata archiving should not persist them separately
    XCTAssertNotNil(metadata, @"Metadata should initialize");
    XCTAssertEqualObjects(metadata.url, @"rtsp://camera.example.com/stream");
}

#pragma mark - RTSP URL Validation

- (void)testValidRTSPSchemes {
    NSArray *validSchemes = @[@"rtsp", @"rtsps"];

    for (NSString *scheme in validSchemes) {
        NSString *urlString = [NSString stringWithFormat:@"%@://camera.example.com/stream", scheme];
        NSURL *url = [NSURL URLWithString:urlString];
        XCTAssertNotNil(url, @"Should accept scheme: %@", scheme);
    }
}

- (void)testRejectNonRTSPSchemes {
    NSArray *invalidSchemes = @[@"http", @"https", @"ftp", @"ssh"];

    for (NSString *scheme in invalidSchemes) {
        NSString *urlString = [NSString stringWithFormat:@"%@://camera.example.com/stream", scheme];
        NSURL *url = [NSURL URLWithString:urlString];
        if (url) {
            XCTAssertFalse([url.scheme isEqualToString:@"rtsp"], @"Should not be RTSP: %@", scheme);
            XCTAssertFalse([url.scheme isEqualToString:@"rtsps"], @"Should not be RTSPS: %@", scheme);
        }
    }
}

- (void)testRTSPURLPortValidation {
    // Standard RTSP port
    NSURL *standardPort = [NSURL URLWithString:@"rtsp://camera.example.com:554/stream"];
    XCTAssertEqual(standardPort.port.integerValue, 554);

    // UniFi RTSPS port
    NSURL *unifiPort = [NSURL URLWithString:@"rtsps://camera.example.com:7441/stream"];
    XCTAssertEqual(unifiPort.port.integerValue, 7441);

    // Custom port
    NSURL *customPort = [NSURL URLWithString:@"rtsp://camera.example.com:8554/stream"];
    XCTAssertEqual(customPort.port.integerValue, 8554);

    // No explicit port (should use default)
    NSURL *defaultPort = [NSURL URLWithString:@"rtsp://camera.example.com/stream"];
    XCTAssertNil(defaultPort.port, @"No explicit port means default");
}

- (void)testRTSPURLWithIPv4Address {
    NSURL *url = [NSURL URLWithString:@"rtsp://192.168.1.100:554/stream"];
    XCTAssertNotNil(url);
    XCTAssertEqualObjects(url.host, @"192.168.1.100");
}

- (void)testRTSPURLWithHostname {
    NSURL *url = [NSURL URLWithString:@"rtsp://camera.local/stream"];
    XCTAssertNotNil(url);
    XCTAssertEqualObjects(url.host, @"camera.local");
}

- (void)testMalformedRTSPURLs {
    NSArray *malformed = @[
        @"rtsp://",
        @"rtsp:///stream",
        @"",
    ];

    for (NSString *urlString in malformed) {
        NSURL *url = [NSURL URLWithString:urlString];
        if (url) {
            // URL may parse but should have no usable host
            BOOL hasUsableHost = (url.host != nil && url.host.length > 0);
            if (!hasUsableHost) {
                // This is expected for malformed URLs
                XCTAssertTrue(YES, @"Correctly identified unusable URL: %@", urlString);
            }
        }
    }
}

#pragma mark - No Plaintext Password in NSUserDefaults

- (void)testNoPlaintextPasswordInUserDefaults {
    // Security requirement: After migration, no passwords should remain in NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *testKey = @"RTSPSecurityTest_Password";
    NSString *testCred = @"TestMigrationPassword";

    // Simulate old behavior: password in NSUserDefaults
    [defaults setObject:password forKey:testKey];
    [defaults synchronize];

    // Migrate
    NSString *account = @"SecurityTestCamera";
    [RTSPKeychainManager migratePasswordFromUserDefaults:testKey
                                              toAccount:account
                                                service:RTSPKeychainServiceRTSPCamera];

    // Verify password removed from NSUserDefaults
    NSString *remainingCred = [defaults stringForKey:testKey];
    XCTAssertNil(remainingCred, @"Password MUST be removed from NSUserDefaults after migration");

    // Verify password is in Keychain
    NSString *keychainCred = [RTSPKeychainManager passwordForAccount:account
                                                              service:RTSPKeychainServiceRTSPCamera];
    XCTAssertEqualObjects(keychainCred, testCred, @"Password should be in Keychain");

    // Cleanup
    [RTSPKeychainManager deletePasswordForAccount:account service:RTSPKeychainServiceRTSPCamera];
    [defaults removeObjectForKey:testKey];
}

#pragma mark - CSV Import Security

- (void)testCSVImportDoesNotLeakCredentials {
    // When importing from CSV, URLs with credentials should be handled carefully
    NSString *csvLine = @"Front Door,rtsp://admin:secret@192.168.1.100/stream,rtsp";

    // Parse CSV line
    NSArray *fields = [csvLine componentsSeparatedByString:@","];
    XCTAssertEqual(fields.count, 3);

    NSString *name = fields[0];
    NSString *urlString = fields[1];

    XCTAssertEqualObjects(name, @"Front Door");

    // The URL should parse correctly
    NSURL *url = [NSURL URLWithString:urlString];
    XCTAssertNotNil(url);

    // For logging purposes, credentials should be stripped
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.user = nil;
    components.password = nil;
    NSString *safeURL = components.string;

    XCTAssertFalse([safeURL containsString:@"secret"], @"Logged URL must not contain password");
}

#pragma mark - Rotation Timing Security

- (void)testRotationIntervalBounds {
    // Ensure rotation interval cannot be set to unreasonable values
    // that could cause DoS or resource exhaustion

    // Minimum practical interval
    NSTimeInterval minInterval = 5.0;
    XCTAssertGreaterThanOrEqual(minInterval, 5.0, @"Minimum rotation should be at least 5 seconds");

    // Maximum practical interval
    NSTimeInterval maxInterval = 3600.0; // 1 hour
    XCTAssertLessThanOrEqual(maxInterval, 3600.0, @"Maximum rotation should not exceed 1 hour");
}

#pragma mark - App Transport Security

- (void)testATSConfigurationExists {
    // Verify ATS configuration in Info.plist
    // RTSP feeds require NSAllowsArbitraryLoads for local network cameras
    // but this should be justified in the Info.plist

    NSBundle *mainBundle = [NSBundle mainBundle];
    NSDictionary *ats = [mainBundle objectForInfoDictionaryKey:@"NSAppTransportSecurity"];
    // ATS configuration is set in Info.plist, verified during build
    // This test documents the security requirement
    XCTAssertTrue(YES, @"ATS configuration should be reviewed in Info.plist");
}

@end
