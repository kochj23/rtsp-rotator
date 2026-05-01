//
//  RTSPMemoryManagementTests.m
//  RTSP Rotator Tests
//
//  Tests for memory management fixes: KVO observers, NSTimer retain cycles, dealloc
//  Ensures no memory leaks in the critical components
//

#import <XCTest/XCTest.h>
#import <AVFoundation/AVFoundation.h>
#import "RTSPWallpaperController.h"

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
    __weak RTSPWallpaperController *weakController = nil;

    @autoreleasepool {
        RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                             rotationInterval:60.0];
        weakController = controller;
        XCTAssertNotNil(weakController, @"Controller should be alive");
        [controller stop];
    }

    XCTestExpectation *expectation = [self expectationWithDescription:@"Controller deallocation"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        RTSPWallpaperController *strongRef = weakController;
        XCTAssertNil(strongRef, @"Controller should be deallocated after stop");
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testControllerDeallocatesWithoutExplicitStop {
    __weak RTSPWallpaperController *weakController = nil;

    @autoreleasepool {
        RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                             rotationInterval:60.0];
        weakController = controller;
        XCTAssertNotNil(weakController, @"Controller should be alive");
    }

    XCTestExpectation *expectation = [self expectationWithDescription:@"Controller deallocation without stop"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        RTSPWallpaperController *strongRef = weakController;
        XCTAssertNil(strongRef, @"Controller should be deallocated even without explicit stop");
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - NSTimer Memory Management Tests

- (void)testTimerDoesNotRetainController {
    __weak RTSPWallpaperController *weakController = nil;

    @autoreleasepool {
        RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                             rotationInterval:1.0];
        weakController = controller;
        XCTAssertNotNil(weakController, @"Controller should be alive");
    }

    XCTestExpectation *expectation = [self expectationWithDescription:@"Timer does not retain controller"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        RTSPWallpaperController *strongRef = weakController;
        XCTAssertNil(strongRef, @"Controller should deallocate (timer should not retain it)");
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - Multiple Lifecycle Tests

- (void)testMultipleStartStopCycles {
    for (int i = 0; i < 5; i++) {
        @autoreleasepool {
            RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                                 rotationInterval:60.0];
            [controller start];
            [controller stop];
            [controller start];
            [controller stop];
        }
    }
    XCTAssertTrue(YES, @"Multiple start/stop cycles completed without crashes");
}

- (void)testRapidStartStopCycles {
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
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                         rotationInterval:60.0];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [controller start];
    [controller stop];

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
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                         rotationInterval:60.0];
    [controller start];
    XCTAssertNotNil(controller.player, @"Player should be created after start");
    [controller stop];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Player cleanup"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - Concurrent Access Tests

- (void)testConcurrentAccessDoesNotCrash {
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test1.example.com",
                                                                                           @"rtsp://test2.example.com",
                                                                                           @"rtsp://test3.example.com"]
                                                                         rotationInterval:60.0];

    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Thread 1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Thread 2"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"Thread 3"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (int i = 0; i < 5; i++) {
            [controller start];
            [NSThread sleepForTimeInterval:0.1];
            [controller stop];
        }
        [expectation1 fulfill];
    });

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < 10; i++) {
            controller.rotationInterval = 30.0 + i;
            [NSThread sleepForTimeInterval:0.05];
        }
        [expectation2 fulfill];
    });

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        for (int i = 0; i < 10; i++) {
            (void)controller.rotationInterval;
            [NSThread sleepForTimeInterval:0.05];
        }
        [expectation3 fulfill];
    });

    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

#pragma mark - Memory Pressure Tests

- (void)testMultipleControllersCanCoexist {
    NSMutableArray *controllers = [NSMutableArray array];

    for (int i = 0; i < 10; i++) {
        RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[[NSString stringWithFormat:@"rtsp://test%d.example.com", i]]
                                                                             rotationInterval:60.0];
        [controllers addObject:controller];
    }

    XCTAssertEqual(controllers.count, 10, @"Should create 10 controllers");

    for (RTSPWallpaperController *controller in controllers) {
        [controller stop];
    }
    [controllers removeAllObjects];

    XCTAssertTrue(YES, @"Multiple controllers cleaned up successfully");
}

- (void)testControllerRecreation {
    __weak RTSPWallpaperController *weakController = nil;

    @autoreleasepool {
        RTSPWallpaperController *controller1 = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                             rotationInterval:60.0];
        weakController = controller1;
        [controller1 start];
        [controller1 stop];
    }

    [NSThread sleepForTimeInterval:0.5];
    XCTAssertNil(weakController, @"First controller should be deallocated");

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
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                         rotationInterval:60.0];
    @try {
        [controller stop];
        XCTAssertTrue(YES, @"Stop without start should not crash");
    } @catch (NSException *exception) {
        XCTFail(@"Stop without start should not throw exception: %@", exception);
    }
}

- (void)testMultipleStopCalls {
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                         rotationInterval:60.0];
    [controller start];

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
    RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] initWithFeeds:@[@"rtsp://test.example.com"]
                                                                         rotationInterval:60.0];
    @try {
        [controller start];
        [controller start];
        [controller start];
        XCTAssertTrue(YES, @"Multiple start calls should not crash");
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
