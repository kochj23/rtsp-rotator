//
//  RTSPFFmpegProxy.m
//  RTSP Rotator
//
//  FFmpeg-based proxy implementation for RTSPS stream conversion
//

#import "RTSPFFmpegProxy.h"
#import "RTSPStatusWindow.h"

@interface RTSPProxyInstance : NSObject
@property (nonatomic, strong) NSURL *sourceURL;
@property (nonatomic, strong) NSURL *localURL;
@property (nonatomic, strong) NSString *cameraName;
@property (nonatomic, strong) NSTask *ffmpegTask;
@property (nonatomic, assign) NSInteger localPort;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, strong) NSString *logFilePath;
@end

@implementation RTSPProxyInstance
@end

@interface RTSPFFmpegProxy ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, RTSPProxyInstance *> *proxies;
@property (nonatomic, strong) dispatch_queue_t proxyQueue;
@property (nonatomic, assign) NSInteger nextPort;
@end

@implementation RTSPFFmpegProxy

#pragma mark - Singleton

+ (instancetype)sharedProxy {
    static RTSPFFmpegProxy *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RTSPFFmpegProxy alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _proxies = [NSMutableDictionary dictionary];
        _proxyQueue = dispatch_queue_create("com.rtsp-rotator.ffmpeg-proxy", DISPATCH_QUEUE_SERIAL);
        _basePort = 18554;
        _nextPort = _basePort;
        _verboseLogging = NO;

        // Find FFmpeg
        _ffmpegPath = [self detectFFmpegPath];

        NSLog(@"[FFmpegProxy] Initialized with FFmpeg at: %@", _ffmpegPath);
    }
    return self;
}

- (NSString *)detectFFmpegPath {
    NSArray *possiblePaths = @[
        @"/opt/homebrew/bin/ffmpeg",
        @"/usr/local/bin/ffmpeg",
        @"/usr/bin/ffmpeg"
    ];

    for (NSString *path in possiblePaths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSLog(@"[FFmpegProxy] Found FFmpeg at: %@", path);
            return path;
        }
    }

    NSLog(@"[FFmpegProxy] WARNING: FFmpeg not found in standard locations");
    return @"/opt/homebrew/bin/ffmpeg"; // Default
}

#pragma mark - Proxy Management

