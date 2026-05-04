//
//  RTSPComprehensiveTests.m
//  RTSP Rotator Tests
//
//  Comprehensive test suite covering unit, security, integration,
//  functional, and framework tests for RTSP Rotator.
//
//  Written by Jordan Koch
//

#import <XCTest/XCTest.h>
#import "RTSPFeedMetadata.h"
#import "RTSPKeychainManager.h"
#import "RTSPBandwidthManager.h"
#import "RTSPTransitionController.h"
#import "RTSPFailoverManager.h"
#import "RTSPScheduleManager.h"
#import "RTSPEventLogger.h"
#import "RTSPThemeManager.h"
#import "RTSPFeedGroupManager.h"

#pragma mark - RTSPFeedMetadata Unit Tests

@interface RTSPFeedMetadataUnitTests : XCTestCase
@end

@implementation RTSPFeedMetadataUnitTests

- (void)testInitWithURL {
    RTSPFeedMetadata *feed = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://192.168.1.100/stream"];
    XCTAssertEqualObjects(feed.url, @"rtsp://192.168.1.100/stream");
    XCTAssertNil(feed.displayName);
    XCTAssertTrue(feed.enabled);
    XCTAssertEqual(feed.healthStatus, RTSPFeedHealthStatusUnknown);
    XCTAssertEqual(feed.consecutiveFailures, 0);
    XCTAssertEqual(feed.totalAttempts, 0);
    XCTAssertEqual(feed.successfulConnections, 0);
}

- (void)testInitWithURLAndDisplayName {
    RTSPFeedMetadata *feed = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://cam1/stream"
                                                        displayName:@"Front Door"];
    XCTAssertEqualObjects(feed.url, @"rtsp://cam1/stream");
    XCTAssertEqualObjects(feed.displayName, @"Front Door");
}

- (void)testEffectiveDisplayNameUsesDisplayName {
    RTSPFeedMetadata *feed = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://cam/stream"
                                                        displayName:@"Garage"];
    XCTAssertEqualObjects([feed effectiveDisplayName], @"Garage");
}

- (void)testEffectiveDisplayNameFallsBackToURL {
    RTSPFeedMetadata *feed = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://cam/stream"];
    XCTAssertEqualObjects([feed effectiveDisplayName], @"rtsp://cam/stream");
}

- (void)testUptimePercentageZeroAttempts {
    RTSPFeedMetadata *feed = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://test/stream"];
    XCTAssertEqual([feed uptimePercentage], 0.0);
}

- (void)testUptimePercentage100Percent {
    RTSPFeedMetadata *feed = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://test/stream"];
    feed.totalAttempts = 100;
    feed.successfulConnections = 100;
    XCTAssertEqualWithAccuracy([feed uptimePercentage], 100.0, 0.01);
}

- (void)testUptimePercentage50Percent {
    RTSPFeedMetadata *feed = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://test/stream"];
    feed.totalAttempts = 200;
    feed.successfulConnections = 100;
    XCTAssertEqualWithAccuracy([feed uptimePercentage], 50.0, 0.01);
}

- (void)testHealthStatusEnum {
    RTSPFeedMetadata *feed = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://test/stream"];
    feed.healthStatus = RTSPFeedHealthStatusHealthy;
    XCTAssertEqual(feed.healthStatus, RTSPFeedHealthStatusHealthy);

    feed.healthStatus = RTSPFeedHealthStatusDegraded;
    XCTAssertEqual(feed.healthStatus, RTSPFeedHealthStatusDegraded);

    feed.healthStatus = RTSPFeedHealthStatusUnhealthy;
    XCTAssertEqual(feed.healthStatus, RTSPFeedHealthStatusUnhealthy);
}

- (void)testFeedMetadataDescription {
    RTSPFeedMetadata *feed = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://test/stream"
                                                        displayName:@"TestCam"];
    NSString *desc = [feed description];
    XCTAssertTrue([desc containsString:@"TestCam"]);
    XCTAssertTrue([desc containsString:@"rtsp://test/stream"]);
}

- (void)testSecureCodingRoundTrip {
    RTSPFeedMetadata *original = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://test/stream"
                                                            displayName:@"Test"];
    original.category = @"Outdoor";
    original.healthStatus = RTSPFeedHealthStatusHealthy;
    original.totalAttempts = 50;
    original.successfulConnections = 45;
    original.notes = @"Test notes";

    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:original
                                         requiringSecureCoding:YES
                                                         error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(data);

    RTSPFeedMetadata *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[RTSPFeedMetadata class]
                                                                  fromData:data
                                                                     error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(decoded);
    XCTAssertEqualObjects(decoded.url, @"rtsp://test/stream");
    XCTAssertEqualObjects(decoded.displayName, @"Test");
    XCTAssertEqualObjects(decoded.category, @"Outdoor");
    XCTAssertEqual(decoded.healthStatus, RTSPFeedHealthStatusHealthy);
    XCTAssertEqual(decoded.totalAttempts, 50);
    XCTAssertEqual(decoded.successfulConnections, 45);
    XCTAssertEqualObjects(decoded.notes, @"Test notes");
}

