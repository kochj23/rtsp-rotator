//
//  RTSPUniFiProtectAdapter.m
//  RTSP Rotator
//
//  UniFi Protect integration implementation
//

#import "RTSPUniFiProtectAdapter.h"
#import "RTSPPreferencesController.h"
#import "RTSPCameraDiagnostics.h"
#import "RTSPStatusWindow.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <CoreFoundation/CoreFoundation.h>

#pragma mark - UniFi Camera Implementation

@implementation RTSPUniFiCamera

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _cameraId = [coder decodeObjectOfClass:[NSString class] forKey:@"cameraId"];
        _name = [coder decodeObjectOfClass:[NSString class] forKey:@"name"];
        _model = [coder decodeObjectOfClass:[NSString class] forKey:@"model"];
        _macAddress = [coder decodeObjectOfClass:[NSString class] forKey:@"macAddress"];
        _ipAddress = [coder decodeObjectOfClass:[NSString class] forKey:@"ipAddress"];
        _firmwareVersion = [coder decodeObjectOfClass:[NSString class] forKey:@"firmwareVersion"];
        _isOnline = [coder decodeBoolForKey:@"isOnline"];
        _supportsRTSP = [coder decodeBoolForKey:@"supportsRTSP"];
        _rtspPort = [coder decodeIntegerForKey:@"rtspPort"];
        _rtspChannel = [coder decodeIntegerForKey:@"rtspChannel"];
        _rtspURL = [coder decodeObjectOfClass:[NSString class] forKey:@"rtspURL"];
        _cameraType = [coder decodeObjectOfClass:[NSString class] forKey:@"cameraType"];
        _lastSeen = [coder decodeObjectOfClass:[NSDate class] forKey:@"lastSeen"];
        _rawData = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"rawData"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.cameraId forKey:@"cameraId"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.model forKey:@"model"];
    [coder encodeObject:self.macAddress forKey:@"macAddress"];
    [coder encodeObject:self.ipAddress forKey:@"ipAddress"];
    [coder encodeObject:self.firmwareVersion forKey:@"firmwareVersion"];
    [coder encodeBool:self.isOnline forKey:@"isOnline"];
    [coder encodeBool:self.supportsRTSP forKey:@"supportsRTSP"];
    [coder encodeInteger:self.rtspPort forKey:@"rtspPort"];
    [coder encodeInteger:self.rtspChannel forKey:@"rtspChannel"];
    [coder encodeObject:self.rtspURL forKey:@"rtspURL"];
    [coder encodeObject:self.cameraType forKey:@"cameraType"];
    [coder encodeObject:self.lastSeen forKey:@"lastSeen"];
    [coder encodeObject:self.rawData forKey:@"rawData"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<RTSPUniFiCamera: %@ (%@) - %@ - %@>",
            self.name, self.model, self.ipAddress, self.isOnline ? @"Online" : @"Offline"];
}

@end

#pragma mark - UniFi Protect Adapter Implementation

@interface RTSPUniFiProtectAdapter () <NSURLSessionDelegate>
@property (nonatomic, strong, nullable) NSString *authToken;
@property (nonatomic, strong, nullable) NSString *authCookie;
@property (nonatomic, strong, nullable) NSURLSession *session;
@property (nonatomic, strong, nullable) NSArray<RTSPUniFiCamera *> *cachedCameras;
@end

@implementation RTSPUniFiProtectAdapter

#pragma mark - Singleton

+ (instancetype)sharedAdapter {
    static RTSPUniFiProtectAdapter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RTSPUniFiProtectAdapter alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _controllerPort = 443;
        _useHTTPS = YES;
        _verifySSL = NO; // Most UniFi controllers use self-signed certs
        _cachedCameras = @[];

        // Create URL session with custom configuration
        // Use ephemeralSessionConfiguration to bypass some restrictions
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        config.timeoutIntervalForRequest = 30.0;
        config.timeoutIntervalForResource = 60.0;
        config.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
        config.HTTPShouldSetCookies = YES;
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        config.URLCache = nil; // Disable caching
        config.allowsCellularAccess = YES;
        config.waitsForConnectivity = NO;

        // Add headers
        config.HTTPAdditionalHeaders = @{
            @"User-Agent": @"RTSP Rotator/2.2.0",
            @"Accept": @"*/*"
        };

        _session = [NSURLSession sessionWithConfiguration:config
                                                 delegate:self
                                            delegateQueue:nil];

        [self loadConfiguration];
    }
    return self;
}

#pragma mark - Configuration Persistence

- (void)saveConfiguration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (self.controllerHost) [defaults setObject:self.controllerHost forKey:@"UniFi_ControllerHost"];
    [defaults setInteger:self.controllerPort forKey:@"UniFi_ControllerPort"];
    if (self.username) [defaults setObject:self.username forKey:@"UniFi_Username"];
    if (self.password) {
        // Store password in NSUserDefaults (consider Keychain for production)
        [defaults setObject:self.password forKey:@"UniFi_Password"];
    }
    [defaults setBool:self.useHTTPS forKey:@"UniFi_UseHTTPS"];
    [defaults setBool:self.verifySSL forKey:@"UniFi_VerifySSL"];

    [defaults synchronize];
    NSLog(@"[UniFi] Configuration saved");
}