- (nullable NSURL *)startProxyForURL:(NSURL *)rtspsURL cameraName:(NSString *)cameraName {
    if (!rtspsURL) {
        NSLog(@"[FFmpegProxy] ERROR: nil URL provided");
        return nil;
    }

    __block NSURL *localURL = nil;

    dispatch_sync(self.proxyQueue, ^{
        NSString *urlKey = rtspsURL.absoluteString;

        // Check if proxy already exists
        RTSPProxyInstance *existing = self.proxies[urlKey];
        if (existing && existing.isRunning) {
            NSLog(@"[FFmpegProxy] Proxy already running for %@", cameraName);
            localURL = existing.localURL;
            return;
        }

        // Create new proxy
        RTSPProxyInstance *proxy = [[RTSPProxyInstance alloc] init];
        proxy.sourceURL = rtspsURL;
        proxy.cameraName = cameraName;
        proxy.localPort = self.nextPort++;
        proxy.localURL = [NSURL URLWithString:[NSString stringWithFormat:@"rtsp://localhost:%ld", (long)proxy.localPort]];

        NSLog(@"[FFmpegProxy] Starting proxy for %@", cameraName);
        NSLog(@"[FFmpegProxy]   Source: %@", rtspsURL.absoluteString);
        NSLog(@"[FFmpegProxy]   Local:  %@", proxy.localURL.absoluteString);

        RTSPStatusWindow *statusWindow = [RTSPStatusWindow sharedWindow];

        // Create HLS output directory for this camera
        NSString *hlsDir = [NSString stringWithFormat:@"/tmp/rtsp_hls_%ld", (long)proxy.localPort];
        NSError *dirError = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:hlsDir withIntermediateDirectories:YES attributes:nil error:&dirError];

        if (dirError) {
            NSLog(@"[FFmpegProxy] ERROR: Could not create HLS directory: %@", dirError);
            [statusWindow appendLog:[NSString stringWithFormat:@"✗ HLS directory creation failed: %@", dirError.localizedDescription] level:@"ERROR"];
            return; // Just return from block, localURL stays nil
        }

        [statusWindow appendLog:[NSString stringWithFormat:@"✓ HLS directory created: %@", hlsDir] level:@"SUCCESS"];

        NSString *hlsPlaylist = [hlsDir stringByAppendingPathComponent:@"stream.m3u8"];
        NSString *ffmpegLogFile = [hlsDir stringByAppendingPathComponent:@"ffmpeg.log"];
        proxy.logFilePath = ffmpegLogFile;

        // Update local URL to point to HLS playlist via HTTP server
        // Extract directory name (e.g., "rtsp_hls_18554")
        // Use 127.0.0.1 instead of localhost to force IPv4 (avoids IPv6 connection refused)
        NSString *hlsDirName = [hlsDir lastPathComponent];
        NSString *httpURL = [NSString stringWithFormat:@"http://127.0.0.1:8080/%@/stream.m3u8", hlsDirName];
        proxy.localURL = [NSURL URLWithString:httpURL];

        // Create FFmpeg task using helper script (bypasses NSTask network restrictions)
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/bin/bash";
        task.arguments = @[
            @"/tmp/ffmpeg_camera_proxy.sh",
            rtspsURL.absoluteString,
            hlsDir,
            ffmpegLogFile
        ];

        // Capture output to both log file AND console
        NSPipe *outputPipe = [NSPipe pipe];
        task.standardOutput = outputPipe;
        task.standardError = outputPipe;

        // Monitor FFmpeg output continuously and write to log file
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            NSFileHandle *handle = [outputPipe fileHandleForReading];
            NSFileHandle *logFile = [NSFileHandle fileHandleForWritingAtPath:ffmpegLogFile];
            if (!logFile) {
                [[NSFileManager defaultManager] createFileAtPath:ffmpegLogFile contents:nil attributes:nil];
                logFile = [NSFileHandle fileHandleForWritingAtPath:ffmpegLogFile];
            }

            NSLog(@"[FFmpegProxy] Logging FFmpeg output to: %@", ffmpegLogFile);
            [statusWindow appendLog:[NSString stringWithFormat:@"FFmpeg log: %@", ffmpegLogFile] level:@"INFO"];

            // Read continuously until task ends
            while (task.isRunning) {
                @autoreleasepool {
                    NSData *data = [handle availableData];
                    if (data.length > 0) {
                        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

                        // Log to console
                        NSLog(@"[FFmpegProxy] %@ OUTPUT: %@", cameraName, output);

                        // Write to file
                        if (logFile) {
                            [logFile writeData:data];
                        }

                        // Show in status window
                        NSArray *lines = [output componentsSeparatedByString:@"\n"];
                        for (NSString *line in lines) {
                            if (line.length > 0 && ![line containsString:@"frame="]) {
                                [statusWindow appendLog:[NSString stringWithFormat:@"[FFmpeg] %@", line] level:@"INFO"];
                            }
                        }
                    }
                    usleep(100000); // 0.1 second
                }
            }

            // Read any final output after termination
            NSData *finalData = [handle readDataToEndOfFile];
            if (finalData.length > 0) {
                NSString *output = [[NSString alloc] initWithData:finalData encoding:NSUTF8StringEncoding];
                NSLog(@"[FFmpegProxy] %@ FINAL OUTPUT: %@", cameraName, output);
                [statusWindow appendLog:[NSString stringWithFormat:@"[FFmpeg] FINAL: %@", output] level:@"ERROR"];

                if (logFile) {
                    [logFile writeData:finalData];
                }
            }

            if (logFile) {
                [logFile closeFile];
            }

            // Log termination
            int exitCode = task.terminationStatus;
            NSLog(@"[FFmpegProxy] %@ terminated with exit code: %d", cameraName, exitCode);
            [statusWindow appendLog:[NSString stringWithFormat:@"FFmpeg terminated (exit code: %d)", exitCode] level:exitCode == 0 ? @"INFO" : @"ERROR"];
        });

        // Launch FFmpeg
        @try {
            NSLog(@"[FFmpegProxy] ==========================================");
            NSLog(@"[FFmpegProxy] Launching FFmpeg for: %@", cameraName);
            NSLog(@"[FFmpegProxy] Command: %@", self.ffmpegPath);
            NSLog(@"[FFmpegProxy] Arguments: %@", [task.arguments componentsJoinedByString:@" "]);
            NSLog(@"[FFmpegProxy] HLS Directory: %@", hlsDir);
            NSLog(@"[FFmpegProxy] HLS Playlist: %@", hlsPlaylist);
            NSLog(@"[FFmpegProxy] ==========================================");

            [task launch];
            proxy.ffmpegTask = task;
            proxy.isRunning = YES;
            self.proxies[urlKey] = proxy;

            NSLog(@"[FFmpegProxy] ✓ FFmpeg process started (PID: %d) for %@", task.processIdentifier, cameraName);
            NSLog(@"[FFmpegProxy] ✓ HLS output will be at: %@", hlsPlaylist);

            // Give FFmpeg time to create HLS segments (needs 6-8 seconds for first playable segments)
            NSLog(@"[FFmpegProxy] Waiting for HLS segments to initialize (8 seconds)...");
            [NSThread sleepForTimeInterval:8.0];

            // Check if FFmpeg is still running and HLS playlist exists
            if (task.isRunning) {
                BOOL hlsExists = [[NSFileManager defaultManager] fileExistsAtPath:hlsPlaylist];
                if (hlsExists) {
                    NSLog(@"[FFmpegProxy] ✓ FFmpeg still running - HLS playlist ready");
                    NSLog(@"[FFmpegProxy] ✓ HLS file: %@", hlsPlaylist);
                    localURL = proxy.localURL;
                } else {
                    NSLog(@"[FFmpegProxy] ⚠ WARNING: HLS playlist not found yet at: %@", hlsPlaylist);
                    // Return URL anyway, might appear soon
                    localURL = proxy.localURL;
                }
            } else {
                NSLog(@"[FFmpegProxy] ERROR: FFmpeg process terminated unexpectedly!");
                proxy.isRunning = NO;
                [self.proxies removeObjectForKey:urlKey];
            }
        } @catch (NSException *exception) {
            NSLog(@"[FFmpegProxy] ERROR: Failed to launch FFmpeg: %@", exception);
            NSLog(@"[FFmpegProxy] Exception reason: %@", exception.reason);
        }
    });

    return localURL;
}

