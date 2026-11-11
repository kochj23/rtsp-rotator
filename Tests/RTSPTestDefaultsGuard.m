//
//  RTSPTestDefaultsGuard.m
//  Tests
//
//  The tests run inside the app (TEST_HOST), so anything they save lands in the app's real
//  preferences domain. This guard snapshots that domain before the first test and puts it back
//  when the bundle finishes. The snapshot is also kept in a temporary file, so a host process
//  that crashes mid-run is restored by the next one (or by the next run).
//

#import <XCTest/XCTest.h>

@interface RTSPTestDefaultsGuard : NSObject <XCTestObservation>
@property (nonatomic, copy) NSDictionary *saved;
@property (nonatomic, copy) NSString *domain;
@property (nonatomic, copy) NSString *backupPath;
@end

@implementation RTSPTestDefaultsGuard

+ (void)load {
    static RTSPTestDefaultsGuard *guard;
    guard = [[RTSPTestDefaultsGuard alloc] init];
    guard.domain = NSBundle.mainBundle.bundleIdentifier ?: @"unknown";
    guard.backupPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                        [NSString stringWithFormat:@"%@.defaults-before-tests.plist", guard.domain]];

    NSDictionary *backup = [NSDictionary dictionaryWithContentsOfFile:guard.backupPath];
    if (backup) {
        // A previous host process died before restoring: that file is the real state.
        guard.saved = backup;
    } else {
        guard.saved = [[NSUserDefaults standardUserDefaults] persistentDomainForName:guard.domain] ?: @{};
        [guard.saved writeToFile:guard.backupPath atomically:YES];
    }
    [[XCTestObservationCenter sharedTestObservationCenter] addTestObserver:guard];
}

- (void)testBundleDidFinish:(NSBundle *)testBundle {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (self.saved.count > 0) {
        [defaults setPersistentDomain:self.saved forName:self.domain];
    } else {
        [defaults removePersistentDomainForName:self.domain];
    }
    [defaults synchronize];
    [[NSFileManager defaultManager] removeItemAtPath:self.backupPath error:nil];
}

@end