- (void)loadConfiguration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    self.controllerHost = [defaults stringForKey:@"UniFi_ControllerHost"];
    NSInteger port = [defaults integerForKey:@"UniFi_ControllerPort"];
    self.controllerPort = port > 0 ? port : 443;
    self.username = [defaults stringForKey:@"UniFi_Username"];
    self.password = [defaults stringForKey:@"UniFi_Password"];
    self.useHTTPS = [defaults boolForKey:@"UniFi_UseHTTPS"];
    self.verifySSL = [defaults boolForKey:@"UniFi_VerifySSL"];

    NSLog(@"[UniFi] Configuration loaded:");
    NSLog(@"[UniFi]   Host: %@", self.controllerHost ?: @"(nil)");
    NSLog(@"[UniFi]   Port: %ld", (long)self.controllerPort);
    NSLog(@"[UniFi]   Username: %@", self.username ?: @"(nil)");
    NSLog(@"[UniFi]   Password: %@", self.password ? @"(set)" : @"(nil)");
    NSLog(@"[UniFi]   UseHTTPS: %d", self.useHTTPS);
}

- (void)clearCredentials {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"UniFi_Password"];
    [defaults removeObjectForKey:@"UniFi_Username"];
    [defaults synchronize];

    self.authToken = nil;
    self.authCookie = nil;
    self.username = nil;
    self.password = nil;

    NSLog(@"[UniFi] Credentials cleared");
}

#pragma mark - Network Test

- (void)testNetworkConnectivity:(void (^)(BOOL success))completion {
    // Simple TCP connection test to trigger local network permission
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFSocketRef socket = CFSocketCreate(NULL, PF_INET, SOCK_STREAM, IPPROTO_TCP, 0, NULL, NULL);
        if (socket) {
            struct sockaddr_in addr;
            memset(&addr, 0, sizeof(addr));
            addr.sin_family = AF_INET;
            addr.sin_port = htons(self.controllerPort);
            inet_pton(AF_INET, [self.controllerHost UTF8String], &addr.sin_addr);

            CFDataRef addressData = CFDataCreate(NULL, (UInt8 *)&addr, sizeof(addr));
            CFSocketError socketError = CFSocketConnectToAddress(socket, addressData, 5.0);

            BOOL success = (socketError == kCFSocketSuccess);
            CFRelease(addressData);
            CFRelease(socket);

            NSLog(@"[UniFi] Network connectivity test: %@", success ? @"SUCCESS" : @"FAILED");

            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(success);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO);
            });
        }
    });
}

#pragma mark - Authentication

- (BOOL)isAuthenticated {
    return (self.authToken != nil || self.authCookie != nil);
}

- (void)authenticateWithCompletion:(void (^)(BOOL, NSError * _Nullable))completion {
    [self authenticateWithMFAToken:nil completion:completion];
}

- (void)authenticateWithMFAToken:(NSString *)mfaToken completion:(void (^)(BOOL, NSError * _Nullable))completion {
    if (!self.controllerHost || !self.username || !self.password) {
        NSError *error = [NSError errorWithDomain:@"RTSPUniFiProtectAdapter"
                                             code:1001
                                         userInfo:@{NSLocalizedDescriptionKey: @"Missing host, username, or password"}];
        NSLog(@"[UniFi] ERROR: Authentication failed - missing credentials");
        if (completion) completion(NO, error);
        return;
    }

    NSLog(@"[UniFi] Authenticating with UniFi Protect at %@:%ld%@", self.controllerHost, (long)self.controllerPort, mfaToken ? @" (with MFA)" : @"");

    // First test network connectivity to trigger permission prompt
    [self testNetworkConnectivity:^(BOOL networkSuccess) {
        if (!networkSuccess) {
            NSLog(@"[UniFi] WARNING: Network connectivity test failed - proceeding anyway");
        }
        [self performAuthenticationWithMFAToken:mfaToken completion:completion];
    }];
}

