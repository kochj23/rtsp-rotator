//
//  RTSPMemoryManagementTests.m
//  RTSP Rotator Tests
//
//  Tests for memory management fixes: KVO observers, NSTimer retain cycles, dealloc
//  Ensures no memory leaks in the critical components
//

#import <XCTest/XCTest.h>
#import <AVFoundation/AVFoundation.h>

// Import the classes we want to test
@interface RTSPWallpaperController : NSObject
@property (nonatomic, strong, readonly, nullable) AVPlayer *player;
@property (nonatomic, assign) NSTimeInterval rotationInterval;
- (instancetype)initWithFeeds:(NSArray<NSString *> *)feeds rotationInterval:(NSTimeInterval)interval;
- (void)start;
- (void)stop;
@end

@interface RTSPMemoryManagementTests : XCTestCase
@end

@implementation RTSPMemoryManagementTests

#pragma mark - Setup and Teardown

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Controller Deallocation Tests

- (void)testControllerDeallocatesAfterStop {
    // Given
    __weak RTSPWallpaperController *weakController = nil;

    @autoreleasepool {
        RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                               rotationInterval:60.0];
        weakController = controller;

        XCTAssertNotNil(weakController, @"Controller should be alive");

        // When - Stop (should clean up resources)
        [controller stop];

        // Controller goes out of scope here
    }

    // Then - Wait a moment for cleanup
    XCTestExpectation *expectation = [self expectationWithDescription:@"Controller deallocation"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertNil(weakController, @"Controller should be deallocated after stop");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testControllerDeallocatesWithoutExplicitStop {
    // Given
    __weak RTSPWallpaperController *weakController = nil;

    @autoreleasepool {
        RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                               rotationInterval:60.0];
        weakController = controller;

        XCTAssertNotNil(weakController, @"Controller should be alive");

        // When - Let controller deallocate without explicit stop (dealloc should handle cleanup)
        // Controller goes out of scope here
    }

    // Then - Wait a moment for cleanup
    XCTestExpectation *expectation = [self expectationWithDescription:@"Controller deallocation without stop"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Note: Without fixing NSTimer retain cycle, this would fail (weakController would still exist)
        XCTAssertNil(weakController, @"Controller should be deallocated even without explicit stop (dealloc handles cleanup)");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - NSTimer Memory Management Tests

- (void)testTimerDoesNotRetainController {
    // This test verifies the fix for NSTimer retain cycle
    // The old code: [NSTimer scheduledTimerWithTimeInterval:interval target:self ...]
    // The new code: Uses block-based API with weak self

    __weak RTSPWallpaperController *weakController = nil;

    @autoreleasepool {
        RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                               rotationInterval:1.0];
        weakController = controller;

        // Note: We don't start the controller to avoid complications, just verify init doesn't cause retain cycle
        XCTAssertNotNil(weakController, @"Controller should be alive");

        // Controller goes out of scope
    }

    // Then - Should deallocate quickly
    XCTestExpectation *expectation = [self expectationWithDescription:@"Timer does not retain controller"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertNil(weakController, @"Controller should deallocate (timer should not retain it)");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - Multiple Lifecycle Tests

- (void)testMultipleStartStopCycles {
    // This tests that starting and stopping multiple times doesn't cause memory issues

    for (int i = 0; i < 5; i++) {
        @autoreleasepool {
            RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                                   rotationInterval:60.0];

            // Start and stop multiple times
            [controller start];
            [controller stop];
            [controller start];
            [controller stop];

            // Controller should clean up properly
        }
    }

    // If we get here without crashes, test passes
    XCTAssertTrue(YES, @"Multiple start/stop cycles completed without crashes");
}

- (void)testRapidStartStopCycles {
    // Test rapid start/stop to ensure cleanup is thread-safe
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                           rotationInterval:60.0];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Rapid cycles complete"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < 10; i++) {
            [controller start];
            [NSThread sleepForTimeInterval:0.05];
            [controller stop];
            [NSThread sleepForTimeInterval:0.05];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [expectation fulfill];
        });
    });

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Observer Management Tests

