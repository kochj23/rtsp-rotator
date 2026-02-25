//
//  RTSPMLXPythonSettings.m
//  RTSP Rotator
//
//  Python MLX toolkit configuration and health check
//

#import "RTSPMLXPythonSettings.h"
#import <AppKit/AppKit.h>

static NSString * const kRTSPPythonPathKey = @"RTSPPythonPath";
static NSString * const kRTSPMLXPathKey = @"RTSPMLXPath";
static NSString * const kRTSPAutoCheckKey = @"RTSPAutoCheckMLX";

@interface RTSPMLXPythonSettings ()

@property (nonatomic, assign, readwrite) RTSPPythonMLXStatus status;
@property (nonatomic, copy, readwrite) NSString *mlxVersion;
@property (nonatomic, copy, readwrite) NSString *pythonVersion;
@property (nonatomic, strong, readwrite) NSDate *lastCheckTime;

@end

@implementation RTSPMLXPythonSettings

+ (instancetype)sharedSettings {
    static RTSPMLXPythonSettings *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RTSPMLXPythonSettings alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _status = RTSPPythonMLXStatusUnknown;
        _pythonPath = @"/usr/local/bin/python3"; // Default
        _autoCheckOnLaunch = YES;

        [self loadSettings];

        if (_autoCheckOnLaunch) {
            [self checkMLXAvailability:nil];
        }

        NSLog(@"[MLXPython] Initialized with Python path: %@", _pythonPath);
    }
    return self;
}

- (void)checkMLXAvailability:(void (^)(RTSPPythonMLXStatus, NSError * _Nullable))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        RTSPPythonMLXStatus newStatus = [self checkMLXAvailabilitySync];

        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(mlxPythonSettings:didUpdateStatus:)]) {
                [self.delegate mlxPythonSettings:self didUpdateStatus:newStatus];
            }

            if (completion) {
                completion(newStatus, nil);
            }
        });
    });
}

- (RTSPPythonMLXStatus)checkMLXAvailabilitySync {
    self.lastCheckTime = [NSDate date];

    // Step 1: Check if Python exists
    if (![self checkPythonExists]) {
        self.status = RTSPPythonMLXStatusNotFound;
        NSLog(@"[MLXPython] ❌ Python not found at: %@", self.pythonPath);
        return self.status;
    }

    NSLog(@"[MLXPython] ✓ Python found: %@", self.pythonPath);

    // Step 2: Get Python version
    self.pythonVersion = [self getPythonVersion];
    NSLog(@"[MLXPython] Python version: %@", self.pythonVersion ?: @"Unknown");

    // Step 3: Check if MLX is installed
    if (![self checkMLXInstalled]) {
        self.status = RTSPPythonMLXStatusMLXMissing;
        NSLog(@"[MLXPython] ⚠️  MLX toolkit not installed");
        return self.status;
    }

    // Step 4: Get MLX version
    self.mlxVersion = [self getMLXVersion];
    NSLog(@"[MLXPython] ✓ MLX version: %@", self.mlxVersion ?: @"Unknown");

    // Step 5: Test MLX import
    if ([self testMLXImport]) {
        self.status = RTSPPythonMLXStatusAvailable;
        NSLog(@"[MLXPython] ✅ MLX toolkit is working!");

        if ([self.delegate respondsToSelector:@selector(mlxPythonSettings:didDetectMLXVersion:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate mlxPythonSettings:self didDetectMLXVersion:self.mlxVersion];
            });
        }
    } else {
        self.status = RTSPPythonMLXStatusError;
        NSLog(@"[MLXPython] ❌ MLX import test failed");
    }

    return self.status;
}

- (BOOL)checkPythonExists {
    return [[NSFileManager defaultManager] fileExistsAtPath:self.pythonPath];
}