- (void)testSupportsSecureCoding {
    XCTAssertTrue([RTSPFeedMetadata supportsSecureCoding]);
}

- (void)testConsecutiveFailuresTracking {
    RTSPFeedMetadata *feed = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://test/stream"];
    feed.consecutiveFailures = 5;
    XCTAssertEqual(feed.consecutiveFailures, 5);
    feed.consecutiveFailures = 0;
    XCTAssertEqual(feed.consecutiveFailures, 0);
}

- (void)testLastConnectionTimestamps {
    RTSPFeedMetadata *feed = [[RTSPFeedMetadata alloc] initWithURL:@"rtsp://test/stream"];
    XCTAssertNil(feed.lastSuccessfulConnection);
    XCTAssertNil(feed.lastFailedConnection);

    NSDate *now = [NSDate date];
    feed.lastSuccessfulConnection = now;
    XCTAssertEqualObjects(feed.lastSuccessfulConnection, now);
}

@end

#pragma mark - RTSPKeychainManager Security Tests

@interface RTSPKeychainManagerSecurityTests : XCTestCase
@end

@implementation RTSPKeychainManagerSecurityTests

- (void)setUp {
    [super setUp];
    // Clean up any test keychain entries
    [RTSPKeychainManager deletePasswordForAccount:@"test_account"
                                          service:@"com.rtsp-rotator.test"];
}

- (void)tearDown {
    [RTSPKeychainManager deletePasswordForAccount:@"test_account"
                                          service:@"com.rtsp-rotator.test"];
    [super tearDown];
}

- (void)testSetAndRetrievePassword {
    BOOL setResult = [RTSPKeychainManager setPassword:@"testpass123"
                                           forAccount:@"test_account"
                                              service:@"com.rtsp-rotator.test"];
    XCTAssertTrue(setResult);

    NSString *retrieved = [RTSPKeychainManager passwordForAccount:@"test_account"
                                                          service:@"com.rtsp-rotator.test"];
    XCTAssertEqualObjects(retrieved, @"testpass123");
}

- (void)testUpdateExistingPassword {
    [RTSPKeychainManager setPassword:@"original"
                          forAccount:@"test_account"
                             service:@"com.rtsp-rotator.test"];

    BOOL updated = [RTSPKeychainManager setPassword:@"updated"
                                         forAccount:@"test_account"
                                            service:@"com.rtsp-rotator.test"];
    XCTAssertTrue(updated);

    NSString *retrieved = [RTSPKeychainManager passwordForAccount:@"test_account"
                                                          service:@"com.rtsp-rotator.test"];
    XCTAssertEqualObjects(retrieved, @"updated");
}

- (void)testDeletePassword {
    [RTSPKeychainManager setPassword:@"tobedeleted"
                          forAccount:@"test_account"
                             service:@"com.rtsp-rotator.test"];

    BOOL deleted = [RTSPKeychainManager deletePasswordForAccount:@"test_account"
                                                         service:@"com.rtsp-rotator.test"];
    XCTAssertTrue(deleted);

    NSString *retrieved = [RTSPKeychainManager passwordForAccount:@"test_account"
                                                          service:@"com.rtsp-rotator.test"];
    XCTAssertNil(retrieved);
}

- (void)testDeleteNonexistentPasswordSucceeds {
    BOOL result = [RTSPKeychainManager deletePasswordForAccount:@"nonexistent"
                                                        service:@"com.rtsp-rotator.test"];
    XCTAssertTrue(result, @"Deleting nonexistent password should succeed");
}

- (void)testRetrieveNonexistentPasswordReturnsNil {
    NSString *result = [RTSPKeychainManager passwordForAccount:@"nonexistent"
                                                       service:@"com.rtsp-rotator.test"];
    XCTAssertNil(result);
}

- (void)testHasPasswordReturnsTrueWhenExists {
    [RTSPKeychainManager setPassword:@"test"
                          forAccount:@"test_account"
                             service:@"com.rtsp-rotator.test"];

    BOOL exists = [RTSPKeychainManager hasPasswordForAccount:@"test_account"
                                                     service:@"com.rtsp-rotator.test"];
    XCTAssertTrue(exists);
}

