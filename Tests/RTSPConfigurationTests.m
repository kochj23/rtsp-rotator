//
//  RTSPConfigurationTests.m
//  RTSP Rotator Tests
//
//  Tests for configuration management, feed metadata, and persistence
//

#import <XCTest/XCTest.h>
#import "RTSPFeedMetadata.h"
#import "RTSPPreferencesController.h"

@interface RTSPConfigurationTests : XCTestCase
@property (nonatomic, strong) RTSPConfigurationManager *configManager;
@end

@implementation RTSPConfigurationTests

#pragma mark - Setup and Teardown

- (void)setUp {
    [super setUp];
    self.configManager = [[RTSPConfigurationManager alloc] init];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - RTSPFeedMetadata Tests

- (void)testFeedMetadataInitialization {
    // Given
    NSString *url = @"rtsp://camera.example.com/stream";

    // When
    RTSPFeedMetadata *metadata = [[RTSPFeedMetadata alloc] initWithURL:url];

    // Then
    XCTAssertNotNil(metadata, @"Metadata should initialize");
    XCTAssertEqualObjects(metadata.url, url, @"URL should be set");
    XCTAssertTrue(metadata.enabled, @"Should be enabled by default");
    XCTAssertEqual(metadata.healthStatus, RTSPFeedHealthStatusUnknown, @"Health status should be unknown initially");
}

- (void)testFeedMetadataWithDisplayName {
    // Given
    NSString *url = @"rtsp://camera.example.com/stream";
    NSString *displayName = @"Front Door Camera";

    // When
    RTSPFeedMetadata *metadata = [[RTSPFeedMetadata alloc] initWithURL:url displayName:displayName];

    // Then
    XCTAssertEqualObjects(metadata.displayName, displayName, @"Display name should be set");
    XCTAssertEqualObjects([metadata effectiveDisplayName], displayName, @"Effective display name should return custom name");
}

- (void)testFeedMetadataEffectiveDisplayNameFallback {
    // Given - No custom display name
    NSString *url = @"rtsp://camera.example.com/stream";
    RTSPFeedMetadata *metadata = [[RTSPFeedMetadata alloc] initWithURL:url];

    // When
    NSString *effectiveName = [metadata effectiveDisplayName];

    // Then
    XCTAssertEqualObjects(effectiveName, url, @"Should fall back to URL when no display name");
}

- (void)testFeedMetadataHealthTracking {
    // Given
    RTSPFeedMetadata *metadata = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://test.example.com"];

    // When - Simulate successful connection
    metadata.healthStatus = RTSPFeedHealthStatusHealthy;
    metadata.lastSuccessfulConnection = [NSDate date];
    metadata.successfulConnections = 10;
    metadata.totalAttempts = 10;

    // Then
    XCTAssertEqual(metadata.healthStatus, RTSPFeedHealthStatusHealthy);
    XCTAssertNotNil(metadata.lastSuccessfulConnection);
    XCTAssertEqual([metadata uptimePercentage], 1.0, @"100% uptime with 10/10 successful");
}

- (void)testFeedMetadataUptimeCalculation {
    // Given
    RTSPFeedMetadata *metadata = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://test.example.com"];

    // When - 75% uptime (75 successful out of 100 attempts)
    metadata.successfulConnections = 75;
    metadata.totalAttempts = 100;

    // Then
    XCTAssertEqual([metadata uptimePercentage], 0.75, @"Should calculate 75% uptime");
}

- (void)testFeedMetadataUptimeWithZeroAttempts {
    // Given
    RTSPFeedMetadata *metadata = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://test.example.com"];
    metadata.totalAttempts = 0;

    // When
    CGFloat uptime = [metadata uptimePercentage];

    // Then
    XCTAssertEqual(uptime, 0.0, @"Should return 0% uptime with zero attempts");
}

- (void)testFeedMetadataConsecutiveFailures {
    // Given
    RTSPFeedMetadata *metadata = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://test.example.com"];

    // When - Track failures
    metadata.consecutiveFailures = 5;
    metadata.lastFailedConnection = [NSDate date];
    metadata.healthStatus = RTSPFeedHealthStatusUnhealthy;

    // Then
    XCTAssertEqual(metadata.consecutiveFailures, 5);
    XCTAssertNotNil(metadata.lastFailedConnection);
    XCTAssertEqual(metadata.healthStatus, RTSPFeedHealthStatusUnhealthy);
}

#pragma mark - RTSPFeedMetadata Coding Tests

- (void)testFeedMetadataArchiving {
    // Given
    RTSPFeedMetadata *original = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://test.example.com"
                                                            displayName:@"Test Camera"];
    original.category = @"Office";
    original.enabled = YES;
    original.healthStatus = RTSPFeedHealthStatusHealthy;
    original.successfulConnections = 10;
    original.totalAttempts = 12;
    original.notes = @"Test notes";

    // When - Archive and unarchive
    NSError *error = nil;
    NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:original
                                                 requiringSecureCoding:YES
                                                                 error:&error];

    XCTAssertNotNil(archivedData, @"Should archive successfully");
    XCTAssertNil(error, @"Should not have archiving error");

    RTSPFeedMetadata *unarchived = [NSKeyedUnarchiver unarchivedObjectOfClass:[RTSPFeedMetadata class]
                                                                      fromData:archivedData
                                                                         error:&error];

    // Then
    XCTAssertNotNil(unarchived, @"Should unarchive successfully");
    XCTAssertNil(error, @"Should not have unarchiving error");
    XCTAssertEqualObjects(unarchived.url, original.url);
    XCTAssertEqualObjects(unarchived.displayName, original.displayName);
    XCTAssertEqualObjects(unarchived.category, original.category);
    XCTAssertEqual(unarchived.enabled, original.enabled);
    XCTAssertEqual(unarchived.healthStatus, original.healthStatus);
    XCTAssertEqual(unarchived.successfulConnections, original.successfulConnections);
    XCTAssertEqual(unarchived.totalAttempts, original.totalAttempts);
    XCTAssertEqualObjects(unarchived.notes, original.notes);
}