- (NSString *)getPythonVersion {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = self.pythonPath;
    task.arguments = @[@"--version"];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    @try {
        [task launch];
        [task waitUntilExit];

        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        return [output stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } @catch (NSException *exception) {
        NSLog(@"[MLXPython] Exception getting Python version: %@", exception);
        return nil;
    }
}

- (BOOL)checkMLXInstalled {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = self.pythonPath;
    task.arguments = @[@"-c", @"import mlx.core"];

    NSPipe *pipe = [NSPipe pipe];
    task.standardError = pipe;

    @try {
        [task launch];
        [task waitUntilExit];

        return task.terminationStatus == 0;
    } @catch (NSException *exception) {
        return NO;
    }
}

- (NSString *)getMLXVersion {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = self.pythonPath;
    task.arguments = @[@"-c", @"import mlx.core; print(mlx.core.__version__)"];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    @try {
        [task launch];
        [task waitUntilExit];

        if (task.terminationStatus != 0) return nil;

        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        return [output stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } @catch (NSException *exception) {
        return nil;
    }
}

- (BOOL)testMLXImport {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = self.pythonPath;
    task.arguments = @[@"-c", @"import mlx.core as mx; import mlx.nn as nn; print('OK')"];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    @try {
        [task launch];
        [task waitUntilExit];

        if (task.terminationStatus != 0) return NO;

        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        return [output containsString:@"OK"];
    } @catch (NSException *exception) {
        return NO;
    }
}

- (NSString *)statusMessage {
    switch (self.status) {
        case RTSPPythonMLXStatusUnknown:
            return @"Not checked yet";

        case RTSPPythonMLXStatusAvailable:
            if (self.mlxVersion) {
                return [NSString stringWithFormat:@"MLX v%@ ready", self.mlxVersion];
            }
            return @"MLX toolkit available";

        case RTSPPythonMLXStatusNotFound:
            return @"Python not found";

        case RTSPPythonMLXStatusMLXMissing:
            return @"MLX toolkit not installed";

        case RTSPPythonMLXStatusError:
            return @"MLX error - check configuration";
    }
}

- (NSColor *)statusColor {
    switch (self.status) {
        case RTSPPythonMLXStatusUnknown:
            return [NSColor grayColor];

        case RTSPPythonMLXStatusAvailable:
            return [NSColor systemGreenColor];

        case RTSPPythonMLXStatusNotFound:
        case RTSPPythonMLXStatusError:
            return [NSColor systemRedColor];

        case RTSPPythonMLXStatusMLXMissing:
            return [NSColor systemYellowColor];
    }
}

- (void)resetToDefaultPythonPath {
    // Try to find Python in common locations
    NSArray *commonPaths = @[
        @"/usr/local/bin/python3",
        @"/opt/homebrew/bin/python3",
        @"/usr/bin/python3",
        @"/Library/Frameworks/Python.framework/Versions/Current/bin/python3",
        @"/opt/anaconda3/bin/python",
        @"/opt/miniconda3/bin/python",
        [NSHomeDirectory() stringByAppendingPathComponent:@".pyenv/shims/python"],
        @"/usr/local/anaconda3/bin/python"
    ];

    for (NSString *path in commonPaths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            self.pythonPath = path;
            NSLog(@"[MLXPython] Found Python at: %@", path);
            [self saveSettings];
            return;
        }
    }

    // Default fallback
    self.pythonPath = @"/usr/local/bin/python3";
    [self saveSettings];
}

- (void)autoDetect:(void (^)(BOOL))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"[MLXPython] Auto-detecting Python and MLX...");

        // Try to find Python
        NSArray *commonPaths = @[
            @"/opt/homebrew/bin/python3",
            @"/usr/local/bin/python3",
            @"/usr/bin/python3",
            @"/Library/Frameworks/Python.framework/Versions/Current/bin/python3",
            @"/opt/anaconda3/bin/python",
            @"/opt/miniconda3/bin/python"
        ];

        BOOL found = NO;

        for (NSString *path in commonPaths) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:path]) continue;

            self.pythonPath = path;

            // Check if this Python has MLX
            RTSPPythonMLXStatus testStatus = [self checkMLXAvailabilitySync];

            if (testStatus == RTSPPythonMLXStatusAvailable) {
                found = YES;
                NSLog(@"[MLXPython] ✅ Auto-detected working configuration");
                NSLog(@"[MLXPython]    Python: %@", path);
                NSLog(@"[MLXPython]    MLX: %@", self.mlxVersion);
                [self saveSettings];
                break;
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(found);
        });
    });
}

- (void)installMLXToolkit:(void (^)(BOOL, NSString * _Nullable, NSError * _Nullable))completion {
    if (![self checkPythonExists]) {
        NSError *error = [NSError errorWithDomain:@"RTSPMLXPython"
                                            code:404
                                        userInfo:@{NSLocalizedDescriptionKey: @"Python not found"}];
        if (completion) completion(NO, nil, error);
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"[MLXPython] Installing MLX toolkit...");

        NSTask *task = [[NSTask alloc] init];
        task.launchPath = self.pythonPath;
        task.arguments = @[@"-m", @"pip", @"install", @"mlx"];

        NSPipe *outputPipe = [NSPipe pipe];
        NSPipe *errorPipe = [NSPipe pipe];
        task.standardOutput = outputPipe;
        task.standardError = errorPipe;

        @try {
            [task launch];
            [task waitUntilExit];

            NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
            NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];

            NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
            NSString *errorOutput = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];

            NSString *fullOutput = [NSString stringWithFormat:@"%@\n%@", output ?: @"", errorOutput ?: @""];

            BOOL success = task.terminationStatus == 0;

            if (success) {
                NSLog(@"[MLXPython] ✅ MLX installed successfully");
                [self checkMLXAvailability:nil]; // Refresh status
            } else {
                NSLog(@"[MLXPython] ❌ MLX installation failed");
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(success, fullOutput, nil);
            });

        } @catch (NSException *exception) {
            NSError *error = [NSError errorWithDomain:@"RTSPMLXPython"
                                                code:500
                                            userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, nil, error);
            });
        }
    });
}

- (void)saveSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:self.pythonPath forKey:kRTSPPythonPathKey];

    if (self.mlxPath) {
        [defaults setObject:self.mlxPath forKey:kRTSPMLXPathKey];
    }

    [defaults setBool:self.autoCheckOnLaunch forKey:kRTSPAutoCheckKey];

    [defaults synchronize];

    NSLog(@"[MLXPython] Settings saved");
}

- (void)loadSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSString *savedPath = [defaults stringForKey:kRTSPPythonPathKey];
    if (savedPath) {
        self.pythonPath = savedPath;
    }

    NSString *savedMLXPath = [defaults stringForKey:kRTSPMLXPathKey];
    if (savedMLXPath) {
        self.mlxPath = savedMLXPath;
    }

    self.autoCheckOnLaunch = [defaults boolForKey:kRTSPAutoCheckKey];

    NSLog(@"[MLXPython] Settings loaded: Python=%@", self.pythonPath);
}

@end
