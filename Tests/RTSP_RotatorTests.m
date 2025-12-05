//
//  RTSP_RotatorTests.m
//  RTSP Rotator Tests
//
//  Created by Jordan Koch on 10/29/25.
//

#import <XCTest/XCTest.h>

// Import the classes we want to test
// Note: These interfaces are duplicated here for testing purposes
// In a production app, these would be in separate header files

@interface RTSPWallpaperWindow : NSWindow
@end

@interface RTSPWallpaperController : NSObject
@property (nonatomic, strong) NSArray<NSString *> *feeds;
@property (nonatomic, assign) NSUInteger currentIndex;
@property (nonatomic, assign) BOOL isMuted;
@property (nonatomic, assign) NSTimeInterval rotationInterval;
- (instancetype)initWithFeeds:(NSArray<NSString *> *)feeds rotationInterval:(NSTimeInterval)interval;
- (void)start;
- (void)stop;
- (void)toggleMute;
@end

// Test-only interface for accessing private methods
@interface RTSPWallpaperController (Testing)
- (void)nextFeed;
@end

@interface RTSP_RotatorTests : XCTestCase
@end

@implementation RTSP_RotatorTests

#pragma mark - Setup and Teardown

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - RTSPWallpaperController Tests

- (void)testControllerInitializationWithValidFeeds {
    // Given
    NSArray<NSString *> *feeds = @[
        @"rtsp://test1.example.com/stream",
        @"rtsp://test2.example.com/stream",
        @"rtsp://test3.example.com/stream"
    ];
    NSTimeInterval interval = 30.0;

    // When
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:feeds
                                                                         rotationInterval:interval];

    // Then
    XCTAssertNotNil(controller, @"Controller should be initialized");
    XCTAssertEqual(controller.feeds.count, 3, @"Should have 3 feeds");
    XCTAssertEqual(controller.currentIndex, 0, @"Should start at index 0");
    XCTAssertTrue(controller.isMuted, @"Should be muted by default");
    XCTAssertEqual(controller.rotationInterval, 30.0, @"Should use provided rotation interval");
}

- (void)testControllerInitializationWithNilFeeds {
    // When
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:nil
                                                                         rotationInterval:60.0];

    // Then
    XCTAssertNotNil(controller, @"Controller should be initialized even with nil feeds");
    XCTAssertGreaterThan(controller.feeds.count, 0, @"Should have default feeds");
    XCTAssertEqual(controller.currentIndex, 0, @"Should start at index 0");
}

- (void)testControllerInitializationWithEmptyFeeds {
    // Given
    NSArray<NSString *> *emptyFeeds = @[];

    // When
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:emptyFeeds
                                                                         rotationInterval:60.0];

    // Then
    XCTAssertNotNil(controller, @"Controller should be initialized even with empty feeds");
    XCTAssertGreaterThan(controller.feeds.count, 0, @"Should fall back to default feeds");
}

- (void)testControllerDefaultInitialization {
    // When
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] init];

    // Then
    XCTAssertNotNil(controller, @"Controller should be initialized with default init");
    XCTAssertGreaterThan(controller.feeds.count, 0, @"Should have default feeds");
    XCTAssertEqual(controller.rotationInterval, 60.0, @"Should use default rotation interval of 60 seconds");
}

- (void)testRotationIntervalValidation {
    // Given
    NSArray<NSString *> *feeds = @[@"rtsp://test.example.com/stream"];

    // When - negative interval
    RTSPWallpaperController *controller1 = [[RTSPWallpaperController alloc] initWithFeeds:feeds
                                                                          rotationInterval:-10.0];

    // Then
    XCTAssertEqual(controller1.rotationInterval, 60.0, @"Should default to 60 seconds for negative interval");

    // When - zero interval
    RTSPWallpaperController *controller2 = [[RTSPWallpaperController alloc] initWithFeeds:feeds
                                                                          rotationInterval:0.0];

    // Then
    XCTAssertEqual(controller2.rotationInterval, 60.0, @"Should default to 60 seconds for zero interval");

    // When - valid interval
    RTSPWallpaperController *controller3 = [[RTSPWallpaperController alloc] initWithFeeds:feeds
                                                                          rotationInterval:45.0];

    // Then
    XCTAssertEqual(controller3.rotationInterval, 45.0, @"Should use valid interval");
}