- (void)testHasPasswordReturnsFalseWhenMissing {
    BOOL exists = [RTSPKeychainManager hasPasswordForAccount:@"nonexistent"
                                                     service:@"com.rtsp-rotator.test"];
    XCTAssertFalse(exists);
}

- (void)testNilPasswordRejected {
    BOOL result = [RTSPKeychainManager setPassword:nil
                                        forAccount:@"test_account"
                                           service:@"com.rtsp-rotator.test"];
    XCTAssertFalse(result, @"nil password should be rejected");
}

- (void)testNilAccountRejected {
    BOOL result = [RTSPKeychainManager setPassword:@"test"
                                        forAccount:nil
                                           service:@"com.rtsp-rotator.test"];
    XCTAssertFalse(result, @"nil account should be rejected");
}

- (void)testNilServiceRejected {
    BOOL result = [RTSPKeychainManager setPassword:@"test"
                                        forAccount:@"test_account"
                                           service:nil];
    XCTAssertFalse(result, @"nil service should be rejected");
}

- (void)testSetAndRetrieveData {
    NSData *testData = [@"binary test data" dataUsingEncoding:NSUTF8StringEncoding];
    BOOL stored = [RTSPKeychainManager setData:testData
                                    forAccount:@"test_account"
                                       service:@"com.rtsp-rotator.test"];
    XCTAssertTrue(stored);

    NSData *retrieved = [RTSPKeychainManager dataForAccount:@"test_account"
                                                    service:@"com.rtsp-rotator.test"];
    XCTAssertEqualObjects(retrieved, testData);
}

- (void)testServiceConstants {
    XCTAssertNotNil(RTSPKeychainServiceUniFiProtect);
    XCTAssertNotNil(RTSPKeychainServiceGoogleHome);
    XCTAssertNotNil(RTSPKeychainServiceRTSPCamera);
    XCTAssertTrue([RTSPKeychainServiceUniFiProtect containsString:@"unifi"]);
}

- (void)testSpecialCharactersInPassword {
    NSString *specialPass = @"p@$$w0rd!#%^&*()_+-=[]{}|;':\",./<>?";
    BOOL stored = [RTSPKeychainManager setPassword:specialPass
                                        forAccount:@"test_account"
                                           service:@"com.rtsp-rotator.test"];
    XCTAssertTrue(stored);

    NSString *retrieved = [RTSPKeychainManager passwordForAccount:@"test_account"
                                                          service:@"com.rtsp-rotator.test"];
    XCTAssertEqualObjects(retrieved, specialPass);
}

- (void)testUnicodeInPassword {
    NSString *unicodePass = @"éèêë中文テスト";
    BOOL stored = [RTSPKeychainManager setPassword:unicodePass
                                        forAccount:@"test_account"
                                           service:@"com.rtsp-rotator.test"];
    XCTAssertTrue(stored);

    NSString *retrieved = [RTSPKeychainManager passwordForAccount:@"test_account"
                                                          service:@"com.rtsp-rotator.test"];
    XCTAssertEqualObjects(retrieved, unicodePass);
}

@end

#pragma mark - RTSPBandwidthManager Unit Tests

@interface RTSPBandwidthManagerUnitTests : XCTestCase
@end

@implementation RTSPBandwidthManagerUnitTests

- (void)testSharedManagerSingleton {
    RTSPBandwidthManager *m1 = [RTSPBandwidthManager sharedManager];
    RTSPBandwidthManager *m2 = [RTSPBandwidthManager sharedManager];
    XCTAssertEqual(m1, m2, @"sharedManager must return same instance");
}

- (void)testDefaultQualityPreset {
    RTSPBandwidthManager *manager = [[RTSPBandwidthManager alloc] init];
    XCTAssertEqual(manager.qualityPreset, RTSPQualityPresetAuto);
}

- (void)testDefaultMaxBandwidth {
    RTSPBandwidthManager *manager = [[RTSPBandwidthManager alloc] init];
    XCTAssertEqual(manager.maxBandwidthMbps, 10.0);
}

- (void)testAutoQualityEnabledByDefault {
    RTSPBandwidthManager *manager = [[RTSPBandwidthManager alloc] init];
    XCTAssertTrue(manager.autoQualityEnabled);
}

- (void)testRecommendedQualityLow {
    RTSPBandwidthManager *manager = [[RTSPBandwidthManager alloc] init];
    manager.maxBandwidthMbps = 1.0;
    XCTAssertEqualObjects([manager recommendedQuality], @"Low");
}

- (void)testRecommendedQualityMedium {
    RTSPBandwidthManager *manager = [[RTSPBandwidthManager alloc] init];
    manager.maxBandwidthMbps = 3.0;
    XCTAssertEqualObjects([manager recommendedQuality], @"Medium");
}