- (void)testFeedMetadataSecureCoding {
    // Then
    XCTAssertTrue([RTSPFeedMetadata supportsSecureCoding], @"RTSPFeedMetadata should support secure coding");
}

#pragma mark - Configuration Manager Tests

- (void)testConfigurationManagerSharedInstance {
    // When
    RTSPConfigurationManager *manager1 = [RTSPConfigurationManager sharedManager];
    RTSPConfigurationManager *manager2 = [RTSPConfigurationManager sharedManager];

    // Then
    XCTAssertNotNil(manager1, @"Shared manager should exist");
    XCTAssertEqual(manager1, manager2, @"Shared manager should return same instance");
}

- (void)testConfigurationManagerDefaults {
    // When
    RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];

    // Then - Verify sensible defaults
    XCTAssertEqual(manager.rotationInterval, 60.0, @"Default rotation interval should be 60 seconds");
    XCTAssertTrue(manager.startMuted, @"Should start muted by default");
    XCTAssertEqual(manager.retryAttempts, 3, @"Default retry attempts should be 3");
}

- (void)testAddManualFeed {
    // Given
    RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];
    NSString *feedURL = @"rtsp://new-camera.example.com/stream";
    NSUInteger initialCount = manager.manualFeeds.count;

    // When
    [manager addManualFeed:feedURL];

    // Then
    XCTAssertEqual(manager.manualFeeds.count, initialCount + 1, @"Should add one feed");
    XCTAssertTrue([manager.manualFeeds containsObject:feedURL], @"Should contain new feed");
}

- (void)testRemoveManualFeedAtIndex {
    // Given
    RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];
    [manager addManualFeed:@"rtsp://feed1.example.com"];
    [manager addManualFeed:@"rtsp://feed2.example.com"];
    [manager addManualFeed:@"rtsp://feed3.example.com"];
    NSUInteger countBefore = manager.manualFeeds.count;

    // When
    [manager removeManualFeedAtIndex:1]; // Remove second feed

    // Then
    XCTAssertEqual(manager.manualFeeds.count, countBefore - 1, @"Should remove one feed");
    XCTAssertFalse([manager.manualFeeds containsObject:@"rtsp://feed2.example.com"], @"Removed feed should not exist");
}

- (void)testUpdateManualFeedAtIndex {
    // Given
    RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];
    [manager addManualFeed:@"rtsp://original.example.com"];
    NSString *newURL = @"rtsp://updated.example.com";

    // When
    [manager updateManualFeedAtIndex:0 withURL:newURL];

    // Then
    XCTAssertEqualObjects(manager.manualFeeds[0], newURL, @"Feed should be updated");
}

#pragma mark - Configuration Source Tests

- (void)testConfigurationSourceManual {
    // Given
    RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];

    // When
    manager.configurationSource = RTSPConfigurationSourceManual;

    // Then
    XCTAssertEqual(manager.configurationSource, RTSPConfigurationSourceManual, @"Should set manual source");
}