- (void)testMuteToggle {
    // Given
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] init];
    BOOL initialMuteState = controller.isMuted;

    // When
    [controller toggleMute];

    // Then (need to wait for main queue dispatch)
    XCTestExpectation *expectation = [self expectationWithDescription:@"Mute toggle"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertNotEqual(controller.isMuted, initialMuteState, @"Mute state should be toggled");
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testNextFeedRotation {
    // Given
    NSArray<NSString *> *feeds = @[
        @"rtsp://feed1.example.com/stream",
        @"rtsp://feed2.example.com/stream",
        @"rtsp://feed3.example.com/stream"
    ];
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:feeds
                                                                         rotationInterval:60.0];

    // When - First rotation
    XCTAssertEqual(controller.currentIndex, 0, @"Should start at index 0");
    [controller nextFeed];

    // Then
    XCTAssertEqual(controller.currentIndex, 1, @"Should move to index 1");

    // When - Second rotation
    [controller nextFeed];

    // Then
    XCTAssertEqual(controller.currentIndex, 2, @"Should move to index 2");

    // When - Wrap around
    [controller nextFeed];

    // Then
    XCTAssertEqual(controller.currentIndex, 0, @"Should wrap around to index 0");
}

- (void)testFeedRotationWithSingleFeed {
    // Given
    NSArray<NSString *> *feeds = @[@"rtsp://single.example.com/stream"];
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:feeds
                                                                         rotationInterval:60.0];

    // When
    [controller nextFeed];

    // Then
    XCTAssertEqual(controller.currentIndex, 0, @"Should stay at index 0 with single feed");
}

- (void)testFeedArrayImmutability {
    // Given
    NSMutableArray<NSString *> *mutableFeeds = [@[
        @"rtsp://feed1.example.com/stream",
        @"rtsp://feed2.example.com/stream"
    ] mutableCopy];

    // When
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:mutableFeeds
                                                                         rotationInterval:60.0];
    [mutableFeeds addObject:@"rtsp://feed3.example.com/stream"];

    // Then
    XCTAssertEqual(controller.feeds.count, 2, @"Controller feeds should not be affected by external changes");
}

#pragma mark - Configuration File Loading Tests

// Note: These would test the loadFeedsFromFile function
// Since it's a C function in the main file, we'll create a test version

NSArray<NSString *> *testLoadFeedsFromString(NSString *content) {
    NSArray<NSString *> *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray<NSString *> *feeds = [NSMutableArray array];

    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0 && ![trimmed hasPrefix:@"#"]) {
            [feeds addObject:trimmed];
        }
    }

    return [feeds copy];
}

- (void)testLoadFeedsFromStringWithValidContent {
    // Given
    NSString *content = @"rtsp://feed1.example.com/stream\nrtsp://feed2.example.com/stream\nrtsp://feed3.example.com/stream";

    // When
    NSArray<NSString *> *feeds = testLoadFeedsFromString(content);

    // Then
    XCTAssertEqual(feeds.count, 3, @"Should load 3 feeds");
    XCTAssertEqualObjects(feeds[0], @"rtsp://feed1.example.com/stream");
    XCTAssertEqualObjects(feeds[1], @"rtsp://feed2.example.com/stream");
    XCTAssertEqualObjects(feeds[2], @"rtsp://feed3.example.com/stream");
}

- (void)testLoadFeedsIgnoresComments {
    // Given
    NSString *content = @"# This is a comment\nrtsp://feed1.example.com/stream\n# Another comment\nrtsp://feed2.example.com/stream";

    // When
    NSArray<NSString *> *feeds = testLoadFeedsFromString(content);

    // Then
    XCTAssertEqual(feeds.count, 2, @"Should load only non-comment lines");
    XCTAssertEqualObjects(feeds[0], @"rtsp://feed1.example.com/stream");
    XCTAssertEqualObjects(feeds[1], @"rtsp://feed2.example.com/stream");
}

- (void)testLoadFeedsIgnoresEmptyLines {
    // Given
    NSString *content = @"rtsp://feed1.example.com/stream\n\n\nrtsp://feed2.example.com/stream\n\n";

    // When
    NSArray<NSString *> *feeds = testLoadFeedsFromString(content);

    // Then
    XCTAssertEqual(feeds.count, 2, @"Should ignore empty lines");
}