- (void)testRecommendedQualityHigh {
    RTSPBandwidthManager *manager = [[RTSPBandwidthManager alloc] init];
    manager.maxBandwidthMbps = 10.0;
    XCTAssertEqualObjects([manager recommendedQuality], @"High");
}

- (void)testQualityPresetAssignment {
    RTSPBandwidthManager *manager = [[RTSPBandwidthManager alloc] init];
    manager.qualityPreset = RTSPQualityPresetHigh;
    XCTAssertEqual(manager.qualityPreset, RTSPQualityPresetHigh);
}

@end

#pragma mark - RTSPTransitionController Unit Tests

@interface RTSPTransitionControllerUnitTests : XCTestCase
@end

@implementation RTSPTransitionControllerUnitTests

- (void)testDefaultDuration {
    RTSPTransitionController *tc = [[RTSPTransitionController alloc] init];
    XCTAssertEqual(tc.duration, 0.5);
}

- (void)testDefaultTransitionType {
    RTSPTransitionController *tc = [[RTSPTransitionController alloc] init];
    XCTAssertEqual(tc.transitionType, RTSPTransitionTypeFade);
}

- (void)testDefaultTimingFunction {
    RTSPTransitionController *tc = [[RTSPTransitionController alloc] init];
    XCTAssertNotNil(tc.timingFunction);
}

- (void)testNameForTransitionTypeNone {
    XCTAssertEqualObjects([RTSPTransitionController nameForTransitionType:RTSPTransitionTypeNone], @"None");
}

- (void)testNameForTransitionTypeFade {
    XCTAssertEqualObjects([RTSPTransitionController nameForTransitionType:RTSPTransitionTypeFade], @"Fade");
}

- (void)testNameForTransitionTypeSlideLeft {
    XCTAssertEqualObjects([RTSPTransitionController nameForTransitionType:RTSPTransitionTypeSlideLeft], @"Slide Left");
}

- (void)testNameForTransitionTypeCube {
    XCTAssertEqualObjects([RTSPTransitionController nameForTransitionType:RTSPTransitionTypeCube], @"Cube");
}

- (void)testNameForTransitionTypeFlip {
    XCTAssertEqualObjects([RTSPTransitionController nameForTransitionType:RTSPTransitionTypeFlip], @"Flip");
}

- (void)testAllTransitionTypesCount {
    NSArray *types = [RTSPTransitionController allTransitionTypes];
    XCTAssertEqual(types.count, 12, @"Should have 12 transition types");
}

- (void)testAllTransitionTypesContainsNone {
    NSArray *types = [RTSPTransitionController allTransitionTypes];
    XCTAssertTrue([types containsObject:@(RTSPTransitionTypeNone)]);
}

- (void)testAllTransitionTypesContainsFade {
    NSArray *types = [RTSPTransitionController allTransitionTypes];
    XCTAssertTrue([types containsObject:@(RTSPTransitionTypeFade)]);
}

- (void)testAllTransitionTypesContainsFlip {
    NSArray *types = [RTSPTransitionController allTransitionTypes];
    XCTAssertTrue([types containsObject:@(RTSPTransitionTypeFlip)]);
}

- (void)testTransitionTypeAssignment {
    RTSPTransitionController *tc = [[RTSPTransitionController alloc] init];
    tc.transitionType = RTSPTransitionTypeZoomIn;
    XCTAssertEqual(tc.transitionType, RTSPTransitionTypeZoomIn);
}

- (void)testDurationAssignment {
    RTSPTransitionController *tc = [[RTSPTransitionController alloc] init];
    tc.duration = 1.5;
    XCTAssertEqual(tc.duration, 1.5);
}

@end

#pragma mark - RTSPFailoverManager Integration Tests

@interface RTSPFailoverManagerIntegrationTests : XCTestCase
@property (nonatomic, strong) RTSPFailoverManager *manager;
@end

@implementation RTSPFailoverManagerIntegrationTests

- (void)setUp {
    [super setUp];
    self.manager = [[RTSPFailoverManager alloc] init];
}

- (void)testDefaultConfiguration {
    XCTAssertEqual(self.manager.healthCheckInterval, 30.0);
    XCTAssertEqual(self.manager.connectionTimeout, 10.0);
    XCTAssertEqual(self.manager.maxRetryAttempts, 3);
    XCTAssertTrue(self.manager.autoFailoverEnabled);
}