- (void)performAuthenticationWithMFAToken:(NSString *)mfaToken completion:(void (^)(BOOL, NSError * _Nullable))completion {

    NSLog(@"[UniFi] Using curl via NSTask with proper environment");

    // Use curl directly via NSTask instead of shell script
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *protocol = self.useHTTPS ? @"https" : @"http";
        NSString *urlString = [NSString stringWithFormat:@"%@://%@:%ld/api/auth/login",
                              protocol, self.controllerHost, (long)self.controllerPort];

        // Build JSON body
        NSMutableDictionary *body = [@{
            @"username": self.username ?: @"",
            @"password": self.password ?: @"",
            @"rememberMe": @YES
        } mutableCopy];

        if (mfaToken) {
            body[@"token"] = mfaToken;
        }

        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
        if (jsonError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, jsonError);
            });
            return;
        }

        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        // Calculate cookie file path (same as discovery uses)
        NSString *hostSafe = [self.controllerHost stringByReplacingOccurrencesOfString:@"." withString:@""];
        hostSafe = [hostSafe stringByReplacingOccurrencesOfString:@":" withString:@""];
        NSString *usernameSafe = [self.username stringByReplacingOccurrencesOfString:@"+" withString:@""];
        usernameSafe = [usernameSafe stringByReplacingOccurrencesOfString:@"@" withString:@""];
        usernameSafe = [usernameSafe stringByReplacingOccurrencesOfString:@"." withString:@""];
        NSString *cookieFilePath = [NSString stringWithFormat:@"/tmp/unifi_cookies_%@_%@.txt", hostSafe, usernameSafe];

        NSLog(@"[UniFi] Will save session cookie to: %@", cookieFilePath);

        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/curl";
        task.arguments = @[
            @"-k",  // Allow self-signed certs
            @"-s",  // Silent
            @"-c", cookieFilePath,  // SAVE COOKIES TO FILE (THIS WAS MISSING!)
            @"-X", @"POST",
            @"-H", @"Content-Type: application/json",
            @"-H", @"Accept: */*",
            @"-H", @"User-Agent: RTSP Rotator/2.2.0",
            @"-w", @"\nHTTP_STATUS:%{http_code}",
            @"-d", jsonString,
            urlString
        ];

        NSPipe *outputPipe = [NSPipe pipe];
        task.standardOutput = outputPipe;
        task.standardError = outputPipe;

        NSLog(@"[UniFi] Executing curl directly: %@", urlString);

        [task launch];
        [task waitUntilExit];

        NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

        NSLog(@"[UniFi] Curl exit status: %d", task.terminationStatus);
        NSLog(@"[UniFi] Curl output length: %lu bytes", (unsigned long)output.length);

        // Parse the response
        NSArray *lines = [output componentsSeparatedByString:@"\n"];
        NSString *statusLine = [lines lastObject];
        NSInteger statusCode = 0;

        if ([statusLine hasPrefix:@"HTTP_STATUS:"]) {
            statusCode = [[statusLine substringFromIndex:12] integerValue];
            NSLog(@"[UniFi] Parsed status code: %ld", (long)statusCode);
        }

        // Get the JSON response (everything except last line)
        NSMutableString *jsonResponse = [NSMutableString string];
        for (NSInteger i = 0; i < lines.count - 1; i++) {
            NSString *line = lines[i];
            if (line.length > 0) {
                [jsonResponse appendString:line];
            }
        }

        NSData *responseData = [jsonResponse dataUsingEncoding:NSUTF8StringEncoding];
        NSError *parseError = nil;
        id response = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError];

        if (parseError) {
            NSLog(@"[UniFi] Response parse error: %@", parseError);
        }

        [self handleAuthenticationResponse:response statusCode:statusCode completion:completion];
    });
}

- (void)handleAuthenticationResponse:(id)jsonResponse statusCode:(NSInteger)statusCode completion:(void (^)(BOOL, NSError * _Nullable))completion {

    dispatch_async(dispatch_get_main_queue(), ^{
        if (statusCode == 200) {
            // Successful authentication
            if ([jsonResponse isKindOfClass:[NSDictionary class]]) {
                NSString *token = jsonResponse[@"token"] ?: jsonResponse[@"accessToken"];
                if (token) {
                    self.authToken = token;
                    NSLog(@"[UniFi] ✓ Got authentication token");
                } else {
                    NSLog(@"[UniFi] ✓ No token in response - using cookie-based auth");
                }
            }

            // Set authCookie to a placeholder value to mark as authenticated
            // The actual session cookie is stored in the curl cookie file
            if (!self.authCookie) {
                self.authCookie = @"authenticated";
            }

            // Verify cookie file was actually created
            NSString *hostSafe = [self.controllerHost stringByReplacingOccurrencesOfString:@"." withString:@""];
            hostSafe = [hostSafe stringByReplacingOccurrencesOfString:@":" withString:@""];
            NSString *usernameSafe = [self.username stringByReplacingOccurrencesOfString:@"+" withString:@""];
            usernameSafe = [usernameSafe stringByReplacingOccurrencesOfString:@"@" withString:@""];
            usernameSafe = [usernameSafe stringByReplacingOccurrencesOfString:@"." withString:@""];
            NSString *cookieFilePath = [NSString stringWithFormat:@"/tmp/unifi_cookies_%@_%@.txt", hostSafe, usernameSafe];

            if ([[NSFileManager defaultManager] fileExistsAtPath:cookieFilePath]) {
                NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:cookieFilePath error:nil];
                unsigned long long fileSize = [attrs fileSize];
                NSLog(@"[UniFi] ✓ Session cookie file created: %@ (%llu bytes)", cookieFilePath, fileSize);
            } else {
                NSLog(@"[UniFi] ⚠ WARNING: Cookie file was not created at: %@", cookieFilePath);
            }

            if (completion) completion(YES, nil);
            if ([self.delegate respondsToSelector:@selector(unifiProtectAdapterDidAuthenticate:)]) {
                [self.delegate unifiProtectAdapterDidAuthenticate:self];
            }
        } else {
            // Parse error message from response
            NSString *errorMessage = [NSString stringWithFormat:@"HTTP %ld", (long)statusCode];
            BOOL requiresMFA = NO;

            if ([jsonResponse isKindOfClass:[NSDictionary class]]) {
                NSString *message = jsonResponse[@"message"];
                NSString *code = jsonResponse[@"code"];

                // Check if MFA is required
                if ([code isEqualToString:@"MFA_REQUIRED"] ||
                    [code isEqualToString:@"MFA_AUTH_REQUIRED"] ||
                    [message rangeOfString:@"MFA" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                    [message rangeOfString:@"two-factor" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    requiresMFA = YES;
                    errorMessage = @"MFA_REQUIRED";

                    // Store MFA cookie if provided
                    NSString *mfaCookie = jsonResponse[@"mfaCookie"];
                    if (mfaCookie) {
                        self.authCookie = mfaCookie;
                        NSLog(@"[UniFi] Stored MFA cookie for 2FA flow");
                    }
                } else if (message) {
                    errorMessage = [NSString stringWithFormat:@"HTTP %ld: %@", (long)statusCode, message];
                }
            }

            NSError *statusError = [NSError errorWithDomain:@"RTSPUniFiProtectAdapter"
                                                       code:requiresMFA ? 1008 : statusCode
                                                   userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
            NSLog(@"[UniFi] ERROR: Authentication failed - %@", errorMessage);

            if (completion) completion(NO, statusError);
            if ([self.delegate respondsToSelector:@selector(unifiProtectAdapter:didFailAuthenticationWithError:)]) {
                [self.delegate unifiProtectAdapter:self didFailAuthenticationWithError:statusError];
            }
        }
    });
}

- (void)logout {
    if (!self.isAuthenticated) {
        return;
    }

    NSLog(@"[UniFi] Logging out from UniFi Protect");

    NSString *protocol = self.useHTTPS ? @"https" : @"http";
    NSString *urlString = [NSString stringWithFormat:@"%@://%@:%ld/api/auth/logout",
                          protocol, self.controllerHost, (long)self.controllerPort];

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [self addAuthenticationToRequest:request];

    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        self.authToken = nil;
        self.authCookie = nil;
        NSLog(@"[UniFi] Logged out");
    }];

    [task resume];
}