- (void)testLoadFeedsTrimsWhitespace {
    // Given
    NSString *content = @"  rtsp://feed1.example.com/stream  \n\t\trtsp://feed2.example.com/stream\t\t";

    // When
    NSArray<NSString *> *feeds = testLoadFeedsFromString(content);

    // Then
    XCTAssertEqual(feeds.count, 2, @"Should load 2 feeds");
    XCTAssertEqualObjects(feeds[0], @"rtsp://feed1.example.com/stream", @"Should trim leading/trailing whitespace");
    XCTAssertEqualObjects(feeds[1], @"rtsp://feed2.example.com/stream", @"Should trim leading/trailing whitespace");
}

- (void)testLoadFeedsFromEmptyString {
    // Given
    NSString *content = @"";

    // When
    NSArray<NSString *> *feeds = testLoadFeedsFromString(content);

    // Then
    XCTAssertEqual(feeds.count, 0, @"Should return empty array for empty content");
}

- (void)testLoadFeedsWithMixedContent {
    // Given
    NSString *content = @"# Configuration file\n\nrtsp://camera1.local/stream\n# Office camera\nrtsp://camera2.local/stream\n\n\n# End of file";

    // When
    NSArray<NSString *> *feeds = testLoadFeedsFromString(content);

    // Then
    XCTAssertEqual(feeds.count, 2, @"Should load only valid feed URLs");
}

#pragma mark - RTSP URL Validation Tests

- (void)testValidRTSPURLs {
    // Given
    NSArray<NSString *> *validURLs = @[
        @"rtsp://192.168.1.100:554/stream",
        @"rtsp://camera.local/live",
        @"rtsp://admin:password@192.168.1.100:554/stream",
        @"rtsp://example.com:8554/camera/stream.sdp"
    ];

    // When/Then
    for (NSString *urlString in validURLs) {
        NSURL *url = [NSURL URLWithString:urlString];
        XCTAssertNotNil(url, @"Should parse valid RTSP URL: %@", urlString);
        XCTAssertEqualObjects(url.scheme, @"rtsp", @"Scheme should be rtsp");
    }
}

- (void)testInvalidRTSPURLs {
    // Given
    NSArray<NSString *> *invalidURLs = @[
        @"not a url",
        @"http://wrong.scheme.com",
        @"",
        @"rtsp://",
    ];

    // When/Then
    for (NSString *urlString in invalidURLs) {
        NSURL *url = [NSURL URLWithString:urlString];
        if (url) {
            XCTAssertNotEqualObjects(url.scheme, @"rtsp", @"Should not accept non-RTSP URL: %@", urlString);
        }
    }
}

#pragma mark - RTSPWallpaperWindow Tests

- (void)testWindowCanBecomeKeyAndMain {
    // Given/When
    RTSPWallpaperWindow *window = [[RTSPWallpaperWindow alloc] initWithContentRect:NSMakeRect(0, 0, 100, 100)
                                                                          styleMask:NSWindowStyleMaskBorderless
                                                                            backing:NSBackingStoreBuffered
                                                                              defer:NO];

    // Then
    XCTAssertNotNil(window, @"Window should be created");
    XCTAssertTrue([window canBecomeKeyWindow], @"Window should be able to become key window");
    XCTAssertTrue([window canBecomeMainWindow], @"Window should be able to become main window");
}

#pragma mark - Performance Tests

- (void)testFeedRotationPerformance {
    // Given
    NSArray<NSString *> *feeds = @[
        @"rtsp://feed1.example.com/stream",
        @"rtsp://feed2.example.com/stream",
        @"rtsp://feed3.example.com/stream",
        @"rtsp://feed4.example.com/stream",
        @"rtsp://feed5.example.com/stream"
    ];
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:feeds
                                                                         rotationInterval:60.0];

    // When/Then
    [self measureBlock:^{
        for (int i = 0; i < 1000; i++) {
            [controller nextFeed];
        }
    }];
}

- (void)testFeedLoadingPerformance {
    // Given
    NSMutableString *content = [NSMutableString string];
    for (int i = 0; i < 100; i++) {
        [content appendFormat:@"rtsp://camera%d.example.com/stream\n", i];
    }

    // When/Then
    [self measureBlock:^{
        NSArray<NSString *> *feeds = testLoadFeedsFromString(content);
        XCTAssertEqual(feeds.count, 100);
    }];
}

@end
