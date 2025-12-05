//
//  RTSPAPIServer.h
//  RTSP Rotator
//
//  HTTP REST API server for remote control
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RTSPAPIServer;

/// API server delegate for handling requests
@protocol RTSPAPIServerDelegate <NSObject>
@optional
- (void)apiServer:(RTSPAPIServer *)server didReceiveCommand:(NSString *)command parameters:(NSDictionary *)parameters;
- (NSArray<NSString *> *)apiServerRequestFeedList:(RTSPAPIServer *)server;
- (NSInteger)apiServerRequestCurrentFeedIndex:(RTSPAPIServer *)server;
- (void)apiServer:(RTSPAPIServer *)server switchToFeedAtIndex:(NSInteger)index;
- (void)apiServerSwitchToNextFeed:(RTSPAPIServer *)server;
- (void)apiServerSwitchToPreviousFeed:(RTSPAPIServer *)server;
- (void)apiServerTakeSnapshot:(RTSPAPIServer *)server;
- (void)apiServerStartRecording:(RTSPAPIServer *)server;
- (void)apiServerStopRecording:(RTSPAPIServer *)server;
- (BOOL)apiServerIsRecording:(RTSPAPIServer *)server;
- (void)apiServer:(RTSPAPIServer *)server setRotationInterval:(NSTimeInterval)interval;
@end

/// HTTP REST API server
@interface RTSPAPIServer : NSObject

/// Shared instance
+ (instancetype)sharedServer;

/// Delegate for API requests
@property (nonatomic, weak) id<RTSPAPIServerDelegate> delegate;

/// Enable API server (default: NO)
@property (nonatomic, assign) BOOL enabled;

/// Server port (default: 8080)
@property (nonatomic, assign) NSInteger port;

/// API key for authentication (optional)
@property (nonatomic, strong, nullable) NSString *apiKey;

/// Require API key (default: NO)
@property (nonatomic, assign) BOOL requireAPIKey;

/// Server is running
@property (nonatomic, assign, readonly) BOOL isRunning;

/// Start API server
- (BOOL)start;

/// Stop API server
- (void)stop;

/// Get server base URL
- (NSURL *)baseURL;

@end

NS_ASSUME_NONNULL_END