#pragma mark - Camera Discovery

- (void)discoverCamerasWithCompletion:(void (^)(NSArray<RTSPUniFiCamera *> * _Nullable, NSError * _Nullable))completion {
    if (!self.isAuthenticated) {
        NSLog(@"[UniFi] Not authenticated, authenticating first...");
        [self authenticateWithCompletion:^(BOOL success, NSError *error) {
            if (success) {
                [self performCameraDiscovery:completion];
            } else {
                if (completion) completion(nil, error);
            }
        }];
        return;
    }

    [self performCameraDiscovery:completion];
}

- (void)performCameraDiscovery:(void (^)(NSArray<RTSPUniFiCamera *> * _Nullable, NSError * _Nullable))completion {
    RTSPStatusWindow *statusWindow = [RTSPStatusWindow sharedWindow];

    NSLog(@"[UniFi] Discovering cameras...");
    [statusWindow appendLog:@"Initiating camera discovery..." level:@"INFO"];

    // Check for session cookie BEFORE attempting discovery
    NSString *hostSafe = [self.controllerHost stringByReplacingOccurrencesOfString:@"." withString:@""];
    hostSafe = [hostSafe stringByReplacingOccurrencesOfString:@":" withString:@""];
    NSString *usernameSafe = [self.username stringByReplacingOccurrencesOfString:@"+" withString:@""];
    usernameSafe = [usernameSafe stringByReplacingOccurrencesOfString:@"@" withString:@""];
    usernameSafe = [usernameSafe stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSString *cookieFilePath = [NSString stringWithFormat:@"/tmp/unifi_cookies_%@_%@.txt", hostSafe, usernameSafe];

    NSLog(@"[UniFi] Checking for session cookie: %@", cookieFilePath);
    [statusWindow appendLog:[NSString stringWithFormat:@"Looking for session cookie: %@", cookieFilePath] level:@"INFO"];

    BOOL cookieExists = [[NSFileManager defaultManager] fileExistsAtPath:cookieFilePath];
    if (cookieExists) {
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:cookieFilePath error:nil];
        unsigned long long fileSize = [attrs fileSize];
        NSLog(@"[UniFi] ✓ Cookie file found (size: %llu bytes)", fileSize);
        [statusWindow appendLog:[NSString stringWithFormat:@"✓ Session cookie exists (%llu bytes)", fileSize] level:@"SUCCESS"];

        if (fileSize < 50) {
            NSLog(@"[UniFi] ⚠ Cookie file seems empty or invalid");
            [statusWindow appendLog:@"⚠ Cookie file is too small - may be invalid" level:@"WARNING"];
            [statusWindow appendLog:@"You may need to re-authenticate with MFA" level:@"WARNING"];
        }
    } else {
        NSLog(@"[UniFi] ✗ Cookie file NOT found - authentication required!");
        [statusWindow appendLog:@"✗ No session cookie found!" level:@"ERROR"];
        [statusWindow appendLog:@"You must authenticate first:" level:@"ERROR"];
        [statusWindow appendLog:@"  1. Menu → UniFi Protect → Connect to Controller" level:@"INFO"];
        [statusWindow appendLog:@"  2. Enter your Google Authenticator MFA code" level:@"INFO"];
        [statusWindow appendLog:@"  3. Then try discovery again" level:@"INFO"];

        NSError *noCookieError = [NSError errorWithDomain:@"RTSPUniFiProtectAdapter"
                                                     code:401
                                                 userInfo:@{NSLocalizedDescriptionKey: @"No session cookie - authenticate first"}];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(nil, noCookieError);
        });
        return;
    }

    NSLog(@"[UniFi] Using curl helper to discover cameras (cookie-based auth)");
    [statusWindow appendLog:@"Using curl helper for network bypass" level:@"INFO"];

    NSLog(@"[UniFi] Host: %@, Username: %@", self.controllerHost, self.username);
    [statusWindow appendLog:[NSString stringWithFormat:@"Host: %@, Username: %@", self.controllerHost, self.username] level:@"INFO"];

    // Use curl helper script to bypass macOS network restrictions
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *helperPath = @"/tmp/unifi_helper.sh";
        // Pass empty string for token parameter since we're using cookies now
        NSArray *args = @[@"cameras", self.controllerHost, self.username, self.password, @""];

        NSLog(@"[UniFi] Executing: %@ %@", helperPath, [args componentsJoinedByString:@" "]);
        [statusWindow appendLog:[NSString stringWithFormat:@"Executing: %@ cameras %@ %@", helperPath, self.controllerHost, self.username] level:@"INFO"];

        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/bin/bash";
        // Prepend the helper script path to arguments
        NSMutableArray *bashArgs = [NSMutableArray arrayWithObject:helperPath];
        [bashArgs addObjectsFromArray:args];
        task.arguments = bashArgs;

        NSPipe *outputPipe = [NSPipe pipe];
        task.standardOutput = outputPipe;
        task.standardError = outputPipe;

        NSLog(@"[UniFi] Launching curl helper task...");
        [statusWindow appendLog:@"Launching curl helper task..." level:@"INFO"];

        // Read data asynchronously to prevent pipe buffer deadlock
        NSFileHandle *fileHandle = [outputPipe fileHandleForReading];
        NSMutableData *outputData = [NSMutableData data];

        [task launch];
        NSLog(@"[UniFi] Task launched, reading output...");
        [statusWindow appendLog:@"Task launched, reading output..." level:@"INFO"];

        // Read in chunks to avoid blocking
        while (task.isRunning) {
            NSData *chunk = [fileHandle availableData];
            if (chunk.length > 0) {
                [outputData appendData:chunk];
                NSLog(@"[UniFi] Read %lu bytes (total: %lu)", (unsigned long)chunk.length, (unsigned long)outputData.length);
            }
            usleep(10000); // 10ms sleep to avoid busy-waiting
        }

        // Read any remaining data
        NSData *remainingData = [fileHandle readDataToEndOfFile];
        if (remainingData.length > 0) {
            [outputData appendData:remainingData];
            NSLog(@"[UniFi] Read final %lu bytes", (unsigned long)remainingData.length);
        }

        [task waitUntilExit];
        NSLog(@"[UniFi] Task completed with exit status: %d", task.terminationStatus);
        [statusWindow appendLog:[NSString stringWithFormat:@"Task completed (exit code: %d)", task.terminationStatus] level:@"INFO"];

        NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

        NSLog(@"[UniFi] Camera discovery helper output: %@", output);
        NSLog(@"[UniFi] Output length: %lu bytes", (unsigned long)output.length);
        [statusWindow appendLog:[NSString stringWithFormat:@"Received %lu bytes of data", (unsigned long)output.length] level:@"INFO"];

        // Parse the response
        [statusWindow appendLog:@"Parsing response..." level:@"INFO"];
        NSArray *lines = [output componentsSeparatedByString:@"\n"];
        NSString *statusLine = [lines lastObject];
        NSInteger statusCode = 0;

        if ([statusLine hasPrefix:@"HTTP_STATUS:"]) {
            statusCode = [[statusLine substringFromIndex:12] integerValue];
            [statusWindow appendLog:[NSString stringWithFormat:@"HTTP Status: %ld", (long)statusCode] level:@"INFO"];
        } else {
            [statusWindow appendLog:@"No HTTP status found in response" level:@"WARNING"];
        }

        // Get the JSON response (everything except last line)
        NSMutableString *jsonResponse = [NSMutableString string];
        for (NSInteger i = 0; i < lines.count - 1; i++) {
            NSString *line = lines[i];
            if (line.length > 0) {
                [jsonResponse appendString:line];
            }
        }
        [statusWindow appendLog:[NSString stringWithFormat:@"JSON response length: %lu bytes", (unsigned long)jsonResponse.length] level:@"INFO"];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (statusCode != 200) {
                NSString *errorMessage = [NSString stringWithFormat:@"HTTP %ld", (long)statusCode];
                NSError *statusError = [NSError errorWithDomain:@"RTSPUniFiProtectAdapter"
                                                           code:statusCode
                                                       userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
                NSLog(@"[UniFi] ERROR: Camera discovery failed - %@", errorMessage);
                [statusWindow appendLog:[NSString stringWithFormat:@"Discovery failed: %@", errorMessage] level:@"ERROR"];

                if (completion) completion(nil, statusError);
                if ([self.delegate respondsToSelector:@selector(unifiProtectAdapter:didFailDiscoveryWithError:)]) {
                    [self.delegate unifiProtectAdapter:self didFailDiscoveryWithError:statusError];
                }
                return;
            }

            // Parse JSON response
            [statusWindow appendLog:@"Parsing JSON data..." level:@"INFO"];
            NSData *jsonData = [jsonResponse dataUsingEncoding:NSUTF8StringEncoding];
            NSError *parseError = nil;
            id parsedResponse = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&parseError];

            if (parseError || ![parsedResponse isKindOfClass:[NSArray class]]) {
                NSLog(@"[UniFi] ERROR: Failed to parse camera list");
                [statusWindow appendLog:[NSString stringWithFormat:@"JSON parsing failed: %@", parseError.localizedDescription] level:@"ERROR"];
                if (completion) completion(nil, parseError);
                return;
            }

            NSArray *cameraArray = (NSArray *)parsedResponse;
            [statusWindow appendLog:[NSString stringWithFormat:@"Found %lu camera objects", (unsigned long)cameraArray.count] level:@"INFO"];

            NSMutableArray<RTSPUniFiCamera *> *cameras = [NSMutableArray array];

            for (NSDictionary *cameraData in cameraArray) {
                RTSPUniFiCamera *camera = [self parseCameraFromJSON:cameraData];
                if (camera) {
                    [cameras addObject:camera];
                    [statusWindow appendLog:[NSString stringWithFormat:@"Parsed: %@ (%@)", camera.name, camera.model] level:@"INFO"];
                }
            }

            self.cachedCameras = [cameras copy];
            NSLog(@"[UniFi] ✓ Discovered %lu cameras", (unsigned long)cameras.count);
            [statusWindow appendLog:[NSString stringWithFormat:@"✓ Successfully discovered %lu cameras", (unsigned long)cameras.count] level:@"SUCCESS"];

            if (completion) completion(cameras, nil);
            if ([self.delegate respondsToSelector:@selector(unifiProtectAdapter:didDiscoverCameras:)]) {
                [self.delegate unifiProtectAdapter:self didDiscoverCameras:cameras];
            }
        });
    });
}