- (void)testConfigurationSourceRemoteURL {
    // Given
    RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];
    NSString *remoteURL = @"https://example.com/cameras.txt";

    // When
    manager.configurationSource = RTSPConfigurationSourceRemoteURL;
    manager.remoteConfigurationURL = remoteURL;

    // Then
    XCTAssertEqual(manager.configurationSource, RTSPConfigurationSourceRemoteURL);
    XCTAssertEqualObjects(manager.remoteConfigurationURL, remoteURL);
}

#pragma mark - Display Settings Tests

- (void)testGridLayoutSettings {
    // Given
    RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];

    // When
    manager.gridLayoutEnabled = YES;
    manager.gridRows = 3;
    manager.gridColumns = 3;

    // Then
    XCTAssertTrue(manager.gridLayoutEnabled);
    XCTAssertEqual(manager.gridRows, 3);
    XCTAssertEqual(manager.gridColumns, 3);
}

- (void)testDisplayIndexSetting {
    // Given
    RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];

    // When
    manager.displayIndex = 2; // Third display

    // Then
    XCTAssertEqual(manager.displayIndex, 2, @"Display index should be set");
}

#pragma mark - OSD Settings Tests

- (void)testOSDSettings {
    // Given
    RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];

    // When
    manager.osdEnabled = YES;
    manager.osdDuration = 3.0;
    manager.osdPosition = 1; // Top-right

    // Then
    XCTAssertTrue(manager.osdEnabled);
    XCTAssertEqual(manager.osdDuration, 3.0);
    XCTAssertEqual(manager.osdPosition, 1);
}

#pragma mark - Recording Settings Tests

- (void)testRecordingSettings {
    // Given
    RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];
    NSString *snapshotDir = @"/Users/test/Snapshots";

    // When
    manager.autoSnapshotsEnabled = YES;
    manager.snapshotInterval = 300.0; // 5 minutes
    manager.snapshotDirectory = snapshotDir;

    // Then
    XCTAssertTrue(manager.autoSnapshotsEnabled);
    XCTAssertEqual(manager.snapshotInterval, 300.0);
    XCTAssertEqualObjects(manager.snapshotDirectory, snapshotDir);
}

#pragma mark - Playback Settings Tests

- (void)testRotationIntervalSetting {
    // Given
    RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];

    // When
    manager.rotationInterval = 45.0;

    // Then
    XCTAssertEqual(manager.rotationInterval, 45.0, @"Rotation interval should be set");
}

- (void)testAutoSkipFailedFeeds {
    // Given
    RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];

    // When
    manager.autoSkipFailedFeeds = YES;
    manager.retryAttempts = 5;

    // Then
    XCTAssertTrue(manager.autoSkipFailedFeeds);
    XCTAssertEqual(manager.retryAttempts, 5);
}

#pragma mark - Feed Validation Tests

- (void)testValidRTSPURLFormats {
    NSArray *validURLs = @[
        @"rtsp://192.168.1.100:554/stream",
        @"rtsp://admin:password@camera.local/live",
        @"rtsps://secure-camera.example.com:7441/stream?enableSrtp",
        @"rtsp://camera.local:8554/h264",
        @"rtsp://[2001:db8::1]:554/stream" // IPv6
    ];

    for (NSString *urlString in validURLs) {
        NSURL *url = [NSURL URLWithString:urlString];
        XCTAssertNotNil(url, @"Should parse valid RTSP URL: %@", urlString);
    }
}

- (void)testSecureRTSPSURLs {
    // Given
    NSString *secureURL = @"rtsps://secure-camera.example.com:7441/stream";

    // When
    NSURL *url = [NSURL URLWithString:secureURL];

    // Then
    XCTAssertNotNil(url, @"Should parse RTSPS URL");
    XCTAssertEqualObjects(url.scheme, @"rtsps", @"Scheme should be rtsps");
    XCTAssertEqualObjects(url.host, @"secure-camera.example.com");
    XCTAssertEqual(url.port.integerValue, 7441);
}

#pragma mark - Feed Array Management Tests

- (void)testMoveManualFeedFromIndexToIndex {
    // Given
    RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];
    [manager addManualFeed:@"rtsp://feed1.example.com"];
    [manager addManualFeed:@"rtsp://feed2.example.com"];
    [manager addManualFeed:@"rtsp://feed3.example.com"];

    // When - Move feed from index 0 to index 2
    [manager moveManualFeedFromIndex:0 toIndex:2];

    // Then
    NSArray *feeds = manager.manualFeeds;
    XCTAssertEqual(feeds.count, 3, @"Should still have 3 feeds");
    XCTAssertEqualObjects(feeds[2], @"rtsp://feed1.example.com", @"First feed should be at index 2");
    XCTAssertEqualObjects(feeds[0], @"rtsp://feed2.example.com", @"Second feed should be at index 0");
}

