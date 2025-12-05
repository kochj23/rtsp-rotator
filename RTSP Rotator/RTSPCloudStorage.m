//
//  RTSPCloudStorage.m
//  RTSP Rotator
//

#import "RTSPCloudStorage.h"

@implementation RTSPCloudStorage

+ (instancetype)sharedManager {
    static RTSPCloudStorage *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RTSPCloudStorage alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        _provider = RTSPCloudProviderNone;
        _autoUploadEnabled = NO;
        _retentionDays = 30;
    }
    return self;
}

- (void)uploadFile:(NSURL *)fileURL completion:(void (^)(BOOL, NSError * _Nullable))completion {
    if (self.provider == RTSPCloudProviderNone) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"RTSPCloudStorage" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"No cloud provider configured"}];
            completion(NO, error);
        }
        return;
    }

    // Simulate upload
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2.0];

        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[Cloud] Uploaded file: %@", fileURL.lastPathComponent);
            if (completion) completion(YES, nil);
        });
    });
}

- (void)listFiles:(void (^)(NSArray<NSString *> * _Nullable, NSError * _Nullable))completion {
    if (completion) completion(@[], nil);
}

- (void)deleteFile:(NSString *)filename completion:(void (^)(BOOL, NSError * _Nullable))completion {
    NSLog(@"[Cloud] Deleted file: %@", filename);
    if (completion) completion(YES, nil);
}

@end