- (nullable RTSPUniFiCamera *)parseCameraFromJSON:(NSDictionary *)json {
    RTSPUniFiCamera *camera = [[RTSPUniFiCamera alloc] init];

    camera.cameraId = json[@"id"];
    camera.name = json[@"name"] ?: @"Unknown Camera";
    camera.model = json[@"type"] ?: json[@"model"] ?: @"Unknown";
    camera.macAddress = json[@"mac"] ?: @"";
    camera.ipAddress = json[@"host"] ?: @"";
    camera.firmwareVersion = json[@"firmwareVersion"];
    camera.isOnline = [json[@"state"] isEqualToString:@"CONNECTED"] || [json[@"isConnected"] boolValue];
    camera.supportsRTSP = YES; // All UniFi cameras support RTSP
    camera.rtspPort = 7441; // UniFi Protect secure RTSP port
    camera.rtspChannel = 0; // Main stream
    camera.cameraType = json[@"type"];
    camera.lastSeen = [NSDate date];
    camera.rawData = json;

    // Generate RTSP URL using the camera's RTSP alias from channel data
    if (camera.ipAddress.length > 0) {
        // Get the RTSP alias from the first channel (high quality stream)
        NSArray *channels = json[@"channels"];
        NSString *rtspAlias = nil;

        if (channels && [channels isKindOfClass:[NSArray class]] && channels.count > 0) {
            NSDictionary *channel = channels[0]; // Channel 0 is high quality
            if ([channel[@"isRtspEnabled"] boolValue]) {
                rtspAlias = channel[@"rtspAlias"];
            }
        }

        if (rtspAlias && rtspAlias.length > 0) {
            // UniFi Protect RTSPS streams go through CONTROLLER, not direct to camera!
            // URL format: rtsps://CONTROLLER-IP:7441/rtspAlias?enableSrtp
            camera.rtspURL = [NSString stringWithFormat:@"rtsps://%@:7441/%@?enableSrtp",
                            self.controllerHost,  // CONTROLLER IP, not camera IP!
                            rtspAlias];
            NSLog(@"[UniFi] Set camera.rtspURL for %@: rtsps://%@:7441/%@", camera.name, self.controllerHost, rtspAlias);
        } else {
            NSLog(@"[UniFi] WARNING: Camera %@ has no RTSP alias in channel data", camera.name);
        }
    }

    return camera;
}

