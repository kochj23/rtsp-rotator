//
//  RTSPAPIServer.m
//  RTSP Rotator
//
//  Simple HTTP REST API server using NSURLConnection
//

#import "RTSPAPIServer.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@interface RTSPAPIServer () <NSNetServiceDelegate>
@property (nonatomic, strong, nullable) NSNetService *netService;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, assign) CFSocketRef socket;
@property (nonatomic, strong) dispatch_queue_t serverQueue;
@end

@implementation RTSPAPIServer

+ (instancetype)sharedServer {
    static RTSPAPIServer *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RTSPAPIServer alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _enabled = NO;
        _port = 8080;
        _requireAPIKey = NO;
        _isRunning = NO;
        _serverQueue = dispatch_queue_create("com.rtsp.apiserver", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (BOOL)start {
    if (self.isRunning) {
        NSLog(@"[API] Server already running");
        return YES;
    }

    if (!self.enabled) {
        NSLog(@"[API] Server is disabled");
        return NO;
    }

    // Create socket
    CFSocketContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
    self.socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, &handleConnect, &context);

    if (!self.socket) {
        NSLog(@"[API] Failed to create socket");
        return NO;
    }

    // Set socket options
    int yes = 1;
    setsockopt(CFSocketGetNative(self.socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));

    // Bind to port
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_port = htons((uint16_t)self.port);
    addr.sin_addr.s_addr = htonl(INADDR_ANY);

    NSData *address = [NSData dataWithBytes:&addr length:sizeof(addr)];
    CFSocketError error = CFSocketSetAddress(self.socket, (__bridge CFDataRef)address);

    if (error != kCFSocketSuccess) {
        NSLog(@"[API] Failed to bind to port %ld", (long)self.port);
        CFRelease(self.socket);
        self.socket = NULL;
        return NO;
    }

    // Add to run loop
    CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, self.socket, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
    CFRelease(source);

    self.isRunning = YES;

    NSLog(@"[API] Server started on port %ld", (long)self.port);
    NSLog(@"[API] Base URL: %@", [self baseURL].absoluteString);

    return YES;
}

static void handleConnect(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    RTSPAPIServer *server = (__bridge RTSPAPIServer *)info;

    if (type == kCFSocketAcceptCallBack) {
        CFSocketNativeHandle nativeSocket = *(CFSocketNativeHandle *)data;

        dispatch_async(server.serverQueue, ^{
            [server handleConnection:nativeSocket];
        });
    }
}

- (void)handleConnection:(CFSocketNativeHandle)nativeSocket {
    // Read request
    char buffer[4096];
    ssize_t bytesRead = recv(nativeSocket, buffer, sizeof(buffer) - 1, 0);

    if (bytesRead <= 0) {
        close(nativeSocket);
        return;
    }

    buffer[bytesRead] = '\0';
    NSString *request = [NSString stringWithUTF8String:buffer];

    // Parse HTTP request
    NSArray *lines = [request componentsSeparatedByString:@"\r\n"];
    if (lines.count == 0) {
        close(nativeSocket);
        return;
    }

    NSString *requestLine = lines[0];
    NSArray *parts = [requestLine componentsSeparatedByString:@" "];

    if (parts.count < 3) {
        [self sendResponse:@"HTTP/1.1 400 Bad Request\r\n\r\n" toSocket:nativeSocket];
        close(nativeSocket);
        return;
    }

    NSString *method = parts[0];
    NSString *path = parts[1];

    // Check API key if required
    if (self.requireAPIKey && self.apiKey) {
        BOOL authenticated = NO;

        for (NSString *line in lines) {
            if ([line hasPrefix:@"Authorization:"]) {
                NSString *auth = [line substringFromIndex:14];
                auth = [auth stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                if ([auth isEqualToString:self.apiKey]) {
                    authenticated = YES;
                    break;
                }
            }
        }

        if (!authenticated) {
            [self sendResponse:@"HTTP/1.1 401 Unauthorized\r\n\r\n{\"error\":\"Invalid API key\"}" toSocket:nativeSocket];
            close(nativeSocket);
            return;
        }
    }

    // Route request
    NSDictionary *response = [self routeRequest:method path:path];

    // Send response
    [self sendJSONResponse:response toSocket:nativeSocket];
    close(nativeSocket);
}

- (NSDictionary *)routeRequest:(NSString *)method path:(NSString *)path {
    if (![method isEqualToString:@"GET"] && ![method isEqualToString:@"POST"]) {
        return @{@"error": @"Method not allowed"};
    }

    // API endpoints
    if ([path isEqualToString:@"/"] || [path isEqualToString:@"/api"]) {
        return @{
            @"name": @"RTSP Rotator API",
            @"version": @"1.0",
            @"endpoints": @[
                @"/api/feeds",
                @"/api/current",
                @"/api/switch/<index>",
                @"/api/next",
                @"/api/previous",
                @"/api/snapshot",
                @"/api/recording/start",
                @"/api/recording/stop",
                @"/api/recording/status",
                @"/api/interval/<seconds>"
            ]
        };
    } else if ([path isEqualToString:@"/api/feeds"]) {
        return [self handleGetFeeds];
    } else if ([path isEqualToString:@"/api/current"]) {
        return [self handleGetCurrent];
    } else if ([path hasPrefix:@"/api/switch/"]) {
        NSString *indexStr = [path substringFromIndex:12];
        NSInteger index = [indexStr integerValue];
        return [self handleSwitchToFeed:index];
    } else if ([path isEqualToString:@"/api/next"]) {
        return [self handleNextFeed];
    } else if ([path isEqualToString:@"/api/previous"]) {
        return [self handlePreviousFeed];
    } else if ([path isEqualToString:@"/api/snapshot"]) {
        return [self handleSnapshot];
    } else if ([path isEqualToString:@"/api/recording/start"]) {
        return [self handleStartRecording];
    } else if ([path isEqualToString:@"/api/recording/stop"]) {
        return [self handleStopRecording];
    } else if ([path isEqualToString:@"/api/recording/status"]) {
        return [self handleRecordingStatus];
    } else if ([path hasPrefix:@"/api/interval/"]) {
        NSString *intervalStr = [path substringFromIndex:14];
        NSTimeInterval interval = [intervalStr doubleValue];
        return [self handleSetInterval:interval];
    }

    return @{@"error": @"Endpoint not found"};
}

- (NSDictionary *)handleGetFeeds {
    if ([self.delegate respondsToSelector:@selector(apiServerRequestFeedList:)]) {
        NSArray *feeds = [self.delegate apiServerRequestFeedList:self];
        return @{@"success": @YES, @"feeds": feeds, @"count": @(feeds.count)};
    }
    return @{@"error": @"Not implemented"};
}

- (NSDictionary *)handleGetCurrent {
    if ([self.delegate respondsToSelector:@selector(apiServerRequestCurrentFeedIndex:)]) {
        NSInteger index = [self.delegate apiServerRequestCurrentFeedIndex:self];
        return @{@"success": @YES, @"index": @(index)};
    }
    return @{@"error": @"Not implemented"};
}

- (NSDictionary *)handleSwitchToFeed:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(apiServer:switchToFeedAtIndex:)]) {
        [self.delegate apiServer:self switchToFeedAtIndex:index];
        return @{@"success": @YES, @"message": @"Switched to feed", @"index": @(index)};
    }
    return @{@"error": @"Not implemented"};
}