- (void)stopProxyForURL:(NSURL *)rtspsURL {
    if (!rtspsURL) return;

    dispatch_sync(self.proxyQueue, ^{
        NSString *urlKey = rtspsURL.absoluteString;
        RTSPProxyInstance *proxy = self.proxies[urlKey];

        if (proxy && proxy.isRunning) {
            NSLog(@"[FFmpegProxy] Stopping proxy for %@", proxy.cameraName);

            if (proxy.ffmpegTask && proxy.ffmpegTask.isRunning) {
                [proxy.ffmpegTask terminate];
                [proxy.ffmpegTask waitUntilExit];
            }

            proxy.isRunning = NO;
            [self.proxies removeObjectForKey:urlKey];

            NSLog(@"[FFmpegProxy] ✓ Proxy stopped for %@", proxy.cameraName);
        }
    });
}

- (void)stopAllProxies {
    NSLog(@"[FFmpegProxy] Stopping all proxies (%lu active)", (unsigned long)self.proxies.count);

    dispatch_sync(self.proxyQueue, ^{
        for (RTSPProxyInstance *proxy in self.proxies.allValues) {
            if (proxy.ffmpegTask && proxy.ffmpegTask.isRunning) {
                [proxy.ffmpegTask terminate];
            }
        }
        [self.proxies removeAllObjects];
        self.nextPort = self.basePort; // Reset port counter
    });

    NSLog(@"[FFmpegProxy] ✓ All proxies stopped");
}

- (BOOL)isProxyRunningForURL:(NSURL *)rtspsURL {
    if (!rtspsURL) return NO;

    __block BOOL running = NO;
    dispatch_sync(self.proxyQueue, ^{
        NSString *urlKey = rtspsURL.absoluteString;
        RTSPProxyInstance *proxy = self.proxies[urlKey];
        running = (proxy != nil && proxy.isRunning && proxy.ffmpegTask.isRunning);
    });
    return running;
}

- (nullable NSURL *)localURLForRTSPSURL:(NSURL *)rtspsURL {
    if (!rtspsURL) return nil;

    __block NSURL *localURL = nil;
    dispatch_sync(self.proxyQueue, ^{
        NSString *urlKey = rtspsURL.absoluteString;
        RTSPProxyInstance *proxy = self.proxies[urlKey];
        if (proxy && proxy.isRunning) {
            localURL = proxy.localURL;
        }
    });
    return localURL;
}

#pragma mark - Status

- (NSInteger)activeProxyCount {
    __block NSInteger count = 0;
    dispatch_sync(self.proxyQueue, ^{
        count = self.proxies.count;
    });
    return count;
}

- (NSArray<NSDictionary *> *)proxyStatus {
    __block NSMutableArray *status = [NSMutableArray array];

    dispatch_sync(self.proxyQueue, ^{
        for (RTSPProxyInstance *proxy in self.proxies.allValues) {
            [status addObject:@{
                @"cameraName": proxy.cameraName ?: @"Unknown",
                @"sourceURL": proxy.sourceURL.absoluteString,
                @"localURL": proxy.localURL.absoluteString,
                @"localPort": @(proxy.localPort),
                @"isRunning": @(proxy.isRunning && proxy.ffmpegTask.isRunning),
                @"pid": @(proxy.ffmpegTask.processIdentifier)
            }];
        }
    });

    return [status copy];
}

#pragma mark - Cleanup

- (void)dealloc {
    [self stopAllProxies];
}

@end