- (void)testRegisterFeed {
    RTSPFeedConfig *feed = [[RTSPFeedConfig alloc] init];
    feed.name = @"Test Camera";
    feed.primaryURL = [NSURL URLWithString:@"rtsp://192.168.1.100/stream"];

    [self.manager registerFeed:feed];

    XCTAssertEqual([self.manager feeds].count, 1);
    XCTAssertEqualObjects(feed.activeURL, feed.primaryURL);
    XCTAssertEqual(feed.status, RTSPFeedStatusUnknown);
}

- (void)testUnregisterFeed {
    RTSPFeedConfig *feed = [[RTSPFeedConfig alloc] init];
    feed.name = @"Test Camera";
    feed.primaryURL = [NSURL URLWithString:@"rtsp://192.168.1.100/stream"];

    [self.manager registerFeed:feed];
    XCTAssertEqual([self.manager feeds].count, 1);

    [self.manager unregisterFeed:feed];
    XCTAssertEqual([self.manager feeds].count, 0);
}

- (void)testDuplicateRegistrationIgnored {
    RTSPFeedConfig *feed = [[RTSPFeedConfig alloc] init];
    feed.name = @"Test Camera";
    feed.primaryURL = [NSURL URLWithString:@"rtsp://192.168.1.100/stream"];

    [self.manager registerFeed:feed];
    [self.manager registerFeed:feed];

    XCTAssertEqual([self.manager feeds].count, 1);
}

- (void)testActiveURLReturnsPrimaryByDefault {
    RTSPFeedConfig *feed = [[RTSPFeedConfig alloc] init];
    feed.name = @"Test";
    feed.primaryURL = [NSURL URLWithString:@"rtsp://primary/stream"];

    [self.manager registerFeed:feed];

    NSURL *active = [self.manager activeURLForFeed:feed];
    XCTAssertEqualObjects(active, feed.primaryURL);
}