- (void)getCameraById:(NSString *)cameraId completion:(void (^)(RTSPUniFiCamera * _Nullable, NSError * _Nullable))completion {
    for (RTSPUniFiCamera *camera in self.cachedCameras) {
        if ([camera.cameraId isEqualToString:cameraId]) {
            if (completion) completion(camera, nil);
            return;
        }
    }

    // Camera not in cache, fetch from server
    NSLog(@"[UniFi] Camera %@ not in cache, fetching...", cameraId);

    NSString *protocol = self.useHTTPS ? @"https" : @"http";
    NSString *urlString = [NSString stringWithFormat:@"%@://%@:%ld/proxy/protect/api/cameras/%@",
                          protocol, self.controllerHost, (long)self.controllerPort, cameraId];

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        NSError *error = [NSError errorWithDomain:@"RTSPUniFiProtectAdapter"
                                             code:1004
                                         userInfo:@{NSLocalizedDescriptionKey: @"Invalid camera URL"}];
        if (completion) completion(nil, error);
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [self addAuthenticationToRequest:request];

    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(nil, error);
            });
            return;
        }

        NSError *parseError = nil;
        id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];

        if ([jsonResponse isKindOfClass:[NSDictionary class]]) {
            RTSPUniFiCamera *camera = [self parseCameraFromJSON:(NSDictionary *)jsonResponse];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(camera, nil);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(nil, parseError);
            });
        }
    }];

    [task resume];
}