- (NSDictionary *)handleNextFeed {
    if ([self.delegate respondsToSelector:@selector(apiServerSwitchToNextFeed:)]) {
        [self.delegate apiServerSwitchToNextFeed:self];
        return @{@"success": @YES, @"message": @"Switched to next feed"};
    }
    return @{@"error": @"Not implemented"};
}

- (NSDictionary *)handlePreviousFeed {
    if ([self.delegate respondsToSelector:@selector(apiServerSwitchToPreviousFeed:)]) {
        [self.delegate apiServerSwitchToPreviousFeed:self];
        return @{@"success": @YES, @"message": @"Switched to previous feed"};
    }
    return @{@"error": @"Not implemented"};
}

- (NSDictionary *)handleSnapshot {
    if ([self.delegate respondsToSelector:@selector(apiServerTakeSnapshot:)]) {
        [self.delegate apiServerTakeSnapshot:self];
        return @{@"success": @YES, @"message": @"Snapshot taken"};
    }
    return @{@"error": @"Not implemented"};
}

- (NSDictionary *)handleStartRecording {
    if ([self.delegate respondsToSelector:@selector(apiServerStartRecording:)]) {
        [self.delegate apiServerStartRecording:self];
        return @{@"success": @YES, @"message": @"Recording started"};
    }
    return @{@"error": @"Not implemented"};
}

- (NSDictionary *)handleStopRecording {
    if ([self.delegate respondsToSelector:@selector(apiServerStopRecording:)]) {
        [self.delegate apiServerStopRecording:self];
        return @{@"success": @YES, @"message": @"Recording stopped"};
    }
    return @{@"error": @"Not implemented"};
}

- (NSDictionary *)handleRecordingStatus {
    if ([self.delegate respondsToSelector:@selector(apiServerIsRecording:)]) {
        BOOL isRecording = [self.delegate apiServerIsRecording:self];
        return @{@"success": @YES, @"recording": @(isRecording)};
    }
    return @{@"error": @"Not implemented"};
}

- (NSDictionary *)handleSetInterval:(NSTimeInterval)interval {
    if ([self.delegate respondsToSelector:@selector(apiServer:setRotationInterval:)]) {
        [self.delegate apiServer:self setRotationInterval:interval];
        return @{@"success": @YES, @"message": @"Interval updated", @"interval": @(interval)};
    }
    return @{@"error": @"Not implemented"};
}

- (void)sendJSONResponse:(NSDictionary *)json toSocket:(CFSocketNativeHandle)socket {
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];

    if (error) {
        [self sendResponse:@"HTTP/1.1 500 Internal Server Error\r\n\r\n{\"error\":\"JSON serialization failed\"}" toSocket:socket];
        return;
    }

    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *response = [NSString stringWithFormat:@"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: %lu\r\n\r\n%@", (unsigned long)[jsonData length], jsonString];

    [self sendResponse:response toSocket:socket];
}

- (void)sendResponse:(NSString *)response toSocket:(CFSocketNativeHandle)socket {
    const char *bytes = [response UTF8String];
    send(socket, bytes, strlen(bytes), 0);
}

- (void)stop {
    if (!self.isRunning) {
        return;
    }

    if (self.socket) {
        CFSocketInvalidate(self.socket);
        CFRelease(self.socket);
        self.socket = NULL;
    }

    self.isRunning = NO;

    NSLog(@"[API] Server stopped");
}

- (NSURL *)baseURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%ld", (long)self.port]];
}

- (void)dealloc {
    [self stop];
}

@end