- (void)testFailoverWithNoBackupURLs {
    RTSPFeedConfig *feed = [[RTSPFeedConfig alloc] init];
    feed.name = @"No Backups";
    feed.primaryURL = [NSURL URLWithString:@"rtsp://primary/stream"];
    feed.backupURLs = nil;

    XCTestExpectation *exp = [self expectationWithDescription:@"Failover completion"];
    [self.manager failoverFeed:feed completion:^(BOOL success, NSURL *activeURL) {
        XCTAssertFalse(success);
        XCTAssertNil(activeURL);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testFailoverWithEmptyBackupURLs {
    RTSPFeedConfig *feed = [[RTSPFeedConfig alloc] init];
    feed.name = @"Empty Backups";
    feed.primaryURL = [NSURL URLWithString:@"rtsp://primary/stream"];
    feed.backupURLs = @[];

    XCTestExpectation *exp = [self expectationWithDescription:@"Failover completion"];
    [self.manager failoverFeed:feed completion:^(BOOL success, NSURL *activeURL) {
        XCTAssertFalse(success);
        XCTAssertNil(activeURL);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testFeedsReturnsImmutableCopy {
    RTSPFeedConfig *feed = [[RTSPFeedConfig alloc] init];
    feed.name = @"Test";
    feed.primaryURL = [NSURL URLWithString:@"rtsp://test/stream"];
    [self.manager registerFeed:feed];

    NSArray *feeds = [self.manager feeds];
    XCTAssertEqual(feeds.count, 1);
    // The returned array should be a copy
    XCTAssertFalse([feeds isKindOfClass:[NSMutableArray class]]);
}

@end

#pragma mark - RTSPScheduleManager Functional Tests

@interface RTSPScheduleManagerFunctionalTests : XCTestCase
@end

@implementation RTSPScheduleManagerFunctionalTests

- (void)testScheduleProfileInit {
    RTSPScheduleProfile *profile = [[RTSPScheduleProfile alloc] init];
    XCTAssertNotNil(profile.profileID);
    XCTAssertTrue(profile.enabled);
    XCTAssertEqual(profile.rotationInterval, 10.0);
}

- (void)testScheduleRuleInit {
    RTSPScheduleRule *rule = [[RTSPScheduleRule alloc] init];
    XCTAssertNotNil(rule.ruleID);
    XCTAssertTrue(rule.enabled);
}

- (void)testRuleActiveWhenEnabled {
    RTSPScheduleRule *rule = [[RTSPScheduleRule alloc] init];
    rule.enabled = YES;
    XCTAssertTrue([rule isActiveAtDate:[NSDate date]]);
}

- (void)testRuleInactiveWhenDisabled {
    RTSPScheduleRule *rule = [[RTSPScheduleRule alloc] init];
    rule.enabled = NO;
    XCTAssertFalse([rule isActiveAtDate:[NSDate date]]);
}

- (void)testRuleWithDayOfWeekConstraint {
    RTSPScheduleRule *rule = [[RTSPScheduleRule alloc] init];
    rule.enabled = YES;

    // Set to only active on a specific day
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *todayComponents = [calendar components:NSCalendarUnitWeekday fromDate:[NSDate date]];
    rule.daysOfWeek = [NSSet setWithObject:@(todayComponents.weekday)];

    XCTAssertTrue([rule isActiveAtDate:[NSDate date]]);
}

- (void)testRuleWithWrongDayOfWeekIsInactive {
    RTSPScheduleRule *rule = [[RTSPScheduleRule alloc] init];
    rule.enabled = YES;

    // Set to a day that is NOT today
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *todayComponents = [calendar components:NSCalendarUnitWeekday fromDate:[NSDate date]];
    NSInteger wrongDay = (todayComponents.weekday % 7) + 1; // different day
    rule.daysOfWeek = [NSSet setWithObject:@(wrongDay)];

    XCTAssertFalse([rule isActiveAtDate:[NSDate date]]);
}

- (void)testRuleWithFutureStartDateIsInactive {
    RTSPScheduleRule *rule = [[RTSPScheduleRule alloc] init];
    rule.enabled = YES;
    rule.startDate = [NSDate dateWithTimeIntervalSinceNow:86400]; // tomorrow

    XCTAssertFalse([rule isActiveAtDate:[NSDate date]]);
}

- (void)testRuleWithPastEndDateIsInactive {
    RTSPScheduleRule *rule = [[RTSPScheduleRule alloc] init];
    rule.enabled = YES;
    rule.endDate = [NSDate dateWithTimeIntervalSinceNow:-86400]; // yesterday

    XCTAssertFalse([rule isActiveAtDate:[NSDate date]]);
}

- (void)testRuleWithTimeRange {
    RTSPScheduleRule *rule = [[RTSPScheduleRule alloc] init];
    rule.enabled = YES;

    NSDateComponents *start = [[NSDateComponents alloc] init];
    start.hour = 0;
    start.minute = 0;
    NSDateComponents *end = [[NSDateComponents alloc] init];
    end.hour = 23;
    end.minute = 59;

    rule.startTime = start;
    rule.endTime = end;

    XCTAssertTrue([rule isActiveAtDate:[NSDate date]]);
}

- (void)testProfileSecureCodingRoundTrip {
    RTSPScheduleProfile *profile = [[RTSPScheduleProfile alloc] init];
    profile.name = @"Night Mode";
    profile.feedURLs = @[@"rtsp://cam1/stream", @"rtsp://cam2/stream"];
    profile.rotationInterval = 30.0;

    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:profile
                                         requiringSecureCoding:YES
                                                         error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(data);

    NSSet *classes = [NSSet setWithArray:@[[RTSPScheduleProfile class], [NSString class], [NSArray class]]];
    RTSPScheduleProfile *decoded = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes
                                                                      fromData:data
                                                                         error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(decoded.name, @"Night Mode");
    XCTAssertEqual(decoded.feedURLs.count, 2);
    XCTAssertEqual(decoded.rotationInterval, 30.0);
}

@end

#pragma mark - RTSPEventLogger Functional Tests

@interface RTSPEventLoggerFunctionalTests : XCTestCase
@property (nonatomic, strong) RTSPEventLogger *logger;
@end

@implementation RTSPEventLoggerFunctionalTests

- (void)setUp {
    [super setUp];
    self.logger = [[RTSPEventLogger alloc] init];
}

- (void)testLogEventAddsToList {
    RTSPEvent *event = [[RTSPEvent alloc] init];
    event.type = RTSPEventTypeFeedSwitch;
    event.title = @"Switched to Camera 2";

    [self.logger logEvent:event];

    XCTAssertEqual([self.logger events].count, 1);
}

- (void)testLogEventDisabledDoesNothing {
    self.logger.loggingEnabled = NO;

    RTSPEvent *event = [[RTSPEvent alloc] init];
    event.type = RTSPEventTypeInfo;
    event.title = @"Should not be logged";

    [self.logger logEvent:event];

    XCTAssertEqual([self.logger events].count, 0);
}

- (void)testEventTypeNames {
    XCTAssertEqualObjects([RTSPEventLogger nameForEventType:RTSPEventTypeFeedSwitch], @"Feed Switch");
    XCTAssertEqualObjects([RTSPEventLogger nameForEventType:RTSPEventTypeSnapshot], @"Snapshot");
    XCTAssertEqualObjects([RTSPEventLogger nameForEventType:RTSPEventTypeMotionDetected], @"Motion Detected");
    XCTAssertEqualObjects([RTSPEventLogger nameForEventType:RTSPEventTypeConnectionFailed], @"Connection Failed");
    XCTAssertEqualObjects([RTSPEventLogger nameForEventType:RTSPEventTypeError], @"Error");
    XCTAssertEqualObjects([RTSPEventLogger nameForEventType:RTSPEventTypeWarning], @"Warning");
    XCTAssertEqualObjects([RTSPEventLogger nameForEventType:RTSPEventTypeInfo], @"Info");
}

- (void)testFilterEventsByType {
    [self.logger logEventType:RTSPEventTypeInfo title:@"Info Event" details:nil feedURL:nil];
    [self.logger logEventType:RTSPEventTypeError title:@"Error Event" details:nil feedURL:nil];
    [self.logger logEventType:RTSPEventTypeInfo title:@"Another Info" details:nil feedURL:nil];

    NSArray *infoEvents = [self.logger eventsWithType:RTSPEventTypeInfo];
    XCTAssertEqual(infoEvents.count, 2);

    NSArray *errorEvents = [self.logger eventsWithType:RTSPEventTypeError];
    XCTAssertEqual(errorEvents.count, 1);
}

- (void)testFilterEventsByFeedURL {
    NSURL *cam1 = [NSURL URLWithString:@"rtsp://cam1/stream"];
    NSURL *cam2 = [NSURL URLWithString:@"rtsp://cam2/stream"];

    [self.logger logEventType:RTSPEventTypeFeedSwitch title:@"Switch 1" details:nil feedURL:cam1];
    [self.logger logEventType:RTSPEventTypeFeedSwitch title:@"Switch 2" details:nil feedURL:cam2];
    [self.logger logEventType:RTSPEventTypeFeedSwitch title:@"Switch 3" details:nil feedURL:cam1];

    NSArray *cam1Events = [self.logger eventsForFeedURL:cam1];
    XCTAssertEqual(cam1Events.count, 2);
}

- (void)testSearchEvents {
    [self.logger logEventType:RTSPEventTypeInfo title:@"Camera Online" details:@"Connected" feedURL:nil];
    [self.logger logEventType:RTSPEventTypeError title:@"Camera Offline" details:@"Timeout" feedURL:nil];

    NSArray *results = [self.logger searchEventsWithQuery:@"camera"];
    XCTAssertEqual(results.count, 2);

    NSArray *onlineResults = [self.logger searchEventsWithQuery:@"online"];
    XCTAssertEqual(onlineResults.count, 1);
}

- (void)testClearAllEvents {
    [self.logger logEventType:RTSPEventTypeInfo title:@"Event 1" details:nil feedURL:nil];
    [self.logger logEventType:RTSPEventTypeInfo title:@"Event 2" details:nil feedURL:nil];

    [self.logger clearAllEvents];

    XCTAssertEqual([self.logger events].count, 0);
}

- (void)testMaxEventsInMemory {
    self.logger.maxEventsInMemory = 5;

    for (int i = 0; i < 10; i++) {
        RTSPEvent *event = [[RTSPEvent alloc] init];
        event.type = RTSPEventTypeInfo;
        event.title = [NSString stringWithFormat:@"Event %d", i];
        [self.logger logEvent:event];
    }

    XCTAssertEqual([self.logger events].count, 5);
}

- (void)testCSVExport {
    [self.logger logEventType:RTSPEventTypeFeedSwitch title:@"Test Event"
                      details:@"Details here" feedURL:nil];

    NSString *tmpPath = [NSTemporaryDirectory()
                         stringByAppendingPathComponent:@"rtsp_test_events.csv"];

    BOOL success = [self.logger exportToCSV:tmpPath];
    XCTAssertTrue(success);

    NSString *content = [NSString stringWithContentsOfFile:tmpPath
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    XCTAssertTrue([content containsString:@"Timestamp,Type,Title"]);
    XCTAssertTrue([content containsString:@"Test Event"]);

    [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
}

- (void)testEventDefaultTimestamp {
    RTSPEvent *event = [[RTSPEvent alloc] init];
    XCTAssertNotNil(event.timestamp);
    XCTAssertNotNil(event.eventID);
}

- (void)testEventSecureCoding {
    XCTAssertTrue([RTSPEvent supportsSecureCoding]);
}

@end

#pragma mark - RTSP URL Security Tests

@interface RTSPURLSecurityAdditionalTests : XCTestCase
@end

@implementation RTSPURLSecurityAdditionalTests

- (void)testRTSPURLWithCredentialsCanBeParsed {
    NSURL *url = [NSURL URLWithString:@"rtsp://user:pass@192.168.1.1/stream"];
    XCTAssertNotNil(url);
    XCTAssertEqualObjects(url.scheme, @"rtsp");
    XCTAssertEqualObjects(url.user, @"user");
    XCTAssertEqualObjects(url.host, @"192.168.1.1");
}

- (void)testRTSPURLWithPortParsing {
    NSURL *url = [NSURL URLWithString:@"rtsp://192.168.1.1:554/stream"];
    XCTAssertNotNil(url);
    XCTAssertEqual(url.port.integerValue, 554);
}

- (void)testRTSPURLWithCustomPortParsing {
    NSURL *url = [NSURL URLWithString:@"rtsp://192.168.1.1:8554/stream"];
    XCTAssertNotNil(url);
    XCTAssertEqual(url.port.integerValue, 8554);
}

- (void)testRTSPSSchemeAccepted {
    NSURL *url = [NSURL URLWithString:@"rtsps://secure.camera.local/stream"];
    XCTAssertNotNil(url);
    XCTAssertEqualObjects(url.scheme, @"rtsps");
}

- (void)testURLInjectionAttemptPrevented {
    // Someone might try to inject a different scheme
    NSString *malicious = @"rtsp://evil.com/stream\nGET /etc/passwd HTTP/1.1";
    NSURL *url = [NSURL URLWithString:malicious];
    // NSURL should fail to parse or not contain injected content
    if (url) {
        XCTAssertNotNil(url.host);
        // The path should not contain the injected command
        XCTAssertFalse([url.path containsString:@"/etc/passwd"]);
    }
}

- (void)testEmptyURLStringReturnsNil {
    NSURL *url = [NSURL URLWithString:@""];
    XCTAssertNil(url);
}

- (void)testNonRTSPSchemeDetectable {
    NSURL *url = [NSURL URLWithString:@"http://not-rtsp.com/stream"];
    XCTAssertNotNil(url);
    XCTAssertNotEqualObjects(url.scheme, @"rtsp");
}

@end

#pragma mark - Performance Tests

@interface RTSPPerformanceTests : XCTestCase
@end

@implementation RTSPPerformanceTests

- (void)testFeedMetadataCreationPerformance {
    [self measureBlock:^{
        for (int i = 0; i < 1000; i++) {
            RTSPFeedMetadata *feed = [[RTSPFeedMetadata alloc]
                initWithURL:[NSString stringWithFormat:@"rtsp://cam%d/stream", i]
                displayName:[NSString stringWithFormat:@"Camera %d", i]];
            (void)feed;
        }
    }];
}

- (void)testEventLoggingPerformance {
    RTSPEventLogger *logger = [[RTSPEventLogger alloc] init];
    logger.maxEventsInMemory = 10000;

    [self measureBlock:^{
        for (int i = 0; i < 1000; i++) {
            [logger logEventType:RTSPEventTypeInfo
                           title:[NSString stringWithFormat:@"Event %d", i]
                         details:nil
                         feedURL:nil];
        }
    }];
}

- (void)testTransitionNameLookupPerformance {
    [self measureBlock:^{
        for (int i = 0; i < 10000; i++) {
            RTSPTransitionType type = (RTSPTransitionType)(i % 12);
            (void)[RTSPTransitionController nameForTransitionType:type];
        }
    }];
}

@end

@interface RTSPFeedConfigFunctionalTests : XCTestCase
@end

@implementation RTSPFeedConfigFunctionalTests

- (void)testFeedConfigProperties {
    RTSPFeedConfig *config = [[RTSPFeedConfig alloc] init];
    config.name = @"Office Camera";
    config.primaryURL = [NSURL URLWithString:@"rtsp://192.168.1.50/stream"];
    config.backupURLs = @[
        [NSURL URLWithString:@"rtsp://192.168.1.51/stream"],
        [NSURL URLWithString:@"rtsp://192.168.1.52/stream"]
    ];

    XCTAssertEqualObjects(config.name, @"Office Camera");
    XCTAssertNotNil(config.primaryURL);
    XCTAssertEqual(config.backupURLs.count, 2);
}

- (void)testFeedConfigStatusTransitions {
    RTSPFeedConfig *config = [[RTSPFeedConfig alloc] init];
    config.status = RTSPFeedStatusUnknown;
    XCTAssertEqual(config.status, RTSPFeedStatusUnknown);

    config.status = RTSPFeedStatusHealthy;
    XCTAssertEqual(config.status, RTSPFeedStatusHealthy);

    config.status = RTSPFeedStatusFailed;
    XCTAssertEqual(config.status, RTSPFeedStatusFailed);

    config.status = RTSPFeedStatusFailedOver;
    XCTAssertEqual(config.status, RTSPFeedStatusFailedOver);
}

@end
