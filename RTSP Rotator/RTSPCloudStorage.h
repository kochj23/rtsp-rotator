//
//  RTSPCloudStorage.h
//  RTSP Rotator
//
//  Cloud storage integration for snapshots and recordings
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTSPCloudProvider) {
    RTSPCloudProviderNone,
    RTSPCloudProvideriCloud,
    RTSPCloudProviderDropbox,
    RTSPCloudProviderGoogleDrive,
    RTSPCloudProviderS3
};

@interface RTSPCloudStorage : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, assign) RTSPCloudProvider provider;
@property (nonatomic, assign) BOOL autoUploadEnabled;
@property (nonatomic, assign) NSInteger retentionDays; // 0 = infinite

- (void)uploadFile:(NSURL *)fileURL completion:(void (^)(BOOL success, NSError *_Nullable error))completion;
- (void)listFiles:(void (^)(NSArray<NSString *> *_Nullable files, NSError *_Nullable error))completion;
- (void)deleteFile:(NSString *)filename completion:(void (^)(BOOL success, NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
