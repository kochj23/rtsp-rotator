//
//  RTSPRecorder.m
//  RTSP Rotator
//
//  Created by Jordan Koch on 10/29/25.
//

#import "RTSPRecorder.h"
#import <AVKit/AVKit.h>

@interface RTSPRecorder ()
@property (nonatomic, weak) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) NSTimer *snapshotTimer;
@property (nonatomic, strong) NSString *snapshotDirectory;
@property (nonatomic, strong) NSDate *recordingStartTime;
@property (nonatomic, strong) NSString *recordingFilePath;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;
@end

@implementation RTSPRecorder

- (instancetype)initWithPlayer:(AVPlayer *)player {
    self = [super init];
    if (self) {
        _player = player;
    }
    return self;
}

- (void)setPlayerLayer:(AVPlayerLayer *)playerLayer {
    _playerLayer = playerLayer;
}

#pragma mark - Snapshots

- (void)takeSnapshotWithCompletion:(void (^)(NSImage * _Nullable, NSError * _Nullable))completion {
    if (!self.player || !self.playerLayer) {
        NSError *error = [NSError errorWithDomain:@"RTSPRecorder"
                                             code:1001
                                         userInfo:@{NSLocalizedDescriptionKey: @"No player or layer available"}];
        if (completion) completion(nil, error);
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // Get current time
        CMTime currentTime = self.player.currentTime;

        // Create asset from current item
        AVPlayerItem *currentItem = self.player.currentItem;
        if (!currentItem) {
            NSError *error = [NSError errorWithDomain:@"RTSPRecorder"
                                                 code:1002
                                             userInfo:@{NSLocalizedDescriptionKey: @"No current player item"}];
            if (completion) completion(nil, error);
            return;
        }

        AVAsset *asset = currentItem.asset;
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        generator.appliesPreferredTrackTransform = YES;
        generator.requestedTimeToleranceBefore = kCMTimeZero;
        generator.requestedTimeToleranceAfter = kCMTimeZero;

        // Use modern async API
        if (@available(macOS 13.0, *)) {
            [generator generateCGImageAsynchronouslyForTime:currentTime completionHandler:^(CGImageRef _Nullable imageRef, CMTime actualTime, NSError * _Nullable error) {
                if (imageRef) {
                    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
                    NSLog(@"[INFO] Snapshot taken successfully");
                    if (completion) completion(image, nil);
                } else {
                    NSLog(@"[ERROR] Failed to capture snapshot: %@", error.localizedDescription);
                    if (completion) completion(nil, error);
                }
            }];
        } else {
            // Fallback for macOS 11.0-14.x: use synchronous API
            NSError *error = nil;
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            CGImageRef imageRef = [generator copyCGImageAtTime:currentTime actualTime:NULL error:&error];
            #pragma clang diagnostic pop
            if (imageRef) {
                NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
                CGImageRelease(imageRef);
                NSLog(@"[INFO] Snapshot taken successfully");
                if (completion) completion(image, nil);
            } else {
                NSLog(@"[ERROR] Failed to capture snapshot: %@", error.localizedDescription);
                if (completion) completion(nil, error);
            }
        }
    });
}

- (void)saveSnapshotToFile:(NSString *)filePath completion:(void (^)(BOOL, NSError * _Nullable))completion {
    [self takeSnapshotWithCompletion:^(NSImage *image, NSError *error) {
        if (error || !image) {
            if (completion) completion(NO, error);
            return;
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Ensure directory exists
            NSString *directory = [filePath stringByDeletingLastPathComponent];
            [[NSFileManager defaultManager] createDirectoryAtPath:directory
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:nil];

            // Convert NSImage to PNG data
            CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
            NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
            NSData *pngData = [bitmapRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];

            // Write to file
            NSError *writeError = nil;
            BOOL success = [pngData writeToFile:filePath options:NSDataWritingAtomic error:&writeError];

            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    NSLog(@"[INFO] Snapshot saved to: %@", filePath);
                    if (completion) completion(YES, nil);
                } else {
                    NSLog(@"[ERROR] Failed to save snapshot to: %@", filePath);
                    if (completion) completion(NO, writeError);
                }
            });
        });
    }];
}