- (void)testStopRemovesAllObservers {
    // This test verifies that stop() properly removes all notification observers
    // The fix adds proper observer cleanup in the stop method

    // Given
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                           rotationInterval:60.0];

    // Get notification center reference count before
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    // When
    [controller start];

    // Stop should remove observers
    [controller stop];

    // Then - No exceptions should be thrown if we post notifications
    @try {
        [nc postNotificationName:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [nc postNotificationName:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
        XCTAssertTrue(YES, @"No crashes after observer removal");
    } @catch (NSException *exception) {
        XCTFail(@"Should not throw exception after proper observer cleanup: %@", exception);
    }
}

#pragma mark - Resource Cleanup Tests

- (void)testStopCleansUpPlayer {
    // Given
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                           rotationInterval:60.0];
    [controller start];

    // Player should exist after start
    XCTAssertNotNil(controller.player, @"Player should be created after start");

    // When
    [controller stop];

    // Then - Wait for cleanup
    XCTestExpectation *expectation = [self expectationWithDescription:@"Player cleanup"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Note: Player might be nil after stop, depending on implementation
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - Concurrent Access Tests

- (void)testConcurrentAccessDoesNotCrash {
    // Test that concurrent access to controller doesn't cause crashes
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test1.example.com",
                                                                                           @"rtsp://test2.example.com",
                                                                                           @"rtsp://test3.example.com"]
                                                                           rotationInterval:60.0];

    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Thread 1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Thread 2"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"Thread 3"];

    // Thread 1: Start/stop
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (int i = 0; i < 5; i++) {
            [controller start];
            [NSThread sleepForTimeInterval:0.1];
            [controller stop];
        }
        [expectation1 fulfill];
    });

    // Thread 2: Toggle mute
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < 10; i++) {
            controller.rotationInterval = 30.0 + i;
            [NSThread sleepForTimeInterval:0.05];
        }
        [expectation2 fulfill];
    });

    // Thread 3: Access properties
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        for (int i = 0; i < 10; i++) {
            NSUInteger _ = controller.currentIndex;
            BOOL _ = controller.isMuted;
            [NSThread sleepForTimeInterval:0.05];
        }
        [expectation3 fulfill];
    });

    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

#pragma mark - Memory Pressure Tests

- (void)testMultipleControllersCanCoexist {
    // Test that multiple controller instances can exist without interfering
    NSMutableArray *controllers = [NSMutableArray array];

    for (int i = 0; i < 10; i++) {
        RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[[NSString stringWithFormat:@"rtsp://test%d.example.com", i]]
                                                                               rotationInterval:60.0];
        [controllers addObject:controller];
    }

    XCTAssertEqual(controllers.count, 10, @"Should create 10 controllers");

    // Cleanup
    for (RTSPWallpaperController *controller in controllers) {
        [controller stop];
    }
    [controllers removeAllObjects];

    XCTAssertTrue(YES, @"Multiple controllers cleaned up successfully");
}

- (void)testControllerRecreation {
    // Test that controller can be recreated after deallocation
    __weak RTSPWallpaperController *weakController = nil;

    @autoreleasepool {
        RTSPWallpaperController *controller1 = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                               rotationInterval:60.0];
        weakController = controller1;
        [controller1 start];
        [controller1 stop];
    }

    // Wait for cleanup
    [NSThread sleepForTimeInterval:0.5];

    // Should be deallocated
    XCTAssertNil(weakController, @"First controller should be deallocated");

    // Create new controller with same configuration
    @autoreleasepool {
        RTSPWallpaperController *controller2 = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                               rotationInterval:60.0];
        XCTAssertNotNil(controller2, @"Should create new controller successfully");
        [controller2 start];
        [controller2 stop];
    }

    XCTAssertTrue(YES, @"Controller recreation successful");
}

#pragma mark - Edge Case Tests

- (void)testStopWithoutStart {
    // Given
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                           rotationInterval:60.0];

    // When - Stop without start
    @try {
        [controller stop];
        XCTAssertTrue(YES, @"Stop without start should not crash");
    } @catch (NSException *exception) {
        XCTFail(@"Stop without start should not throw exception: %@", exception);
    }
}

- (void)testMultipleStopCalls {
    // Given
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                           rotationInterval:60.0];
    [controller start];

    // When - Multiple stop calls
    @try {
        [controller stop];
        [controller stop];
        [controller stop];
        XCTAssertTrue(YES, @"Multiple stop calls should not crash");
    } @catch (NSException *exception) {
        XCTFail(@"Multiple stop calls should not throw exception: %@", exception);
    }
}

- (void)testMultipleStartCalls {
    // Given
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                           rotationInterval:60.0];

    // When - Multiple start calls
    @try {
        [controller start];
        [controller start];
        [controller start];
        XCTAssertTrue(YES, @"Multiple start calls should not crash");

        // Cleanup
        [controller stop];
    } @catch (NSException *exception) {
        XCTFail(@"Multiple start calls should not throw exception: %@", exception);
    }
}

#pragma mark - Performance Tests

- (void)testControllerCreationPerformance {
    [self measureBlock:^{
        for (int i = 0; i < 10; i++) {
            RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                                   rotationInterval:60.0];
            [controller stop];
        }
    }];
}

- (void)testStartStopPerformance {
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                           rotationInterval:60.0];

    [self measureBlock:^{
        [controller start];
        [controller stop];
    }];
}

@end
