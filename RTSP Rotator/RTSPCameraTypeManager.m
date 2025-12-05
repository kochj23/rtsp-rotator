//
//  RTSPCameraTypeManager.m
//  RTSP Rotator
//

#import "RTSPCameraTypeManager.h"
#import <AVFoundation/AVFoundation.h>

@implementation RTSPStandardCameraConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        self.cameraType = @"RTSP";
        _port = 554;
        _connectionTimeout = 10.0;
        _maxRetries = 3;
        _preferredFramerate = 30;
        _hasAudio = NO;
        _enableAudio = NO;
        _audioVolume = 0.5;
        _useUDP = NO;
        _bufferSize = 1000;
        _supportsPTZ = NO;
    }
    return self;
}

- (NSURL *)buildRTSPURL {
    if (self.feedURL) {
        return self.feedURL;
    }

    // Build from components
    NSString *scheme = self.usesTLS ? @"rtsps" : @"rtsp";
    NSString *host = @""; // Should be set separately
    NSString *streamPath = self.streamPath ?: @"/stream";

    NSString *urlString;
    if (self.username && self.password) {
        urlString = [NSString stringWithFormat:@"%@://%@:%@@%@:%ld%@",
                    scheme, self.username, self.password, host, (long)self.port, streamPath];
    } else {
        urlString = [NSString stringWithFormat:@"%@://%@:%ld%@",
                    scheme, host, (long)self.port, streamPath];
    }

    return [NSURL URLWithString:urlString];
}

- (void)testConnectionWithCompletion:(void (^)(BOOL, NSError * _Nullable))completion {
    if (!self.feedURL) {
        NSError *error = [NSError errorWithDomain:@"RTSPCameraTypeManager"
                                            code:1001
                                        userInfo:@{NSLocalizedDescriptionKey: @"No feed URL configured"}];
        if (completion) completion(NO, error);
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVPlayer *testPlayer = [[AVPlayer alloc] init];
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:self.feedURL];

        __block BOOL completed = NO;
        NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:self.connectionTimeout];

        [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
        [testPlayer replaceCurrentItemWithPlayerItem:item];

        while (!completed && [[NSDate date] compare:timeout] == NSOrderedAscending) {
            if (item.status == AVPlayerItemStatusReadyToPlay) {
                completed = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(YES, nil);
                });
                break;
            } else if (item.status == AVPlayerItemStatusFailed) {
                completed = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(NO, item.error);
                });
                break;
            }
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }

        if (!completed) {
            NSError *error = [NSError errorWithDomain:@"RTSPCameraTypeManager"
                                                code:1002
                                            userInfo:@{NSLocalizedDescriptionKey: @"Connection timeout"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, error);
            });
        }

        [item removeObserver:self forKeyPath:@"status"];
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // Observer for test connection
}

@end

@interface RTSPCameraTypeManager ()