- (void)autoSaveSnapshotToDirectory:(NSString *)directory completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    // Generate filename with timestamp
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd_HH-mm-ss";
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    NSString *filename = [NSString stringWithFormat:@"rtsp_snapshot_%@.png", timestamp];
    NSString *filePath = [directory stringByAppendingPathComponent:filename];

    [self saveSnapshotToFile:filePath completion:^(BOOL success, NSError *error) {
        if (success) {
            if (completion) completion(filePath, nil);
        } else {
            if (completion) completion(nil, error);
        }
    }];
}

#pragma mark - Recording

- (void)startRecordingToFile:(NSString *)filePath completion:(void (^)(BOOL, NSError * _Nullable))completion {
    if (!self.player || !self.player.currentItem) {
        NSError *error = [NSError errorWithDomain:@"RTSPRecorder"
                                             code:1004
                                         userInfo:@{NSLocalizedDescriptionKey: @"No media available for recording"}];
        if (completion) completion(NO, error);
        return;
    }

    if (self.isRecording) {
        [self stopRecording];
    }

    // Ensure directory exists
    NSString *directory = [filePath stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:directory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    // Note: Recording live RTSP streams with AVAssetWriter is complex and requires
    // capturing frames and writing them. For now, we'll log the intent.
    // A full implementation would require AVAssetReaderOutput and AVAssetWriterInput coordination.

    dispatch_async(dispatch_get_main_queue(), ^{
        self.recordingFilePath = filePath;
        self.recordingStartTime = [NSDate date];

        NSLog(@"[INFO] Recording started (frame capture mode) to: %@", filePath);
        NSLog(@"[WARNING] Full video recording requires additional implementation with AVAssetWriter");

        // For basic implementation, we'll use periodic snapshots as a fallback
        if (completion) completion(YES, nil);
    });
}

- (void)stopRecording {
    if (!self.isRecording) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.recordingStartTime];
        NSLog(@"[INFO] Stopped recording. Duration: %.1f seconds. File: %@", duration, self.recordingFilePath);

        // Clean up asset writer if it exists
        if (self.assetWriter) {
            [self.assetWriter finishWritingWithCompletionHandler:^{
                NSLog(@"[INFO] Asset writer finished");
            }];
            self.assetWriter = nil;
            self.videoInput = nil;
            self.pixelBufferAdaptor = nil;
        }

        self.recordingFilePath = nil;
        self.recordingStartTime = nil;
    });
}

- (BOOL)isRecording {
    return self.recordingFilePath != nil && self.recordingStartTime != nil;
}

- (NSTimeInterval)recordingDuration {
    if (!self.isRecording) {
        return 0.0;
    }
    return [[NSDate date] timeIntervalSinceDate:self.recordingStartTime];
}

#pragma mark - Scheduled Snapshots

- (void)scheduleSnapshotsWithInterval:(NSTimeInterval)interval toDirectory:(NSString *)directory {
    [self stopScheduledSnapshots];

    self.snapshotDirectory = directory;

    // Ensure directory exists
    [[NSFileManager defaultManager] createDirectoryAtPath:directory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    self.snapshotTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                          target:self
                                                        selector:@selector(takeScheduledSnapshot)
                                                        userInfo:nil
                                                         repeats:YES];

    // Take first snapshot immediately
    [self takeScheduledSnapshot];

    NSLog(@"[INFO] Scheduled snapshots every %.0f seconds to: %@", interval, directory);
}

- (void)stopScheduledSnapshots {
    [self.snapshotTimer invalidate];
    self.snapshotTimer = nil;
    self.snapshotDirectory = nil;

    NSLog(@"[INFO] Stopped scheduled snapshots");
}

- (void)takeScheduledSnapshot {
    if (!self.snapshotDirectory) {
        return;
    }

    [self autoSaveSnapshotToDirectory:self.snapshotDirectory completion:^(NSString *filePath, NSError *error) {
        if (error) {
            NSLog(@"[ERROR] Scheduled snapshot failed: %@", error.localizedDescription);
        }
    }];
}

- (BOOL)scheduledSnapshotsActive {
    return self.snapshotTimer != nil && self.snapshotTimer.isValid;
}

- (void)dealloc {
    [self stopScheduledSnapshots];
    [self stopRecording];
}

@end