#pragma mark - Category Management Tests

- (void)testFeedCategoryOrganization {
    // Given - Feeds with different categories
    RTSPFeedMetadata *unifiCamera = [[RTSPFeedMetadata alloc] initWithURL:@"rtsps://10.0.0.1:7441/camera1"];
    unifiCamera.category = @"UniFi Protect";
    unifiCamera.displayName = @"Front Door";

    RTSPFeedMetadata *manualCamera = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://192.168.1.50:554/stream"];
    manualCamera.category = @"Manual";
    manualCamera.displayName = @"DVR Camera";

    RTSPFeedMetadata *googleCamera = [[RTSPFeedMetadata alloc] initWithURL:@"rtsps://streaming.example.com/xyz"];
    googleCamera.category = @"Google Home";
    googleCamera.displayName = @"Nest Camera";

    // When - Group by category
    NSArray *allFeeds = @[unifiCamera, manualCamera, googleCamera];
    NSMutableDictionary *groupedByCategory = [NSMutableDictionary dictionary];

    for (RTSPFeedMetadata *feed in allFeeds) {
        NSString *category = feed.category ?: @"Uncategorized";
        if (!groupedByCategory[category]) {
            groupedByCategory[category] = [NSMutableArray array];
        }
        [groupedByCategory[category] addObject:feed];
    }

    // Then
    XCTAssertEqual(groupedByCategory.count, 3, @"Should have 3 categories");
    XCTAssertEqual([groupedByCategory[@"UniFi Protect"] count], 1);
    XCTAssertEqual([groupedByCategory[@"Manual"] count], 1);
    XCTAssertEqual([groupedByCategory[@"Google Home"] count], 1);
}

#pragma mark - Edge Case Tests

- (void)testEmptyFeedArray {
    // Given
    RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];

    // When
    manager.manualFeeds = @[];

    // Then
    XCTAssertNotNil(manager.manualFeeds, @"Feed array should not be nil");
    XCTAssertEqual(manager.manualFeeds.count, 0, @"Feed array should be empty");
}

- (void)testNilFeedMetadataArray {
    // Given
    RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];

    // When
    manager.manualFeedMetadata = nil;

    // Then - Should handle gracefully
    XCTAssertNotNil(manager.manualFeedMetadata, @"Should provide empty array instead of nil");
}

#pragma mark - Status Menu Settings Tests

- (void)testStatusMenuSetting {
    // Given
    RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];

    // When
    manager.statusMenuEnabled = YES;

    // Then
    XCTAssertTrue(manager.statusMenuEnabled, @"Status menu should be enabled");
}

#pragma mark - Performance Tests

- (void)testLargeFeedArrayPerformance {
    [self measureBlock:^{
        RTSPConfigurationManager *manager = [[RTSPConfigurationManager alloc] init];
        NSMutableArray *feeds = [NSMutableArray array];

        for (int i = 0; i < 100; i++) {
            RTSPFeedMetadata *metadata = [[RTSPFeedMetadata alloc] initWithURL:[NSString stringWithFormat:@"rtsp://camera%d.example.com", i]];
            metadata.displayName = [NSString stringWithFormat:@"Camera %d", i];
            metadata.category = @"Test";
            [feeds addObject:metadata];
        }

        manager.manualFeedMetadata = feeds;

        XCTAssertEqual(manager.manualFeedMetadata.count, 100);
    }];
}

- (void)testMetadataArchivingPerformance {
    // Given
    NSMutableArray *feeds = [NSMutableArray array];
    for (int i = 0; i < 50; i++) {
        RTSPFeedMetadata *metadata = [[RTSPFeedMetadata alloc] initWithURL:[NSString stringWithFormat:@"rtsp://camera%d.example.com", i]];
        [feeds addObject:metadata];
    }

    // When/Then
    [self measureBlock:^{
        NSError *error = nil;
        NSData *archived = [NSKeyedArchiver archivedDataWithRootObject:feeds
                                                 requiringSecureCoding:YES
                                                                 error:&error];
        XCTAssertNotNil(archived);

        NSArray *unarchived = [NSKeyedUnarchiver unarchivedArrayOfObjectsOfClass:[RTSPFeedMetadata class]
                                                                         fromData:archived
                                                                            error:&error];
        XCTAssertEqual(unarchived.count, 50);
    }];
}

@end