- (void)refreshCameraList:(void (^)(BOOL, NSError * _Nullable))completion {
    NSLog(@"[UniFi] Refreshing camera list...");

    // If already authenticated (have auth cookie), just discover cameras
    // Otherwise authenticate first
    if (self.isAuthenticated) {
        NSLog(@"[UniFi] Already authenticated, directly discovering cameras");
        [self discoverCamerasWithCompletion:^(NSArray<RTSPUniFiCamera *> *cameras, NSError *discoveryError) {
            if (completion) {
                completion(cameras != nil, discoveryError);
            }
        }];
    } else {
        NSLog(@"[UniFi] Not authenticated, authenticating first");
        [self authenticateWithCompletion:^(BOOL authSuccess, NSError *authError) {
            if (!authSuccess) {
                if (completion) completion(NO, authError);
                return;
            }

            [self discoverCamerasWithCompletion:^(NSArray<RTSPUniFiCamera *> *cameras, NSError *discoveryError) {
                if (completion) {
                    completion(cameras != nil, discoveryError);
                }
            }];
        }];
    }
}

#pragma mark - RTSP URL Generation

- (NSString *)generateRTSPURLForCamera:(RTSPUniFiCamera *)camera streamType:(NSString *)streamType {
    return [self generateRTSPURLForCamera:camera
                               streamType:streamType
                                 username:self.username
                                 password:self.password];
}

- (NSString *)generateRTSPURLForCamera:(RTSPUniFiCamera *)camera
                            streamType:(NSString *)streamType
                              username:(NSString *)username
                              password:(NSString *)password {
    if (!camera.ipAddress || camera.ipAddress.length == 0) {
        NSLog(@"[UniFi] WARNING: Camera %@ has no IP address", camera.name);
        return nil;
    }

    // Check user preference for RTSP protocol
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL useSecureRTSP = [defaults boolForKey:@"UniFi_UseSecureRTSP"];

    NSLog(@"[UniFi] Checking RTSP protocol preference: UniFi_UseSecureRTSP = %d", useSecureRTSP);
    NSLog(@"[UniFi] Will generate %@ URLs (port %d)", useSecureRTSP ? @"RTSPS" : @"RTSP", useSecureRTSP ? 7441 : 554);

    // Get the RTSP alias from channel data based on stream type
    NSArray *channels = camera.rawData[@"channels"];
    NSString *rtspAlias = nil;
    NSInteger channelIndex = [streamType isEqualToString:@"low"] ? 2 : 0;

    if (channels && [channels isKindOfClass:[NSArray class]] && channelIndex < channels.count) {
        NSDictionary *channel = channels[channelIndex];
        if ([channel[@"isRtspEnabled"] boolValue]) {
            rtspAlias = channel[@"rtspAlias"];
        }
    }

    if (!rtspAlias || rtspAlias.length == 0) {
        NSLog(@"[UniFi] WARNING: Camera %@ has no RTSP alias for stream type %@", camera.name, streamType);
        return nil;
    }

    NSString *rtspURL;

    if (useSecureRTSP) {
        // RTSPS (Secure) - Port 7441 through CONTROLLER (not direct to camera!)
        // UniFi cameras don't expose port 7441 - only the controller does
        // URL format: rtsps://CONTROLLER-IP:7441/rtspAlias?enableSrtp
        rtspURL = [NSString stringWithFormat:@"rtsps://%@:7441/%@?enableSrtp",
                            self.controllerHost,  // Use CONTROLLER IP, not camera IP!
                            rtspAlias];
        NSLog(@"[UniFi] Generated SECURE RTSPS URL (FFmpeg proxy): rtsps://%@:7441/%@", self.controllerHost, rtspAlias);
    } else {
        // RTSP (Non-Secure) - Port 554 - Works with AVFoundation
        // Direct camera connection, bypasses controller proxy
        // Format: rtsp://username:password@camera-ip:554/channel-path

        // UniFi cameras use simple channel paths
        NSString *channelPath = [streamType isEqualToString:@"low"] ? @"s1" : @"s0";

        if (username && password && username.length > 0 && password.length > 0) {
            // URL encode username and password for special characters
            NSString *encodedUsername = [username stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLUserAllowedCharacterSet]];
            NSString *encodedPassword = [password stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPasswordAllowedCharacterSet]];

            rtspURL = [NSString stringWithFormat:@"rtsp://%@:%@@%@:554/%@",
                                encodedUsername,
                                encodedPassword,
                                camera.ipAddress,
                                channelPath];
        } else {
            rtspURL = [NSString stringWithFormat:@"rtsp://%@:554/%@",
                                camera.ipAddress,
                                channelPath];
        }

        NSLog(@"[UniFi] Generated RTSP URL (AVFoundation compatible): rtsp://%@:554/%@", camera.ipAddress, channelPath);
    }

    return rtspURL;
}

#pragma mark - Camera Import

- (void)importCameras:(NSArray<RTSPUniFiCamera *> *)cameras completion:(void (^)(NSInteger))completion {
    NSLog(@"[UniFi] Importing %lu cameras...", (unsigned long)cameras.count);

    RTSPConfigurationManager *config = [RTSPConfigurationManager sharedManager];
    NSMutableArray *metadata = [config.manualFeedMetadata mutableCopy] ?: [NSMutableArray array];

    NSInteger importedCount = 0;

    for (RTSPUniFiCamera *camera in cameras) {
        if (!camera.rtspURL || camera.rtspURL.length == 0) {
            NSLog(@"[UniFi] Skipping camera %@ - no RTSP URL", camera.name);
            continue;
        }

        // Check if already exists
        BOOL exists = NO;
        for (RTSPFeedMetadata *existing in metadata) {
            if ([existing.url isEqualToString:camera.rtspURL]) {
                exists = YES;
                break;
            }
        }

        if (!exists) {
            RTSPFeedMetadata *feedMeta = [[RTSPFeedMetadata alloc] init];
            feedMeta.url = camera.rtspURL;
            feedMeta.displayName = [NSString stringWithFormat:@"%@ (%@)", camera.name, camera.model];
            feedMeta.enabled = camera.isOnline;
            feedMeta.category = @"UniFi Protect";

            [metadata addObject:feedMeta];
            importedCount++;

            NSLog(@"[UniFi] ✓ Imported: %@", camera.name);
        } else {
            NSLog(@"[UniFi] Skipping %@ - already exists", camera.name);
        }
    }

    config.manualFeedMetadata = metadata;
    [config save];

    NSLog(@"[UniFi] ✓ Imported %ld cameras", (long)importedCount);

    if (completion) {
        completion(importedCount);
    }
}

#pragma mark - Health Monitoring

- (void)testCameraConnection:(RTSPUniFiCamera *)camera completion:(void (^)(BOOL, NSTimeInterval, NSError * _Nullable))completion {
    if (!camera.rtspURL) {
        NSError *error = [NSError errorWithDomain:@"RTSPUniFiProtectAdapter"
                                             code:1005
                                         userInfo:@{NSLocalizedDescriptionKey: @"Camera has no RTSP URL"}];
        if (completion) completion(NO, 0, error);
        return;
    }

    NSLog(@"[UniFi] Testing connection to %@...", camera.name);

    NSDate *startTime = [NSDate date];

    // Simple TCP connection test to camera IP
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL canConnect = NO;
        NSError *testError = nil;

        // Try to create a socket connection to the camera's RTSP port
        CFSocketRef socket = CFSocketCreate(NULL, PF_INET, SOCK_STREAM, IPPROTO_TCP, 0, NULL, NULL);
        if (socket) {
            struct sockaddr_in addr;
            memset(&addr, 0, sizeof(addr));
            addr.sin_family = AF_INET;
            addr.sin_port = htons(camera.rtspPort);
            inet_pton(AF_INET, [camera.ipAddress UTF8String], &addr.sin_addr);

            CFDataRef addressData = CFDataCreate(NULL, (UInt8 *)&addr, sizeof(addr));
            CFSocketError socketError = CFSocketConnectToAddress(socket, addressData, 5.0); // 5 second timeout

            canConnect = (socketError == kCFSocketSuccess);
            CFRelease(addressData);
            CFRelease(socket);

            if (!canConnect) {
                testError = [NSError errorWithDomain:@"RTSPUniFiProtectAdapter"
                                                code:1006
                                            userInfo:@{NSLocalizedDescriptionKey: @"Connection timeout or refused"}];
            }
        } else {
            testError = [NSError errorWithDomain:@"RTSPUniFiProtectAdapter"
                                            code:1007
                                        userInfo:@{NSLocalizedDescriptionKey: @"Failed to create socket"}];
        }

        NSTimeInterval totalLatency = [[NSDate date] timeIntervalSinceDate:startTime];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (canConnect) {
                NSLog(@"[UniFi] ✓ Camera %@ is reachable (%.2fs)", camera.name, totalLatency);
            } else {
                NSLog(@"[UniFi] ✗ Camera %@ connection failed: %@", camera.name, testError.localizedDescription);
            }

            if (completion) {
                completion(canConnect, totalLatency, testError);
            }
        });
    });
}

- (nullable NSString *)getSnapshotURLForCamera:(RTSPUniFiCamera *)camera {
    if (!camera.cameraId) {
        return nil;
    }

    NSString *protocol = self.useHTTPS ? @"https" : @"http";
    return [NSString stringWithFormat:@"%@://%@:%ld/proxy/protect/api/cameras/%@/snapshot",
            protocol, self.controllerHost, (long)self.controllerPort, camera.cameraId];
}

#pragma mark - Helper Methods

- (void)addAuthenticationToRequest:(NSMutableURLRequest *)request {
    if (self.authToken) {
        [request setValue:[NSString stringWithFormat:@"Bearer %@", self.authToken]
       forHTTPHeaderField:@"Authorization"];
    }

    if (self.authCookie) {
        [request setValue:self.authCookie forHTTPHeaderField:@"Cookie"];
    }
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {

    NSLog(@"[UniFi] SSL Challenge received: method=%@, host=%@, verifySSL=%d",
          challenge.protectionSpace.authenticationMethod,
          challenge.protectionSpace.host,
          self.verifySSL);

    // Allow self-signed certificates if verifySSL is disabled
    if (!self.verifySSL && [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSLog(@"[UniFi] ✓ Accepting self-signed certificate for %@", challenge.protectionSpace.host);
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        NSLog(@"[UniFi] ✗ Using default SSL handling");
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {

    NSLog(@"[UniFi] Task-level SSL Challenge: method=%@", challenge.protectionSpace.authenticationMethod);

    // Allow self-signed certificates if verifySSL is disabled
    if (!self.verifySSL && [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSLog(@"[UniFi] ✓ Accepting self-signed certificate (task-level)");
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

@end
